import { Routes } from '@angular/router';
import { CustomerComponent } from './components/customer/customer';

export const routes: Routes = [
  { path: '', redirectTo: '/customer', pathMatch: 'full' },
  { 
    path: 'restaurants', 
    loadComponent: () => import('./components/restaurants/restaurants').then(m => m.RestaurantsComponent)
  },
  { 
    path: 'menu/:restaurantName', 
    loadComponent: () => import('./components/menu/menu').then(m => m.MenuComponent)
  },
  { 
    path: 'checkout', 
    loadComponent: () => import('./components/checkout/checkout').then(m => m.CheckoutComponent)
  },
  { 
    path: 'orders', 
    loadComponent: () => import('./components/orders/orders').then(m => m.OrdersComponent)
  },
  { path: 'customer', component: CustomerComponent },
  {
    path: 'missions',
    loadComponent: () => import('./components/missions-page/missions-page').then(m => m.MissionsPageComponent)
  },
  {
    path: 'investigations',
    loadComponent: () => import('./components/investigations-page/investigations-page').then(m => m.InvestigationsPageComponent)
  },
  {
    path: 'instructor',
    loadComponent: () => import('./components/instructor/instructor').then(m => m.InstructorComponent)
  },
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
