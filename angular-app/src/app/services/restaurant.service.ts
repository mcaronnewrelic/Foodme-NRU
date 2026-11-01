import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Restaurant } from '../models/restaurant.model';
import { nameToSlug } from '../utils/url.utils';

@Injectable({
  providedIn: 'root'
})
export class RestaurantService {
  private apiUrl = '/api/restaurant';
  
  constructor(private http: HttpClient) {}

  getRestaurants(): Observable<Restaurant[]> {
    return this.http.get<Restaurant[]>(this.apiUrl);
  }

  getRestaurant(id: string): Observable<Restaurant> {
    return this.http.get<Restaurant>(`${this.apiUrl}/${id}`);
  }

  getRestaurantByName(nameSlug: string): Observable<Restaurant> {
    return this.http.get<Restaurant>(`${this.apiUrl}/by-name/${nameSlug}`);
  }

  // Helper method to convert restaurant name to URL slug
  getRestaurantSlug(restaurant: Restaurant): string {
    return nameToSlug(restaurant.name);
  }
}
