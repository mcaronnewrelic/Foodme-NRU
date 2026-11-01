import { Component, OnInit, signal, computed, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { RestaurantService } from '../../services/restaurant.service';
import { CartService } from '../../services/cart.service';
import { CustomerService } from '../../services/customer.service';
import { Restaurant, MenuItem } from '../../models/restaurant.model';

@Component({
  selector: 'app-menu',
  imports: [RouterModule, HeaderComponent, FormsModule, NrCalloutComponent, NrCheckComponent],
  templateUrl: './menu.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './menu.css'
})
export class MenuComponent implements OnInit {
  readonly menuStatusNrql =
    "SELECT count(*) FROM Transaction WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/GET//api/restaurant/by-name/:name' FACET request.uri, http.statusCode SINCE 1 day ago";
  readonly menuNrql =
    "SELECT count(*), average(duration) FROM Transaction WHERE appName = 'OrderUp' AND name = 'WebTransaction/Expressjs/GET//api/restaurant/by-name/:name' FACET request.uri SINCE 1 day ago";

  restaurant = signal<Restaurant | null>(null);
  loading = signal(true);
  error = signal<string | null>(null);
  
  // Visual feedback for adding items to cart
  addingToCart = signal<string | null>(null);
  recentlyAdded = signal<Set<string>>(new Set());
  
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

    // Get restaurant name slug from route params
    const restaurantName = this.route.snapshot.paramMap.get('restaurantName');
    if (restaurantName) {
      this.loadRestaurant(restaurantName);
    } else {
      this.error.set('No restaurant name provided');
      this.loading.set(false);
    }
  }

  loadRestaurant(nameSlug: string) {
    this.loading.set(true);
    this.error.set(null);
    
    this.restaurantService.getRestaurantByName(nameSlug).subscribe({
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
      // Set visual feedback
      this.addingToCart.set(item.id);
      
      // Add to cart
      this.cartService.addToCart({
        menuItem: item,
        quantity: 1,
        restaurant: restaurant
      });
      
      // Add to recently added set for visual feedback
      const currentSet = this.recentlyAdded();
      currentSet.add(item.id);
      this.recentlyAdded.set(new Set(currentSet));
      
      // Clear adding state after animation
      setTimeout(() => {
        this.addingToCart.set(null);
      }, 500);
      
      // Clear recently added state after feedback period
      setTimeout(() => {
        const currentSet = this.recentlyAdded();
        currentSet.delete(item.id);
        this.recentlyAdded.set(new Set(currentSet));
      }, 2000);
    }
  }

  isAddingToCart(itemId: string): boolean {
    return this.addingToCart() === itemId;
  }

  isRecentlyAdded(itemId: string): boolean {
    return this.recentlyAdded().has(itemId);
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

  scrollToCategory(category: string) {
    const elementId = this.getCategoryId(category);
    const element = document.getElementById(elementId);
    if (element) {
      element.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'start',
        inline: 'nearest'
      });
    }
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
