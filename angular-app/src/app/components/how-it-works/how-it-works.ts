import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NewRelicService } from '../../services/newrelic.service';
import { errorToJson, flattenError, getErrorSummary, getUserFriendlyErrorMessage } from '../../utils/error.utils';

@Component({
  selector: 'app-how-it-works',
  imports: [CommonModule, RouterModule, HeaderComponent, NrCalloutComponent],
  templateUrl: './how-it-works.html',
  styleUrl: './how-it-works.css'
})
export class HowItWorksComponent {
  readonly errorNrql =
    "SELECT timestamp, errorMessage, pageUrl FROM JavaScriptError WHERE pageUrl LIKE '%how-it-works%' SINCE 1 hour ago";
  readonly actionNrql =
    "SELECT timestamp, actionName, errorType, endpoint, errorSummary FROM PageAction WHERE actionName = 'error_simulation_triggered' SINCE 1 hour ago";
  readonly timingNrql =
    "SELECT average(durationMs), max(durationMs) FROM PageAction WHERE actionName = 'error_simulation_triggered' TIMESERIES SINCE 1 hour ago";

  constructor(
    private http: HttpClient,
    private newRelicService: NewRelicService
  ) {
    // Log New Relic agent info when component initializes
    this.newRelicService.logAgentInfo();
    
    // Set a custom attribute for this page
    this.newRelicService.setCustomAttribute('page', 'how-it-works');
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
