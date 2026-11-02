import { Component, Input, inject, ChangeDetectionStrategy } from '@angular/core';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { MissionProgressService } from '../../services/mission-progress.service';
import { NrConfigService } from '../../nr-config';
import {
  InvestigationCheckpoint,
  InvestigationDef,
  investigationMissionId,
} from '../../services/investigations';

/**
 * One investigation (spec section 11): a gated chain of checkpoints.
 * Checkpoint n unlocks when n-1 is solved; solving is read from the
 * same MissionProgressService store the missions use, and the checks
 * record their answers as OrderupQuizAnswer under
 * missionId = 'inv-<slug>' via the check component itself. A solved
 * checkpoint collapses to its reveal; the case-closed summary appears
 * when every checkpoint is solved.
 */
@Component({
  selector: 'app-investigation',
  imports: [NrCalloutComponent, NrCheckComponent],
  templateUrl: './investigation.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './investigation.css',
})
export class InvestigationComponent {
  private progress = inject(MissionProgressService);
  protected config = inject(NrConfigService);

  @Input({ required: true }) def!: InvestigationDef;

  protected get missionId(): string {
    return investigationMissionId(this.def.slug);
  }

  /** Structural investigations are always live; armed ones only while armed. */
  protected get isLive(): boolean {
    return this.def.live === 'always' || this.config.armedInvestigation()?.slug === this.def.slug;
  }

  protected solved(cp: InvestigationCheckpoint): boolean {
    return this.progress.isSolved(this.missionId, cp.questionId);
  }

  protected unlocked(index: number): boolean {
    return index === 0 || this.solved(this.def.checkpoints[index - 1]);
  }

  protected get solvedCount(): number {
    return this.def.checkpoints.filter((cp) => this.solved(cp)).length;
  }

  protected get allSolved(): boolean {
    return this.solvedCount === this.def.checkpoints.length;
  }

  protected paragraphs(text: string): string[] {
    return text.split('\n\n');
  }
}
