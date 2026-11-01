import { Component, ChangeDetectionStrategy } from '@angular/core';
import { RouterOutlet } from '@angular/router';

import { CartService } from './services/cart.service';
import { DemoIdentityService } from './services/demo-identity.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './app.css'
})
export class App {
  protected title = 'FoodMe - Angular v20';

  constructor(
    public cartService: CartService,
    // Injected for its side effects: creates/loads the visitor's demoCode
    // and keeps it stamped on the browser agent's data (spec section 1).
    demoIdentity: DemoIdentityService
  ) {}
}
