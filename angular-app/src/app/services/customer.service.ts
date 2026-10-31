import { Injectable, signal } from '@angular/core';
import { Customer } from '../models/restaurant.model';

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private customerSignal = signal<Customer>(this.loadFromStorage());

  get customer() {
    return this.customerSignal.asReadonly();
  }

  get address() {
    return this.customerSignal().address;
  }

  private loadFromStorage(): Customer {
    if (typeof localStorage !== 'undefined') {
      try {
        const stored = localStorage.getItem('foodme-customer');
        return stored ? JSON.parse(stored) : {};
      } catch {
        return {};
      }
    }
    return {};
  }

  private saveToStorage(customer: Customer) {
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem('foodme-customer', JSON.stringify(customer));
      } catch {
        // Silently fail if localStorage is not available
      }
    }
  }

  updateCustomer(customer: Partial<Customer>) {
    this.customerSignal.update(current => {
      const updated = { ...current, ...customer };
      this.saveToStorage(updated);
      return updated;
    });
  }

  setAddress(address: string) {
    this.customerSignal.update(current => {
      const updated = { ...current, address };
      this.saveToStorage(updated);
      return updated;
    });
  }

  clearCustomer() {
    this.customerSignal.set({});
    if (typeof localStorage !== 'undefined') {
      localStorage.removeItem('foodme-customer');
    }
  }
}
