import { Component, Input, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { Customer } from '../../models/restaurant.model';

@Component({
  selector: 'app-customer-card',
  imports: [RouterModule],
  templateUrl: './customer-card.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './customer-card.css'
})
export class CustomerCardComponent {
  @Input() customer: Customer | null = null;
}
