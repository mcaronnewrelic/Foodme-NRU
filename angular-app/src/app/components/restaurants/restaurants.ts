import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { RestaurantService } from '../../services/restaurant.service';
import { CustomerService } from '../../services/customer.service';
import { Restaurant } from '../../models/restaurant.model';
import { CustomerCardComponent } from '../customer-card/customer-card';
import { HeaderComponent } from '../header/header';

@Component({
  selector: 'app-restaurants',
  imports: [CommonModule, RouterModule, FormsModule, CustomerCardComponent, HeaderComponent],
  templateUrl: './restaurants.html',
  styleUrl: './restaurants.css'
})
export class RestaurantsComponent implements OnInit {
  allRestaurants = signal<Restaurant[]>([]);
  
  // Add collapsible state for filters
  filtersCollapsed = signal(true);
  
  filter = signal({
    cuisine: [] as string[],
    price: null as number | null,
    rating: null as number | null,
    sortBy: 'name',
    sortAsc: true
  });

  filteredRestaurants = computed(() => {
    const restaurants = this.allRestaurants();
    const currentFilter = this.filter();
    
    return restaurants
      .filter(restaurant => {
        if (currentFilter.price && currentFilter.price !== restaurant.price) {
          return false;
        }
        if (currentFilter.rating && currentFilter.rating !== restaurant.rating) {
          return false;
        }
        if (currentFilter.cuisine.length && !currentFilter.cuisine.includes(restaurant.cuisine)) {
          return false;
        }
        return true;
      })
      .sort((a, b) => {
        const aVal = (a as any)[currentFilter.sortBy];
        const bVal = (b as any)[currentFilter.sortBy];
        
        if (aVal > bVal) return currentFilter.sortAsc ? 1 : -1;
        if (aVal < bVal) return currentFilter.sortAsc ? -1 : 1;
        return 0;
      });
  });

  cuisineOptions: Record<string, string> = {
    'american': 'American',
    'chinese': 'Chinese',
    'italian': 'Italian',
    'mexican': 'Mexican',
    'thai': 'Thai',
    'indian': 'Indian'
  };

  constructor(
    private restaurantService: RestaurantService,
    private customerService: CustomerService,
    private router: Router
  ) {}

  ngOnInit() {
    if (!this.customerService.address) {
      this.router.navigate(['/customer']);
      return;
    }

    this.restaurantService.getRestaurants().subscribe(restaurants => {
      this.allRestaurants.set(restaurants);
    });
  }

  updateFilter(key: string, value: any) {
    this.filter.update(current => ({ ...current, [key]: value }));
  }

  toggleCuisine(cuisine: string) {
    this.filter.update(current => {
      const newCuisines = current.cuisine.includes(cuisine)
        ? current.cuisine.filter(c => c !== cuisine)
        : [...current.cuisine, cuisine];
      return { ...current, cuisine: newCuisines };
    });
  }

  getCuisineKeys() {
    return Object.keys(this.cuisineOptions);
  }

  getCuisineName(cuisine: string) {
    return this.cuisineOptions[cuisine] || cuisine;
  }

  toggleFilters() {
    this.filtersCollapsed.update(collapsed => !collapsed);
  }

  getStarArray(count: number) {
    return new Array(Math.floor(count));
  }

  getEmptyStarArray(count: number) {
    return new Array(Math.floor(count));
  }

  getFilledStars(rating: number) {
    return '\u2605'.repeat(Math.floor(rating));
  }

  getEmptyStars(rating: number) {
    return '\u2606'.repeat(5 - Math.floor(rating));
  }

  getDollarSigns(price: number) {
    return '$'.repeat(price);
  }

  viewMenu(restaurantId: string) {
    this.router.navigate(['/menu', restaurantId]);
  }

  // Expose customer data for the customer card
  get customer() {
    return this.customerService.customer();
  }

  // Make Object available in template
  Object = Object;
}
