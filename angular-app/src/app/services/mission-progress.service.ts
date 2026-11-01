import { Injectable, signal } from '@angular/core';

const STORAGE_KEY = 'orderup-missions';

export interface QuestionProgress {
  attempts: number;
  solved: boolean;
}

interface ProgressFile {
  questions: Record<string, QuestionProgress>;
}

/**
 * Per-visitor mission/check state (spec sections 2-3): how many attempts
 * each check has taken and whether it is solved. Persisted in localStorage
 * so progress survives navigation and reloads; the authoritative record of
 * every answer is the OrderupQuizAnswer event in New Relic - this service
 * is only the on-device view of it.
 */
@Injectable({ providedIn: 'root' })
export class MissionProgressService {
  readonly state = signal<ProgressFile>(this.load());

  key(missionId: string, questionId: string): string {
    return `${missionId}:${questionId}`;
  }

  progress(missionId: string, questionId: string): QuestionProgress {
    return this.state().questions[this.key(missionId, questionId)] ?? { attempts: 0, solved: false };
  }

  isSolved(missionId: string, questionId: string): boolean {
    return this.progress(missionId, questionId).solved;
  }

  /** Records one answer attempt; returns the 1-based attempt number. */
  recordAttempt(missionId: string, questionId: string, correct: boolean): number {
    const k = this.key(missionId, questionId);
    const current = this.progress(missionId, questionId);
    const updated: QuestionProgress = {
      attempts: current.attempts + 1,
      solved: current.solved || correct,
    };
    this.state.update(file => ({ questions: { ...file.questions, [k]: updated } }));
    this.save();
    return updated.attempts;
  }

  /** Missions (by id) with at least one solved check - for the §6 hub. */
  solvedCount(): number {
    return Object.values(this.state().questions).filter(q => q.solved).length;
  }

  private load(): ProgressFile {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as ProgressFile;
        if (parsed && typeof parsed === 'object' && parsed.questions) return parsed;
      }
    } catch { /* fall through to a fresh file */ }
    return { questions: {} };
  }

  private save(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state()));
    } catch { /* storage unavailable: progress lasts for this page load only */ }
  }
}
