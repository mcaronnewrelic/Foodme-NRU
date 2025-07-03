import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Customer } from '../../models/restaurant.model';

@Component({
  selector: 'app-customer-card',
  imports: [CommonModule, RouterModule],
  templateUrl: './customer-card.html',
  styleUrl: './customer-card.css'
})
export class CustomerCardComponent {
  @Input() customer: Customer | null = null;
}
