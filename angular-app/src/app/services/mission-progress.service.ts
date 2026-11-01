import { Injectable, signal } from '@angular/core';
import { MISSIONS, missionById } from './missions';

const STORAGE_KEY = 'orderup-missions';

export interface QuestionProgress {
  attempts: number;
  solved: boolean;
}

export interface MissionState {
  /** The mission's Try action was observed (spec section 2). */
  tried: boolean;
  /** The mission's Find link was clicked. */
  found: boolean;
}

interface ProgressFile {
  questions: Record<string, QuestionProgress>;
  missions: Record<string, MissionState>;
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
    this.state.update(file => ({ ...file, questions: { ...file.questions, [k]: updated } }));
    this.save();
    return updated.attempts;
  }

  /** Missions (by id) with at least one solved check - for the §6 hub. */
  solvedCount(): number {
    return Object.values(this.state().questions).filter(q => q.solved).length;
  }

  missionState(missionId: string): MissionState {
    return this.state().missions[missionId] ?? { tried: false, found: false };
  }

  markTried(missionId: string): void {
    this.markMission(missionId, { tried: true });
  }

  markFound(missionId: string): void {
    this.markMission(missionId, { found: true });
  }

  private markMission(missionId: string, patch: Partial<MissionState>): void {
    const current = this.missionState(missionId);
    if ((patch.tried && current.tried) || (patch.found && current.found)) return;
    const updated = { ...current, ...patch };
    this.state.update(file => ({ ...file, missions: { ...file.missions, [missionId]: updated } }));
    this.save();
  }

  /** A mission is checked when its check question (or its alternative) is solved. */
  isChecked(missionId: string): boolean {
    const mission = missionById(missionId);
    if (!mission) return false;
    return this.isSolved(missionId, mission.questionId)
      || (mission.altQuestionId ? this.isSolved(missionId, mission.altQuestionId) : false);
  }

  /** Questions solved on the first attempt - the hub's first-try score (spec section 6). */
  firstTryCount(): number {
    return Object.values(this.state().questions).filter(q => q.solved && q.attempts === 1).length;
  }

  checkedCount(): number {
    return MISSIONS.filter(m => this.isChecked(m.id)).length;
  }

  private load(): ProgressFile {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as ProgressFile;
        if (parsed && typeof parsed === 'object' && parsed.questions) {
          return { questions: parsed.questions, missions: parsed.missions ?? {} };
        }
      }
    } catch { /* fall through to a fresh file */ }
    return { questions: {}, missions: {} };
  }

  private save(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state()));
    } catch { /* storage unavailable: progress lasts for this page load only */ }
  }
}
