import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Order } from '../models/order.model';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = '/api/orders';

  constructor(private http: HttpClient) {}

  /**
   * Get orders for a customer by their email address
   */
  getOrdersByCustomerEmail(email: string): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/customer/${encodeURIComponent(email)}`);
  }

  /**
   * Get a specific order by ID
   */
  getOrderById(orderId: string): Observable<Order> {
    return this.http.get<Order>(`${this.apiUrl}/${orderId}`);
  }

  /**
   * Get orders for a customer by their phone number (fallback)
   */
  getOrdersByCustomerPhone(phone: string): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/customer/phone/${encodeURIComponent(phone)}`);
  }
}