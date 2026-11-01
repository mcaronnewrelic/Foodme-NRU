import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export type ScenarioKind = 'restaurant' | 'order-restaurant' | 'order-item';

export interface ArmedScenario {
  kind: ScenarioKind;
  /** Slug the server compares against */
  target: string;
  /** Display name, for showing to humans */
  targetName: string;
  source: 'env' | 'manual' | 'rotation';
}

export interface DemoFailureState {
  source: 'env' | 'manual' | 'rotation' | 'none';
  week: string;
  armed: { kind: ScenarioKind; target: string; targetName: string } | null;
}

const NR_BASE_URL = 'https://one.newrelic.com';
const CALLOUTS_STORAGE_KEY = 'foodme-nr-callouts';
const CALLOUTS_SHOWN_BY_DEFAULT = false;

@Injectable({ providedIn: 'root' })
export class NrConfigService {
  // Stays null until the server answers, or if NEW_RELIC_ACCOUNT_ID isn't set
  readonly accountId = signal<string | null>(null);

  readonly browserEntityGuid = signal<string | null>(null);
  readonly showCallouts = signal(this.loadShowCallouts());

  /** The demo failure scenario the server currently has armed, if any. */
  readonly armedScenario = signal<ArmedScenario | null>(null);
  readonly demoState = signal<DemoFailureState | null>(null);

  constructor(private http: HttpClient) {
    http.get<{ accountId: string | null; browserEntityGuid: string | null; armedScenario: ArmedScenario | null }>('/api/nr-config')
      .subscribe({
        next: config => {
          this.accountId.set(config.accountId);
          this.browserEntityGuid.set(config.browserEntityGuid);
          this.armedScenario.set(config.armedScenario);
        },
        error: () => {}
      });
  }

  /** Plain-language description of the armed scenario, for banners/panels. */
  static describeScenario(s: ArmedScenario): string {
    switch (s.kind) {
      case 'restaurant': return `The page for “${s.targetName}” fails to load.`;
      case 'order-restaurant': return `Orders placed with “${s.targetName}” fail.`;
      case 'order-item': return `Orders containing “${s.targetName}” fail.`;
    }
  }

  refreshDemoState(): void {
    this.http.get<DemoFailureState>('/api/demo/failures').subscribe({
      next: state => this.applyDemoState(state),
      error: () => {}
    });
  }

  /** Arm one scenario manually (instructor override). */
  armScenario(kind: ScenarioKind, target: string): void {
    this.http.post<DemoFailureState>('/api/demo/failures', { kind, target }).subscribe({
      next: state => this.applyDemoState(state),
      error: () => {}
    });
  }

  /** Arm nothing at all (instructor override), until cleared. */
  disarmScenario(): void {
    this.http.post<DemoFailureState>('/api/demo/failures', { kind: 'off' }).subscribe({
      next: state => this.applyDemoState(state),
      error: () => {}
    });
  }

  /** Drop the instructor override; back to env / weekly rotation. */
  clearScenarioOverride(): void {
    this.http.delete<DemoFailureState>('/api/demo/failures').subscribe({
      next: state => this.applyDemoState(state),
      error: () => {}
    });
  }

  private applyDemoState(state: DemoFailureState): void {
    this.demoState.set(state);
    this.armedScenario.set(state.armed ? { ...state.armed, source: state.source as ArmedScenario['source'] } : null);
  }

  private accountNoteClaimed = false;

  /**
   * The spec section 5.4 account note ("opens in the shared demo account")
   * is shown once per page, under the first callout's Find button. The
   * first callout to ask claims it; later callouts on the page get false.
   */
  claimAccountNote(): boolean {
    if (this.accountNoteClaimed) return false;
    this.accountNoteClaimed = true;
    return true;
  }

  toggleCallouts(): void {
    this.showCallouts.update(shown => !shown);
    localStorage.setItem(CALLOUTS_STORAGE_KEY, String(this.showCallouts()));
  }

  private loadShowCallouts(): boolean {
    // Instructor override (spec section 7): ?callouts=1 on a handout or QR
    // link shows the callouts for this visit without changing the visitor's
    // stored preference; ?callouts=0 forces them off the same way.
    if (typeof location !== 'undefined') {
      const param = new URLSearchParams(location.search).get('callouts');
      if (param === '1' || param === 'true') return true;
      if (param === '0' || param === 'false') return false;
    }
    const stored = typeof localStorage === 'undefined' ? null : localStorage.getItem(CALLOUTS_STORAGE_KEY);
    return stored === null ? CALLOUTS_SHOWN_BY_DEFAULT : stored === 'true';
  }

  browserErrorsUrl(): string | null {
    const guid = this.browserEntityGuid();
    return guid ? `${NR_BASE_URL}/nr1-core/errors-inbox/entity-inbox/${guid}` : null;
  }

  nrqlUrl(nrql: string): string | null {
    const accountId = Number(this.accountId());
    if (!accountId) return null;
    const pane = {
      nerdletId: 'data-exploration.query-builder',
      initialActiveInterface: 'nrqlEditor',
      initialQueries: [{ accountId, nrql }],
      initialAccountId: accountId
    };
    return `${NR_BASE_URL}/launcher/data-exploration.query-builder?pane=${btoa(JSON.stringify(pane))}`;
  }
}
