import { Component, Input, inject, signal, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NrConfigService } from '../../nr-config';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { MissionProgressService } from '../../services/mission-progress.service';
import { NewRelicService } from '../../services/newrelic.service';

export type CheckKind = 'choice' | 'multi' | 'number' | 'text';

/**
 * The Check step of Try / Learn / Find / Check (spec section 3). One
 * instance per question, projected inside an <app-nr-callout> after its
 * Find button. Every answer - right or wrong - fires an OrderupQuizAnswer
 * custom event mirroring browser.nru.to's DemoQuizAnswer attributes, so
 * the knowledge-checks dashboard queries port directly.
 *
 * Answers are judged locally (the answer key ships with the question, as
 * on browser.nru.to): most checks are evidence checks whose answers live
 * in the data, so guessing without opening New Relic is the hard path.
 */
@Component({
  selector: 'app-nr-check',
  imports: [FormsModule],
  templateUrl: './nr-check.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './nr-check.css'
})
export class NrCheckComponent {
  protected config = inject(NrConfigService);
  private identity = inject(DemoIdentityService);
  private progress = inject(MissionProgressService);
  private newRelic = inject(NewRelicService);

  @Input({ required: true }) missionId!: string;
  @Input({ required: true }) questionId!: string;
  @Input({ required: true }) question!: string;
  @Input({ required: true }) kind!: CheckKind;
  /** Options for kind=choice / kind=multi. */
  @Input() options: string[] = [];
  /** The correct answer: a string (choice/text), string[] (multi), or number. */
  @Input({ required: true }) answer!: string | string[] | number;
  /** Allowed +/- distance for kind=number. */
  @Input() tolerance = 0;
  /** One line shown on a correct answer: what the answer proves. */
  @Input() proves = '';

  protected selected = signal<string | null>(null);
  protected selectedMulti = signal<Set<string>>(new Set());
  protected entry = signal('');
  protected feedback = signal<'idle' | 'wrong' | 'correct'>('idle');

  get solved(): boolean {
    return this.progress.isSolved(this.missionId, this.questionId);
  }

  get attempts(): number {
    return this.progress.progress(this.missionId, this.questionId).attempts;
  }

  protected get canSubmit(): boolean {
    if (this.solved) return false;
    switch (this.kind) {
      case 'choice': return this.selected() !== null;
      case 'multi': return this.selectedMulti().size > 0;
      case 'number': return this.entry().trim() !== '' && !Number.isNaN(Number(this.entry()));
      case 'text': return this.entry().trim() !== '';
    }
  }

  protected toggleMulti(option: string, checked: boolean): void {
    this.selectedMulti.update(set => {
      const next = new Set(set);
      if (checked) next.add(option); else next.delete(option);
      return next;
    });
  }

  protected submit(): void {
    if (!this.canSubmit) return;
    const submitted = this.submittedAnswer();
    const correct = this.isCorrect(submitted);
    const attempt = this.progress.recordAttempt(this.missionId, this.questionId, correct);
    this.feedback.set(correct ? 'correct' : 'wrong');
    this.newRelic.recordCustomEvent('OrderupQuizAnswer', {
      missionId: this.missionId,
      questionId: this.questionId,
      question: this.question,
      answer: submitted,
      outcome: correct ? 'correct' : 'incorrect',
      attempt,
      demoPage: location.pathname,
      demoCode: this.identity.code(),
    });
  }

  private submittedAnswer(): string {
    switch (this.kind) {
      case 'choice': return this.selected() ?? '';
      case 'multi': return [...this.selectedMulti()].sort().join(', ');
      default: return this.entry().trim();
    }
  }

  private isCorrect(submitted: string): boolean {
    switch (this.kind) {
      case 'choice':
        return submitted === this.answer;
      case 'multi': {
        const expected = (this.answer as string[]).map(s => s.trim()).sort().join(', ');
        return submitted === expected;
      }
      case 'number': {
        const value = Number(submitted);
        return !Number.isNaN(value) && Math.abs(value - Number(this.answer)) <= this.tolerance;
      }
      case 'text':
        return normalize(submitted) === normalize(String(this.answer));
    }
  }
}

function normalize(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, ' ');
}
