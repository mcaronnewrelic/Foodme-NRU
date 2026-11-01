import { Component, OnInit, signal, computed, ChangeDetectionStrategy } from '@angular/core';

import { Router } from '@angular/router';
import { OrderService } from '../../services/order.service';
import { CustomerService } from '../../services/customer.service';
import { Order } from '../../models/order.model';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { MissionProgressService } from '../../services/mission-progress.service';

@Component({
  selector: 'app-orders',
  standalone: true,
  imports: [HeaderComponent, NrCalloutComponent, NrCheckComponent],
  templateUrl: './orders.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrls: ['./orders.css']
})
export class OrdersComponent implements OnInit {
  // Scoped to this visitor's lookups: the server stamps each lookup
  // transaction with userID = 'user_' + the customer's name normalised,
  // and the name is the demoCode (spec section 2, Mission 4) - supplied
  // to the callout as the <userId> token.
  readonly ordersNrql =
    "SELECT timestamp, userID, operation, duration FROM Transaction WHERE operation = 'get_orders_by_phone' AND userID = '<userId>' SINCE 1 day ago";

  orders = signal<Order[]>([]);
  loading = signal<boolean>(false);
  error = signal<string | null>(null);

  // Computed properties for filtering and display
  sortedOrders = computed(() => {
    return this.orders().sort((a, b) => 
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  });

  constructor(
    private orderService: OrderService,
    private customerService: CustomerService,
    public router: Router,
    private identity: DemoIdentityService,
    private progress: MissionProgressService
  ) {}

  /** The userID the server derives from this visitor's code, for the Find query. */
  get lookupTokens(): Record<string, string> {
    const userId = 'user_' + this.identity.code().toLowerCase().replace(/[^a-z0-9]/g, '_');
    return { userId };
  }

  ngOnInit() {
    // Check if customer has completed their information
    const customer = this.customerService.customer();
    
    if (!customer.phone) {
      this.router.navigate(['/customer']);
      return;
    }

    this.loadOrders();
  }

  loadOrders() {
    this.loading.set(true);
    this.error.set(null);

    const customer = this.customerService.customer();
    const phone = customer.phone;

    // Orders are looked up by the (sample) phone number only: email is not
    // collected anywhere in the demo, so there is nothing real to look up.
    if (phone) {
      this.loadOrdersByPhone(phone);
    } else {
      this.error.set('No customer information available');
      this.loading.set(false);
    }
  }

  private loadOrdersByPhone(phone: string) {
    this.orderService.getOrdersByCustomerPhone(phone).subscribe({
      next: (orders) => {
        this.orders.set(orders);
        this.loading.set(false);
        // Looking the order up again is Mission 4's Try (spec section 2).
        this.progress.markTried('mission-4');
      },
      error: (err) => {
        console.error('Error loading orders by phone:', err);
        this.error.set('Failed to load orders');
        this.loading.set(false);
      }
    });
  }

  getStatusDisplayName(status: string): string {
    const statusMap: { [key: string]: string } = {
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing',
      'ready': 'Ready for Pickup',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled'
    };
    return statusMap[status] || status;
  }

  getStatusClass(status: string): string {
    const statusClasses: { [key: string]: string } = {
      'pending': 'status-pending',
      'confirmed': 'status-confirmed',
      'preparing': 'status-preparing',
      'ready': 'status-ready',
      'delivered': 'status-delivered',
      'cancelled': 'status-cancelled'
    };
    return statusClasses[status] || 'status-pending';
  }

  formatDate(date: Date): string {
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  formatCurrency(amount: number): string {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  }

  navigateToRestaurant(restaurantId: string) {
    // This would need the restaurant name slug, but for now we'll navigate to restaurants page
    this.router.navigate(['/restaurants']);
  }

  reorder(order: Order) {
    // For now, just navigate to the restaurant
    this.navigateToRestaurant(order.restaurantId);
  }
}