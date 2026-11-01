import { Injectable, inject } from '@angular/core';
import { EventTypesService } from './event-types.service';

// Declare the global newrelic object
declare global {
  interface Window {
    newrelic: any;
  }
}

@Injectable({
  providedIn: 'root'
})
export class NewRelicService {
  private eventTypes = inject(EventTypesService);

  private get newrelic() {
    return window.newrelic;
  }

  /**
   * Check if New Relic browser agent is available
   */
  isAvailable(): boolean {
    return !!(window.newrelic && typeof window.newrelic === 'object');
  }

  /**
   * Log an error to New Relic
   * @param error - The error to log
   */
  noticeError(error: any): void {
    if (this.isAvailable() && typeof this.newrelic.noticeError === 'function') {
      this.newrelic.log(error); // Log the error to New Relic
      this.newrelic.noticeError(error);
      this.eventTypes.mark('JavaScriptError');
      console.log('Error logged to New Relic browser agent');
    } else {
      console.warn('New Relic browser agent not available for error logging');
    }
  }

    /**
   * Log an error to New Relic
   * @param error - The error to log
   */
  log(logmessage: any): void {
    if (this.isAvailable() && typeof this.newrelic.log === 'function') {
      this.newrelic.log(logmessage); 
    } else {
      console.warn('New Relic browser agent not available for error logging');
    }
  }

  /**
   * Add custom attributes to the current page view
   * @param attributes - Object containing key-value pairs of attributes
   */
  addPageAction(actionName: string, attributes?: Record<string, any>): void {
    if (this.isAvailable() && typeof this.newrelic.addPageAction === 'function') {
      this.newrelic.addPageAction(actionName, attributes);
      this.eventTypes.mark('PageAction');
      console.log(`Page action '${actionName}' logged to New Relic`);
    } else {
      console.warn('New Relic browser agent not available for page action logging');
    }
  }

  /**
   * Record a custom event of the given type (e.g. OrderupQuizAnswer).
   * Falls back to a PageAction named after the type if the agent build
   * has no recordCustomEvent, so the data lands either way.
   */
  recordCustomEvent(eventType: string, attributes?: Record<string, any>): void {
    if (!this.isAvailable()) {
      console.warn('New Relic browser agent not available for custom event logging');
      return;
    }
    if (typeof this.newrelic.recordCustomEvent === 'function') {
      this.newrelic.recordCustomEvent(eventType, attributes);
    } else if (typeof this.newrelic.addPageAction === 'function') {
      this.newrelic.addPageAction(eventType, attributes);
    }
  }

  /**
   * Set custom attributes for the current page view
   * @param attributes - Object containing key-value pairs of attributes
   */
  setCustomAttribute(name: string, value: any): void {
    if (this.isAvailable() && typeof this.newrelic.setCustomAttribute === 'function') {
      this.newrelic.setCustomAttribute(name, value);
      console.log(`Custom attribute '${name}' set in New Relic`);
    } else {
      console.warn('New Relic browser agent not available for custom attributes');
    }
  }

  /**
   * Set the user ID for the current session
   * @param userId - The user identifier
   */
  setUserId(userId: string): void {
    if (this.isAvailable() && typeof this.newrelic.setUserId === 'function') {
      this.newrelic.setUserId(userId);
      console.log(`User ID '${userId}' set in New Relic`);
    } else {
      console.warn('New Relic browser agent not available for user ID setting');
    }
  }

  /**
   * Log information about the New Relic browser agent
   */
  logAgentInfo(): void {
    if (this.isAvailable()) {
      console.log('New Relic Browser Agent Info:', {
        available: true,
        methods: Object.keys(this.newrelic).filter(key => typeof this.newrelic[key] === 'function'),
        info: this.newrelic.info || 'No info available'
      });
    } else {
      console.log('New Relic Browser Agent: Not available');
    }
  }
}
