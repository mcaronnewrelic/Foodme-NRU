import { Component, inject, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { MissionProgressService } from '../../services/mission-progress.service';
import { OrderStatusService } from '../../services/order-status.service';
import { CartItem } from '../../models/restaurant.model';

@Component({
  selector: 'app-thank-you',
  imports: [
    RouterModule,
    HeaderComponent,
    NrCalloutComponent,
    NrCheckComponent,
  ],
  templateUrl: './thank-you.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './thank-you.css',
})
export class ThankYouComponent {
  protected readonly Math = Math;
  private progress = inject(MissionProgressService);
  protected orderStatus = inject(OrderStatusService);

  /** Domino's-style tracker stages, in lifecycle order. */
  readonly stages = [
    { key: 'pending', label: 'Order received', icon: 'fas fa-receipt' },
    { key: 'preparing', label: 'Preparing', icon: 'fas fa-utensils' },
    { key: 'out_for_delivery', label: 'Out for delivery', icon: 'fas fa-bicycle' },
    { key: 'delivered', label: 'Delivered', icon: 'fas fa-flag-checkered' },
  ];

  /** Index of the current stage, or -1 before the first status / for unknown statuses. */
  get stageIndex(): number {
    const status = this.orderStatus.status();
    return this.stages.findIndex((stage) => stage.key === status);
  }

  // Set by checkout through router state; missing if someone opens /thank-you directly
  readonly orderId: string | undefined =
    history.state?.orderId != null ? String(history.state.orderId) : undefined;
  private readonly requestId: string | undefined = history.state?.requestId;
  readonly hasRequestId = !!this.requestId;
  readonly items: CartItem[] = history.state?.items ?? [];
  readonly restaurantName = this.items[0]?.restaurant.name;
  readonly itemCount = this.items.reduce(
    (total, item) => total + item.quantity,
    0,
  );
  readonly orderTotal =
    this.items.reduce(
      (total, item) =>
        total + Math.round(item.menuItem.price * 100) * item.quantity,
      0,
    ) / 100;

  constructor() {
    // Reaching this page with an order is Mission 3's Try (spec section 2).
    if (this.orderId) {
      this.progress.markTried('mission-3');
      // Watch the order move: the worker pushes each advance over the
      // order-status WebSocket (polling fallback in the service). The
      // service owns the channel from here - the header pill follows
      // the same order across the rest of the site.
      this.orderStatus.track(this.orderId, this.restaurantName);
    }
  }

  get requestIdTail(): string {
    return this.requestId?.slice(-4) ?? '';
  }

  private readonly orderIdLiteral = `'${(this.orderId ?? '').replace(/'/g, "\\'")}'`;
  readonly itemsOrderedNrql = `FROM ItemsOrdered SELECT orderId, itemName, itemCount, unitPrice, itemTotal WHERE orderId = ${this.orderIdLiteral} SINCE 1 day ago LIMIT MAX`;
  readonly transactionNrql = `FROM Transaction SELECT orderId, requestId, customer, restaurant, itemCount, orderTotal, duration, http.statusCode WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/POST//api/order' AND orderId = ${this.orderIdLiteral} SINCE 1 day ago`;
  readonly joinedItemsNrql = `FROM ItemsOrdered\nJOIN (FROM Transaction SELECT orderId, requestId, customer, restaurant, orderTotal, duration, http.statusCode WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/POST//api/order' AND orderId = ${this.orderIdLiteral} LIMIT MAX) ON orderId\nSELECT orderId, requestId, customer, restaurant, itemName, itemCount, unitPrice, itemTotal, orderTotal, duration, http.statusCode\nWHERE orderId = ${this.orderIdLiteral} SINCE 1 day ago LIMIT MAX`;
  readonly metricsNrql =
    "FROM Metric SELECT count(newrelic.timeslice.value) AS 'Orders', sum(newrelic.timeslice.value) AS 'Revenue', average(newrelic.timeslice.value) AS 'Average order total' WHERE appName = 'OrderUp' AND (metricTimesliceName = 'Custom/total' OR metricTimesliceName LIKE 'Custom/%/total') FACET metricTimesliceName TIMESERIES SINCE 1 day ago";
}
