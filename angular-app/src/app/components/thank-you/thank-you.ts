import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';

@Component({
  selector: 'app-thank-you',
  imports: [CommonModule, RouterModule, HeaderComponent, NrCalloutComponent],
  templateUrl: './thank-you.html',
  styleUrl: './thank-you.css'
})
export class ThankYouComponent {
  // Set by checkout through router state; missing if someone opens /thank-you directly
  readonly orderId: number | undefined = history.state?.orderId;
  readonly requestId: string | undefined = history.state?.requestId;

  readonly orderEventNrql = `SELECT * FROM \`Order\` WHERE requestId = '${this.requestId}' SINCE 1 day ago`;
  readonly transactionNrql =
    `SELECT customer, restaurant, itemCount, orderTotal, userID, orderId, duration FROM Transaction WHERE requestId = '${this.requestId}' SINCE 1 day ago`;
  readonly metricsNrql =
    "SELECT count(newrelic.timeslice.value), sum(newrelic.timeslice.value) FROM Metric WHERE appName = 'FoodMe' AND metricTimesliceName IN ('Custom/Orders/count', 'Custom/Orders/total') FACET metricTimesliceName TIMESERIES SINCE 1 day ago";
}
