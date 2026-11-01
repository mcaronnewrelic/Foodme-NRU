import { Component, ChangeDetectionStrategy, signal } from '@angular/core';

import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NewRelicService } from '../../services/newrelic.service';
import { NrConfigService, ScenarioKind, ArmedScenario } from '../../nr-config';
import { errorToJson, flattenError, getErrorSummary, getUserFriendlyErrorMessage } from '../../utils/error.utils';

@Component({
  selector: 'app-how-it-works',
  imports: [RouterModule, FormsModule, HeaderComponent, NrCalloutComponent],
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

  // Instructor controls for the demo failure scenario
  readonly restaurantNames = signal<string[]>([]);
  readonly itemNames = signal<string[]>([]);
  readonly selectedKind = signal<ScenarioKind>('order-item');
  readonly selectedTarget = signal<string>('');

  constructor(
    private http: HttpClient,
    private newRelicService: NewRelicService,
    public nrConfig: NrConfigService
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
        
        // Show user-friendly message
        const userMessage = getUserFriendlyErrorMessage(error);
        alert(`${userMessage}\n\nTechnical details: ${getErrorSummary(error)}\n\nCheck your APM dashboard for the error event.`);
      }
    });
  }
}
