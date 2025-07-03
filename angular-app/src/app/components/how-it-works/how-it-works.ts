import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NewRelicService } from '../../services/newrelic.service';
import { errorToJson, flattenError, getErrorSummary, getUserFriendlyErrorMessage } from '../../utils/error.utils';

@Component({
  selector: 'app-how-it-works',
  imports: [CommonModule, RouterModule, HeaderComponent],
  templateUrl: './how-it-works.html',
  styleUrl: './how-it-works.css'
})
export class HowItWorksComponent {
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
    // Start timing for the error simulation
    this.newRelicService.startTime('error_simulation');
    
    this.http.get('/simulate/error/sync').subscribe({
      next: (response) => {
        console.log('Unexpected success:', response);
        this.newRelicService.endTime('error_simulation');
      },
      error: (error) => {
        console.error(errorToJson(error));
        // End timing and log the error using the service
        this.newRelicService.endTime('error_simulation');
        this.newRelicService.noticeError(errorToJson);
        this.newRelicService.addPageAction('error_simulation_triggered', {
          errorType: 'sync',
          endpoint: '/simulate/error/sync',
          errorSummary: getErrorSummary(error)
        });
        
        // Show user-friendly message
        const userMessage = getUserFriendlyErrorMessage(error);
        alert(`${userMessage}\n\nTechnical details: ${getErrorSummary(error)}\n\nCheck your APM dashboard for the error event.`);
      }
    });
  }
}
