import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { CartService } from '../../services/cart.service';

@Component({
  selector: 'app-header',
  imports: [CommonModule, RouterModule],
  templateUrl: './header.html',
  styleUrl: './header.css'
})
export class HeaderComponent {
  showCartDropdown = false;
  showHelpDropdown = false;
  showMobileMenu = false;

  constructor(public cartService: CartService) {}

  get cartItemCount() {
    return this.cartService.totalItems();
  }

  get cartTotal() {
    return this.cartService.totalPrice();
  }

  toggleCartDropdown() {
    this.showCartDropdown = !this.showCartDropdown;
    this.showHelpDropdown = false; // Close other dropdowns
  }

  closeCartDropdown() {
    this.showCartDropdown = false;
  }

  toggleHelpDropdown() {
    this.showHelpDropdown = !this.showHelpDropdown;
    this.showCartDropdown = false; // Close other dropdowns
  }

  closeHelpDropdown() {
    this.showHelpDropdown = false;
  }

  toggleMobileMenu() {
    this.showMobileMenu = !this.showMobileMenu;
  }

  closeMobileMenu() {
    this.showMobileMenu = false;
  }
}
