import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';
import { CartService } from './cart.service';
import { DemoIdentityService } from './demo-identity.service';
import { CartItem } from '../models/restaurant.model';

describe('CartService restaurant validation', () => {
  let service: CartService;
  const item = (restaurantId: string): CartItem => ({
    restaurant: { id: restaurantId, name: restaurantId, cuisine: 'Test', price: 1, rating: 5 },
    menuItem: { id: 'shared-id', name: 'Soup', description: '', price: 5, category: 'Main' },
    quantity: 1
  });

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(),
        { provide: DemoIdentityService, useValue: { code: () => 'OU-TEST' } }]
    });
    service = TestBed.inject(CartService);
  });

  it('rejects another restaurant without changing cart contents or totals', () => {
    expect(service.addToCart(item('a'))).toBeTrue();
    expect(service.addToCart(item('b'))).toBeFalse();
    expect(service.cartItems().length).toBe(1);
    expect(service.totalItems()).toBe(1);
    expect(service.totalPrice()).toBe(5);
  });

  it('allows more items from the same restaurant', () => {
    service.addToCart(item('a'));
    expect(service.addToCart(item('a'))).toBeTrue();
    expect(service.totalItems()).toBe(2);
  });

  it('allows switching restaurants after clearing or removing the last item', () => {
    service.addToCart(item('a'));
    service.clearCart();
    expect(service.addToCart(item('b'))).toBeTrue();
    service.removeFromCart('shared-id');
    expect(service.addToCart(item('a'))).toBeTrue();
  });

  it('submits the selected restaurant and menu item ID', () => {
    service.addToCart(item('a'));
    service.submitOrder({ name: 'Test' }).subscribe();
    const http = TestBed.inject(HttpTestingController);
    const request = http.expectOne('/api/order');
    expect(request.request.body.restaurant.id).toBe('a');
    expect(request.request.body.items[0].id).toBe('shared-id');
    request.flush({ orderId: 1, requestId: 'test' });
    http.verify();
  });
});