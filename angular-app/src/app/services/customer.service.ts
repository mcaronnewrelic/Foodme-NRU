import { Injectable, signal } from '@angular/core';
import { Customer } from '../models/restaurant.model';

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private customerSignal = signal<Customer>({});

  get customer() {
    return this.customerSignal.asReadonly();
  }

  get address() {
    return this.customerSignal().address;
  }

  updateCustomer(customer: Partial<Customer>) {
    this.customerSignal.update(current => ({ ...current, ...customer }));
  }

  setAddress(address: string) {
    this.customerSignal.update(current => ({ ...current, address }));
  }

  clearCustomer() {
    this.customerSignal.set({});
  }
}
