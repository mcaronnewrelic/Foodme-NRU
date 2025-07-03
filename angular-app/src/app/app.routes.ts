import { Routes } from '@angular/router';
import { CustomerComponent } from './components/customer/customer';

export const routes: Routes = [
  { path: '', redirectTo: '/customer', pathMatch: 'full' },
  { 
    path: 'restaurants', 
    loadComponent: () => import('./components/restaurants/restaurants').then(m => m.RestaurantsComponent)
  },
  { 
    path: 'menu/:restaurantId', 
    loadComponent: () => import('./components/menu/menu').then(m => m.MenuComponent)
  },
  { 
    path: 'checkout', 
    loadComponent: () => import('./components/checkout/checkout').then(m => m.CheckoutComponent)
  },
  { path: 'customer', component: CustomerComponent },
  { 
    path: 'how-it-works', 
    loadComponent: () => import('./components/how-it-works/how-it-works').then(m => m.HowItWorksComponent)
  },
  { 
    path: 'who-we-are', 
    loadComponent: () => import('./components/who-we-are/who-we-are').then(m => m.WhoWeAreComponent)
  },
  { 
    path: 'thank-you', 
    loadComponent: () => import('./components/thank-you/thank-you').then(m => m.ThankYouComponent)
  }
];
