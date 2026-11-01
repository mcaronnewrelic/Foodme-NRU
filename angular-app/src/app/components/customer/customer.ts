import { Component, signal, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CustomerService } from '../../services/customer.service';
import { Customer } from '../../models/restaurant.model';
import { NewRelicService } from '../../services/newrelic.service';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrCalloutComponent } from '../nr-callout/nr-callout';
import { NrCheckComponent } from '../nr-check/nr-check';
import { EventTypesService } from '../../services/event-types.service';
import { MissionProgressService } from '../../services/mission-progress.service';

@Component({
  selector: 'app-customer',
  imports: [RouterModule, FormsModule, HeaderComponent, NrCalloutComponent, NrCheckComponent],
  templateUrl: './customer.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './customer.css'
})
export class CustomerComponent {
  readonly userNrql =
    "SELECT count(*) FROM PageView, AjaxRequest, PageAction, JavaScriptError WHERE demoCode = '<code>' FACET enduser.id, eventType() SINCE 1 day ago";

  customerForm = signal<Customer>({
    name: '',
    phone: '',
    address: ''
  });

  constructor(
    private customerService: CustomerService,
    private router: Router,
    private http: HttpClient,
    private newRelicService: NewRelicService,
    private progress: MissionProgressService,
    private eventTypes: EventTypesService
  ) {
    // Initialize with existing customer data if available
    const existingCustomer = this.customerService.customer();
    if (existingCustomer) {
      this.customerForm.set({
        name: existingCustomer.name || '',
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
      this.progress.markTried('mission-1');
      this.router.navigate(['/restaurants']);
    }
  }

  /**
   * Mission 1's answer key: how many of the four faceted event types this
   * visitor has produced so far, tracked by EventTypesService from the
   * app's own actions - the same count the Find query returns.
   */
  get eventTypeAnswer(): string {
    const count = this.eventTypes.count();
    return count <= 1 ? '1' : count === 2 ? '2' : '3 or more';
  }

  isFormValid(): boolean {
    const form = this.customerForm();
    return true;
  }
}
