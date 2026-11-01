import { Component, inject, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { MissionProgressService } from '../../services/mission-progress.service';

@Component({
  selector: 'app-thank-you',
  imports: [RouterModule, HeaderComponent, NrCalloutComponent, NrCheckComponent],
  templateUrl: './thank-you.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './thank-you.css'
})
export class ThankYouComponent {
  private progress = inject(MissionProgressService);

  // Set by checkout through router state; missing if someone opens /thank-you directly
  readonly orderId: number | undefined = history.state?.orderId;
  readonly requestId: string | undefined = history.state?.requestId;

  constructor() {
    // Reaching this page with an order is Mission 3's Try (spec section 2).
    if (this.requestId) this.progress.markTried('mission-3');
  }

  /** Mission 3's evidence answer: the last 4 characters of this order's requestId. */
  get requestIdTail(): string {
    return this.requestId?.slice(-4) ?? '';
  }

  readonly orderEventNrql = `SELECT * FROM \`Order\` WHERE requestId = '${this.requestId}' SINCE 1 day ago`;
  readonly transactionNrql =
    `SELECT customer, restaurant, itemCount, orderTotal, userID, orderId, duration FROM Transaction WHERE requestId = '${this.requestId}' SINCE 1 day ago`;
  readonly metricsNrql =
    "SELECT count(newrelic.timeslice.value), sum(newrelic.timeslice.value) FROM Metric WHERE appName = 'OrderUp' AND metricTimesliceName IN ('Custom/Orders/count', 'Custom/Orders/total') FACET metricTimesliceName TIMESERIES SINCE 1 day ago";
}
