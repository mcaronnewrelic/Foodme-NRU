import { Component, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { CartService } from '../../services/cart.service';
import { NrConfigService } from '../../nr-config';
import { DemoIdentityService } from '../../services/demo-identity.service';

@Component({
  selector: 'app-header',
  imports: [RouterModule],
  templateUrl: './header.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './header.css'
})
export class HeaderComponent {
  protected readonly NrConfigService = NrConfigService;
  showCartDropdown = false;
  showHelpDropdown = false;
  showMobileMenu = false;

  constructor(
    public cartService: CartService,
    public nrConfig: NrConfigService,
    public demoIdentity: DemoIdentityService
  ) {}

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
