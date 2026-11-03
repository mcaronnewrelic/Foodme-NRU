import { Component, inject, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { MissionProgressService } from '../../services/mission-progress.service';
import { CartItem } from '../../models/restaurant.model';

@Component({
  selector: 'app-thank-you',
  imports: [RouterModule, HeaderComponent, NrCalloutComponent, NrCheckComponent],
  templateUrl: './thank-you.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './thank-you.css'
})
export class ThankYouComponent {
  protected readonly Math = Math;
  private progress = inject(MissionProgressService);

  // Set by checkout through router state; missing if someone opens /thank-you directly
  readonly orderId: string | undefined = history.state?.orderId != null
    ? String(history.state.orderId)
    : undefined;
  readonly items: CartItem[] = history.state?.items ?? [];
  readonly restaurantName = this.items[0]?.restaurant.name;
  readonly itemCount = this.items.reduce((total, item) => total + item.quantity, 0);
  readonly orderTotal = this.items.reduce(
    (total, item) => total + Math.round(item.menuItem.price * 100) * item.quantity, 0
  ) / 100;

  constructor() {
    // Reaching this page with an order is Mission 3's Try (spec section 2).
    if (this.orderId) this.progress.markTried('mission-3');
  }

  get orderIdTail(): string {
    return this.orderId?.slice(-4) ?? '';
  }

  private readonly orderIdLiteral = `'${(this.orderId ?? '').replace(/'/g, "\\'")}'`;
  readonly itemsOrderedNrql =
    `FROM ItemsOrdered SELECT orderId, itemName, itemCount, unitPrice, itemTotal WHERE orderId = ${this.orderIdLiteral} SINCE 1 day ago LIMIT MAX`;
  readonly transactionNrql =
    `FROM Transaction SELECT orderId, customer, restaurant, itemCount, orderTotal, duration, http.statusCode WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/POST//api/order' AND orderId = ${this.orderIdLiteral} SINCE 1 day ago`;
  readonly joinedItemsNrql =
    `FROM ItemsOrdered\nJOIN (FROM Transaction SELECT orderId, customer, restaurant, orderTotal, duration, http.statusCode WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/POST//api/order' AND orderId = ${this.orderIdLiteral} LIMIT MAX) ON orderId\nSELECT orderId, customer, restaurant, itemName, itemCount, unitPrice, itemTotal, orderTotal, duration, http.statusCode\nWHERE orderId = ${this.orderIdLiteral} SINCE 1 day ago LIMIT MAX`;
  readonly metricsNrql =
    "FROM Metric SELECT count(newrelic.timeslice.value) AS 'Orders', sum(newrelic.timeslice.value) AS 'Revenue', average(newrelic.timeslice.value) AS 'Average order total' WHERE appName = 'OrderUp' AND (metricTimesliceName = 'Custom/total' OR metricTimesliceName LIKE 'Custom/%/total') FACET metricTimesliceName TIMESERIES SINCE 1 day ago";
}
