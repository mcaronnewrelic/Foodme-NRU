import { Component, ChangeDetectionStrategy, signal } from '@angular/core';

import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { InvestigationComponent } from '../investigation/investigation';
import { INVESTIGATIONS } from '../../services/investigations';
import { MissionProgressService } from '../../services/mission-progress.service';
import { MISSIONS } from '../../services/missions';
import { NewRelicService } from '../../services/newrelic.service';
import { NrConfigService, ScenarioKind, ArmedScenario } from '../../nr-config';
import { errorToJson, flattenError, getErrorSummary, getUserFriendlyErrorMessage } from '../../utils/error.utils';

@Component({
  selector: 'app-how-it-works',
  imports: [RouterModule, FormsModule, HeaderComponent, NrCalloutComponent, NrCheckComponent, InvestigationComponent],
  templateUrl: './how-it-works.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './how-it-works.css'
})
export class HowItWorksComponent {
  protected readonly NrConfigService = NrConfigService;
  readonly errorNrql =
    "SELECT timestamp, errorMessage, pageUrl FROM JavaScriptError WHERE pageUrl LIKE '%how-it-works%' SINCE 1 hour ago";
  readonly actionNrql =
    "SELECT timestamp, actionName, errorType, endpoint, errorSummary FROM PageAction WHERE actionName = 'error_simulation_triggered' SINCE 1 hour ago";
  readonly timingNrql =
    "SELECT average(durationMs), max(durationMs) FROM PageAction WHERE actionName = 'error_simulation_triggered' TIMESERIES SINCE 1 hour ago";
  readonly huntNrql =
    "SELECT timestamp, error.message, transactionName, requestId FROM TransactionError SINCE 1 day ago";

  protected readonly missions = MISSIONS;
  protected readonly investigations = INVESTIGATIONS;

  // Instructor controls for the demo failure scenario
  readonly restaurantNames = signal<string[]>([]);
  readonly itemNames = signal<string[]>([]);
  readonly selectedKind = signal<ScenarioKind>('order-item');
  readonly selectedTarget = signal<string>('');

  constructor(
    private http: HttpClient,
    private newRelicService: NewRelicService,
    public nrConfig: NrConfigService,
    public progress: MissionProgressService
  ) {
    // Log New Relic agent info when component initializes
    this.newRelicService.logAgentInfo();

    // Set a custom attribute for this page
    this.newRelicService.setCustomAttribute('page', 'how-it-works');

    // Current scenario state, and the pick-lists for arming a different one
    this.nrConfig.refreshDemoState();
    this.http.get<{ name: string; menuItems?: { name: string }[] }[]>('/api/restaurant').subscribe({
      next: restaurants => {
        this.restaurantNames.set(restaurants.map(r => r.name));
        this.itemNames.set([...new Set(restaurants.flatMap(r => (r.menuItems || []).map(m => m.name)))]);
        this.selectedTarget.set(this.targetsForKind()[0] || '');
      },
      error: () => {}
    });
  }

  /** The armed scenario in plain language, from the app-wide nr-config signal. */
  armedDescription(): string | null {
    const scenario = this.nrConfig.armedScenario();
    return scenario ? NrConfigService.describeScenario(scenario) : null;
  }

  /**
   * The exact error message the armed failure throws, built from the same
   * templates the server uses (server/index.js): the menu failure embeds
   * the route slug it was called with; the order failures embed the
   * restaurant / item display names.
   */
  get armedErrorMessage(): string {
    const s = this.nrConfig.armedScenario();
    if (!s) return '';
    switch (s.kind) {
      case 'restaurant':
        return `Menu data for "${s.target}" is corrupted: menu_items.category is null for 3 rows`;
      case 'order-restaurant':
        return `Kitchen at "${s.targetName}" is not accepting orders: ticket printer offline`;
      case 'order-item':
        return `Inventory check failed for "${s.targetName}": stock count is -2`;
    }
  }

  currentDescription(): string | null {
    const state = this.nrConfig.demoState();
    if (!state?.armed) return null;
    return NrConfigService.describeScenario({ ...state.armed, source: state.source as ArmedScenario['source'] });
  }

  targetsForKind(): string[] {
    return this.selectedKind() === 'order-item' ? this.itemNames() : this.restaurantNames();
  }

  onKindChange(kind: ScenarioKind) {
    this.selectedKind.set(kind);
    this.selectedTarget.set(this.targetsForKind()[0] || '');
  }

  armSelected() {
    if (this.selectedTarget()) {
      this.nrConfig.armScenario(this.selectedKind(), this.selectedTarget());
    }
  }

  simulateError() {
    const startedAt = performance.now();
    
    this.http.get('/simulate/error/sync').subscribe({
      next: (response) => {
        console.log('Unexpected success:', response);
      },
      error: (error) => {
        console.error(errorToJson(error));
        this.newRelicService.noticeError(new Error(getErrorSummary(error)));
        this.newRelicService.addPageAction('error_simulation_triggered', {
          errorType: 'sync',
          endpoint: '/simulate/error/sync',
          errorSummary: getErrorSummary(error),
          durationMs: Math.round(performance.now() - startedAt)
        });
        // Triggering the simulated error is Mission 5's Try (spec section 2).
        this.progress.markTried('mission-5');
        
        // Show user-friendly message
        const userMessage = getUserFriendlyErrorMessage(error);
        alert(`${userMessage}\n\nTechnical details: ${getErrorSummary(error)}\n\nCheck your APM dashboard for the error event.`);
      }
    });
  }
}
