import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CustomerService } from '../../services/customer.service';
import { Customer } from '../../models/restaurant.model';
import { NewRelicService } from '../../services/newrelic.service';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';

@Component({
  selector: 'app-customer',
  imports: [CommonModule, RouterModule, FormsModule, HeaderComponent],
  templateUrl: './customer.html',
  styleUrl: './customer.css'
})
export class CustomerComponent {
  customerForm = signal<Customer>({
    name: '',
    email: '',
    phone: '',
    address: ''
  });

  constructor(
    private customerService: CustomerService,
    private router: Router,
    private http: HttpClient,
    private newRelicService: NewRelicService
  ) {
    // Initialize with existing customer data if available
    const existingCustomer = this.customerService.customer();
    if (existingCustomer) {
      this.customerForm.set({
        name: existingCustomer.name || '',
        email: existingCustomer.email || '',
        phone: existingCustomer.phone || '',
        address: existingCustomer.address || ''
      });
    }
  }

  updateForm(field: keyof Customer, value: string) {
    this.customerForm.update(current => ({
      ...current,
      [field]: value
    }));
  }

  onSubmit() {
    const form = this.customerForm();
    if (form.address?.trim()) {
      this.customerService.updateCustomer(form);
      this.newRelicService.setUserId(form.name ? form.name : 'guest');
      this.router.navigate(['/restaurants']);
    }
  }

  isFormValid(): boolean {
    const form = this.customerForm();
    return true;
  }
}
