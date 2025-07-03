import { Injectable, signal, computed, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CartItem, Customer } from '../models/restaurant.model';

@Injectable({
  providedIn: 'root'
})
export class CartService {
  private http = inject(HttpClient);
  private cartItemsSignal = signal<CartItem[]>([]);

  cartItems = this.cartItemsSignal.asReadonly();
  
  totalItems = computed(() => 
    this.cartItemsSignal().reduce((sum, item) => sum + item.quantity, 0)
  );
  
  totalPrice = computed(() =>
    this.cartItemsSignal().reduce((sum, item) => sum + (item.menuItem.price * item.quantity), 0)
  );

  addToCart(item: CartItem) {
    this.cartItemsSignal.update(items => {
      const existingIndex = items.findIndex(
        cartItem => cartItem.menuItem.id === item.menuItem.id
      );
      
      if (existingIndex >= 0) {
        const updatedItems = [...items];
        updatedItems[existingIndex].quantity += item.quantity;
        return updatedItems;
      } else {
        return [...items, item];
      }
    });
  }

  removeFromCart(menuItemId: string) {
    this.cartItemsSignal.update(items => 
      items.filter(item => item.menuItem.id !== menuItemId)
    );
  }

  updateQuantity(menuItemId: string, quantity: number) {
    if (quantity <= 0) {
      this.removeFromCart(menuItemId);
      return;
    }
    
    this.cartItemsSignal.update(items =>
      items.map(item =>
        item.menuItem.id === menuItemId
          ? { ...item, quantity }
          : item
      )
    );
  }

  clearCart() {
    this.cartItemsSignal.set([]);
  }

  private readonly API_URL_ORDER = '/api/order';

  submitOrder(customer: Customer): Observable<{orderId: number}> {
    const cartItems = this.cartItemsSignal();
    
    if (cartItems.length === 0) {
      throw new Error('Cannot submit empty cart');
    }

    // Get the restaurant from the first item (assuming all items are from the same restaurant)
    const restaurant = cartItems[0].restaurant;

    // Transform cart items to the format expected by the API
    const orderItems = cartItems.map(cartItem => ({
      id: cartItem.menuItem.id,
      name: cartItem.menuItem.name,
      price: cartItem.menuItem.price,
      qty: cartItem.quantity
    }));

    // Create the order object in the format expected by the server
    const order = {
      deliverTo: {
        name: customer.name || '',
        email: customer.email || '',
        phone: customer.phone || '',
        address: customer.address || ''
      },
      restaurant: {
        id: restaurant.id,
        name: restaurant.name
      },
      items: orderItems,
      total: this.totalPrice(),
      timestamp: new Date().toISOString()
    };

    // Post to the API endpoint
    return this.http.post<{orderId: number}>(this.API_URL_ORDER, order);
  }
}
