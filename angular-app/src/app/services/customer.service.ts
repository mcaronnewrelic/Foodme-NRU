import { Injectable, inject, signal } from '@angular/core';
import { Customer } from '../models/restaurant.model';
import { DemoIdentityService } from './demo-identity.service';

const SAMPLE_STREETS = [
  'SE Morrison St', 'NW Flanders St', 'SW Alder St', 'NE Alberta St',
  'SE Division St', 'NW Thurman St', 'SW Salmon St', 'NE Fremont St'
];

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private demoIdentity = inject(DemoIdentityService);
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
        const stored = localStorage.getItem('orderup-customer');
        if (stored) {
          const parsed = JSON.parse(stored);
          // Email is no longer collected (it was a PII risk in a shared
          // demo); drop it from anything stored by an older version.
          delete parsed.email;
          if (parsed.name || parsed.phone || parsed.address) return parsed;
        }
      } catch {
        // fall through to a generated sample customer
      }
    }
    return this.generateSampleCustomer();
  }

  /**
   * A made-up customer for this visit, so nobody has to type real personal
   * details into a shared demo: the name is the visitor's demoCode, the
   * phone is in the reserved 555-01xx fictional range, and the address is
   * generated. Visitors can edit the details, and the sample persists like
   * any other customer data.
   */
  private generateSampleCustomer(): Customer {
    const street = SAMPLE_STREETS[Math.floor(Math.random() * SAMPLE_STREETS.length)];
    const number = 100 + Math.floor(Math.random() * 3800);
    const zip = `972${String(Math.floor(Math.random() * 100)).padStart(2, '0')}`;
    const phoneSuffix = String(Math.floor(Math.random() * 100)).padStart(2, '0');
    return {
      name: this.demoIdentity.code(),
      phone: `(503) 555-01${phoneSuffix}`,
      address: `${number} ${street}, Portland, OR ${zip}`
    };
  }

  private saveToStorage(customer: Customer) {
    if (typeof localStorage !== 'undefined') {
      try {
        localStorage.setItem('orderup-customer', JSON.stringify(customer));
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
      localStorage.removeItem('orderup-customer');
    }
  }
}
