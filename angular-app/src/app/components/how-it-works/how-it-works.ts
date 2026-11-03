import { Component, ChangeDetectionStrategy, signal } from '@angular/core';

import { RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { MissionProgressService } from '../../services/mission-progress.service';
import { NewRelicService } from '../../services/newrelic.service';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { CODE_ALPHABET } from '../../services/demo-identity-bootstrap';
import { NrConfigService } from '../../nr-config';
import { errorToJson, flattenError, getErrorSummary, getUserFriendlyErrorMessage } from '../../utils/error.utils';

@Component({
  selector: 'app-how-it-works',
  imports: [RouterModule, HeaderComponent, NrCalloutComponent, NrCheckComponent],
  templateUrl: './how-it-works.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './how-it-works.css'
})
export class HowItWorksComponent {
  readonly errorNrql =
    "SELECT timestamp, errorMessage, pageUrl FROM JavaScriptError WHERE pageUrl LIKE '%how-it-works%' SINCE 1 hour ago";
  readonly actionNrql =
    "SELECT timestamp, actionName, errorType, endpoint, errorSummary FROM PageAction WHERE actionName = 'error_simulation_triggered' SINCE 1 hour ago";
  readonly timingNrql =
    "SELECT average(durationMs), max(durationMs) FROM PageAction WHERE actionName = 'error_simulation_triggered' TIMESERIES SINCE 1 hour ago";
  readonly huntNrql =
    "SELECT timestamp, error.message, transactionName, requestId FROM TransactionError SINCE 1 day ago";

  /** The code in the last simulated error's message. Held in memory only, so the answer lives in the data. */
  readonly incidentTicket = signal<string | null>(null);

  constructor(
    private http: HttpClient,
    private newRelicService: NewRelicService,
    private identity: DemoIdentityService,
    public nrConfig: NrConfigService,
    public progress: MissionProgressService
  ) {
    // Log New Relic agent info when component initializes
    this.newRelicService.logAgentInfo();

    // Set a custom attribute for this page
    this.newRelicService.setCustomAttribute('page', 'how-it-works');

  }

  get incidentNrql(): string {
    return `SELECT timestamp, error.message, error.class, transactionName, scenario FROM TransactionError WHERE demoCode = '${this.identity.code()}' SINCE 1 hour ago`;
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





  private newIncidentTicket(): string {
    let suffix = '';
    for (let index = 0; index < 4; index++) {
      suffix += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
    }
    return `INC-${suffix}`;
  }

  simulateError() {
    const startedAt = performance.now();
    const ticket = this.newIncidentTicket();
    this.incidentTicket.set(ticket);

    // The server picks which failure happens and writes the ticket into its error message.
    this.http
      .get('/simulate/error/incident', { params: { ticket, demoCode: this.identity.code() } })
      .subscribe({
        next: (response) => {
          console.log('Unexpected success:', response);
        },
        error: (error) => {
          console.error(errorToJson(error));
          this.newRelicService.noticeError(new Error(getErrorSummary(error)));
          this.newRelicService.addPageAction('error_simulation_triggered', {
            errorType: 'incident',
            endpoint: '/simulate/error/incident',
            errorSummary: getErrorSummary(error),
            durationMs: Math.round(performance.now() - startedAt)
          });
          // Triggering the simulated error is Mission 5's Try (spec section 2).
          this.progress.markTried('mission-5');

          alert(`${getUserFriendlyErrorMessage(error)}\n\nThe browser only sees the HTTP failure. The server knows what actually broke. Find your incident code in New Relic.`);
        }
      });
  }
}
