import { Component, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { CartService } from '../../services/cart.service';
import { CustomerService } from '../../services/customer.service';
import { Customer } from '../../models/restaurant.model';
import { HeaderComponent } from '../header/header';

interface PaymentInfo {
  type: string;
  number: string;
  expire: string;
  cvc: string;
  name: string;
}

@Component({
  selector: 'app-checkout',
  imports: [CommonModule, RouterModule, FormsModule, HeaderComponent],
  templateUrl: './checkout.html',
  styleUrl: './checkout.css'
})
export class CheckoutComponent implements OnInit {
  submitting = signal(false);
  
  // Use customer data from the customer service
  get customer() {
    return this.customerService.customer();
  }

  payment: PaymentInfo = {
    type: 'visa',
    number: '4111111111111111',
    expire: '12/2025',
    cvc: '123',
    name: 'John Doe'
  };

  cardTypes = [
    { value: 'visa', label: 'Visa' },
    { value: 'mc', label: 'MasterCard' },
    { value: 'amex', label: 'American Express' },
    { value: 'discover', label: 'Discover' }
  ];

  constructor(
    public cartService: CartService,
    private customerService: CustomerService,
    private router: Router
  ) {
    // Update payment name when customer data changes
    const customerData = this.customerService.customer();
    if (customerData?.name) {
      this.payment.name = customerData.name;
    }
  }

  ngOnInit() {
     // Check if customer has completed their information
    if (!this.customerService.address) {
      this.router.navigate(['/customer']);
      return;
    }  }

  updateQuantity(menuItemId: string, quantity: number) {
    this.cartService.updateQuantity(menuItemId, quantity);
  }

  onQuantityChange(menuItemId: string, event: Event) {
    const target = event.target as HTMLInputElement;
    const quantity = parseInt(target.value, 10);
    if (quantity > 0) {
      this.updateQuantity(menuItemId, quantity);
    }
  }

  updateCustomerField(field: keyof Customer, value: string) {
    this.customerService.updateCustomer({ [field]: value });
    
    // Update payment name when customer name changes
    if (field === 'name') {
      this.payment.name = value;
    }
  }

  onCustomerNameChange(event: Event) {
    const target = event.target as HTMLInputElement;
    this.updateCustomerField('name', target.value);
  }

  onCustomerEmailChange(event: Event) {
    const target = event.target as HTMLInputElement;
    this.updateCustomerField('email', target.value);
  }

  onCustomerPhoneChange(event: Event) {
    const target = event.target as HTMLInputElement;
    this.updateCustomerField('phone', target.value);
  }

  onCustomerAddressChange(event: Event) {
    const target = event.target as HTMLTextAreaElement;
    this.updateCustomerField('address', target.value);
  }

  removeItem(menuItemId: string) {
    this.cartService.removeFromCart(menuItemId);
  }

  clearCart() {
    this.cartService.clearCart();
  }

  goBackToMenu() {
    // Get the first item's restaurant to navigate back
    const firstItem = this.cartService.cartItems()[0];
    if (firstItem) {
      this.router.navigate(['/menu', firstItem.restaurant.id]);
    } else {
      this.router.navigate(['/restaurants']);
    }
  }

  async purchase() {
    if (this.submitting() || this.cartService.totalItems() === 0) {
      return;
    }

    this.submitting.set(true);

    try {
      // Submit the order to the API
      const customerData = this.customer;
      const orderResponse = await firstValueFrom(this.cartService.submitOrder(customerData));
      
      console.log('Order submitted successfully:', orderResponse);
      
      // Clear the cart after successful purchase
      this.cartService.clearCart();
      
      // Navigate to thank you page
      this.router.navigate(['/thank-you']);
    } catch (error) {
      console.error('Purchase failed:', error);
      alert('Purchase failed. Please try again.');
    } finally {
      this.submitting.set(false);
    }
  }

  isFormValid(): boolean {
    const customerData = this.customer || {};
    
    // Log the validation state for debugging
    console.log('Form validation check:', {
      paymentType: this.payment.type.length > 0,
      paymentNumber: this.payment.number.length >= 15, // Allow 15-16 digits
      paymentExpire: this.payment.expire.match(/\d{2}\/\d{4}/) !== null,
      paymentCvc: this.payment.cvc.length >= 3,
      paymentName: this.payment.name.length > 0,
      customerName: (customerData.name?.length || 0) > 0,
      customerEmail: (customerData.email?.length || 0) > 0,
      customerPhone: (customerData.phone?.length || 0) > 0,
      customerAddress: (customerData.address?.length || 0) > 0,
      cartItems: this.cartService.totalItems() > 0,
      customerData: customerData,
      payment: this.payment
    });
    
    return this.payment.type.length > 0 &&
           this.payment.number.length >= 15 && // Allow 15-16 digits for different card types
           this.payment.expire.match(/\d{2}\/\d{4}/) !== null &&
           this.payment.cvc.length >= 3 &&
           this.payment.name.length > 0 &&
           (customerData.name?.length || 0) > 0 &&
           (customerData.email?.length || 0) > 0 &&
           (customerData.phone?.length || 0) > 0 &&
           (customerData.address?.length || 0) > 0 &&
           this.cartService.totalItems() > 0;
  }
}
