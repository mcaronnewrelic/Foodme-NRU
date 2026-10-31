import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { OrderService } from '../../services/order.service';
import { CustomerService } from '../../services/customer.service';
import { Order } from '../../models/order.model';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';

@Component({
  selector: 'app-orders',
  standalone: true,
  imports: [CommonModule, HeaderComponent, NrCalloutComponent],
  templateUrl: './orders.html',
  styleUrls: ['./orders.css']
})
export class OrdersComponent implements OnInit {
  readonly ordersNrql =
    "SELECT timestamp, userID, operation, duration FROM Transaction WHERE operation IN ('get_orders_by_email', 'get_orders_by_phone') SINCE 1 day ago";

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
    public router: Router
  ) {}

  ngOnInit() {
    // Check if customer has completed their information
    const customer = this.customerService.customer();
    
    if (!customer.email && !customer.phone) {
      this.router.navigate(['/customer']);
      return;
    }

    this.loadOrders();
  }

  loadOrders() {
    this.loading.set(true);
    this.error.set(null);

    const customer = this.customerService.customer();
    const email = customer.email;
    const phone = customer.phone;

    if (email) {
      // Try to load orders by email first
      this.orderService.getOrdersByCustomerEmail(email).subscribe({
        next: (orders) => {
          this.orders.set(orders);
          this.loading.set(false);
        },
        error: (err) => {
          console.error('Error loading orders by email:', err);
          // Fallback to phone if available
          if (phone) {
            this.loadOrdersByPhone(phone);
          } else {
            this.error.set('Failed to load orders');
            this.loading.set(false);
          }
        }
      });
    } else if (phone) {
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