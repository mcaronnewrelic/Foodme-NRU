import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HeaderComponent } from '../header/header';
import { RestaurantService } from '../../services/restaurant.service';
import { CartService } from '../../services/cart.service';
import { CustomerService } from '../../services/customer.service';
import { Restaurant, MenuItem } from '../../models/restaurant.model';

@Component({
  selector: 'app-menu',
  imports: [CommonModule, RouterModule, HeaderComponent, FormsModule],
  templateUrl: './menu.html',
  styleUrl: './menu.css'
})
export class MenuComponent implements OnInit {
  restaurant = signal<Restaurant | null>(null);
  loading = signal(true);
  error = signal<string | null>(null);
  
  // Group menu items by category
  menuCategories = computed(() => {
    const restaurant = this.restaurant();
    if (!restaurant?.menuItems) return {};
    
    return restaurant.menuItems.reduce((categories, item) => {
      if (!categories[item.category]) {
        categories[item.category] = [];
      }
      categories[item.category].push(item);
      return categories;
    }, {} as Record<string, MenuItem[]>);
  });

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private restaurantService: RestaurantService,
    public cartService: CartService,
    private customerService: CustomerService
  ) {}

  ngOnInit() {
    // Check if customer has completed their information
    if (!this.customerService.address) {
      this.router.navigate(['/customer']);
      return;
    }

    // Get restaurant ID from route params
    const restaurantId = this.route.snapshot.paramMap.get('restaurantId');
    if (restaurantId) {
      this.loadRestaurant(restaurantId);
    } else {
      this.error.set('No restaurant ID provided');
      this.loading.set(false);
    }
  }

  loadRestaurant(id: string) {
    this.loading.set(true);
    this.error.set(null);
    
    this.restaurantService.getRestaurant(id).subscribe({
      next: (restaurant) => {
        this.restaurant.set(restaurant);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Error loading restaurant:', err);
        this.error.set('Failed to load restaurant menu');
        this.loading.set(false);
      }
    });
  }

  addToCart(item: MenuItem) {
    const restaurant = this.restaurant();
    if (restaurant) {
      this.cartService.addToCart({
        menuItem: item,
        quantity: 1,
        restaurant: restaurant
      });
    }
  }

  getCategoryKeys() {
    return Object.keys(this.menuCategories());
  }

  getCategoryId(category: string): string {
    return 'category-' + category.toLowerCase().replace(/\s+/g, '-');
  }

  getCategoryLink(category: string): string {
    return '#category-' + category.toLowerCase().replace(/\s+/g, '-');
  }

  goBack() {
    this.router.navigate(['/restaurants']);
  }

  getFilledStars(rating: number) {
    return '\u2605'.repeat(Math.floor(rating));
  }

  getEmptyStars(rating: number) {
    return '\u2606'.repeat(5 - Math.floor(rating));
  }

  proceedToCheckout() {
    this.router.navigate(['/checkout']);
  }
}
