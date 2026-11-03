import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter, Router } from '@angular/router';
import { CustomerComponent } from './customer';
import { CustomerService } from '../../services/customer.service';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { NewRelicService } from '../../services/newrelic.service';
import { NrConfigService } from '../../nr-config';
import { EventTypesService } from '../../services/event-types.service';
import { MissionProgressService } from '../../services/mission-progress.service';

describe('CustomerComponent demo identity reset', () => {
  let fixture: ComponentFixture<CustomerComponent>;
  let originalCode: string | null;
  let originalCustomer: string | null;
  let originalUrl: string;
  const telemetry = jasmine.createSpyObj('NewRelicService', [
    'setCustomAttribute',
    'setUserId',
  ]);
  const initialCustomer = {
    name: 'OU-AAAA',
    phone: '(503) 555-0100',
    address: '100 SE Morrison St, Portland, OR 97200',
  };

  beforeEach(async () => {
    originalCode = localStorage.getItem('orderup-demo-code');
    originalCustomer = localStorage.getItem('orderup-customer');
    originalUrl = location.href;
    history.replaceState(history.state, '', location.pathname);
    localStorage.setItem('orderup-demo-code', initialCustomer.name);
    localStorage.setItem('orderup-customer', JSON.stringify(initialCustomer));
    telemetry.setCustomAttribute.calls.reset();
    telemetry.setUserId.calls.reset();
    await TestBed.configureTestingModule({
      imports: [CustomerComponent],
      providers: [
        provideHttpClient(),
        provideRouter([]),
        { provide: NewRelicService, useValue: telemetry },
        { provide: EventTypesService, useValue: { mark() {}, count: () => 2 } },
        {
          provide: MissionProgressService,
          useValue: { markTried() {}, markFound() {} },
        },
        {
          provide: NrConfigService,
          useValue: {
            showCallouts: () => false,
            armedScenario: () => null,
            armedInvestigation: () => null,
            claimAccountNote: () => false,
            nrqlUrl: () => null,
            browserErrorsUrl: () => null,
          },
        },
      ],
    }).compileComponents();
    spyOn(TestBed.inject(Router), 'navigate').and.resolveTo(true);
  });

  afterEach(() => {
    if (originalCode === null) localStorage.removeItem('orderup-demo-code');
    else localStorage.setItem('orderup-demo-code', originalCode);
    if (originalCustomer === null) localStorage.removeItem('orderup-customer');
    else localStorage.setItem('orderup-customer', originalCustomer);
    history.replaceState(history.state, '', originalUrl);
  });

  function render() {
    fixture = TestBed.createComponent(CustomerComponent);
    fixture.detectChanges();
    return fixture.componentInstance;
  }

  it('resets all fields, persists them, and immediately tags the new identity without submitting', () => {
    render();
    const button: HTMLButtonElement = fixture.nativeElement.querySelector(
      'button.btn-outline-secondary',
    );
    button.click();
    fixture.detectChanges();
    const customer = fixture.componentInstance.customerForm();
    const identity = TestBed.inject(DemoIdentityService);
    expect(customer.name).toBe(identity.code());
    expect(customer.name).not.toBe(initialCustomer.name);
    expect(customer.phone).not.toBe(initialCustomer.phone);
    expect(customer.address).not.toBe(initialCustomer.address);
    expect(customer.phone).toMatch(/^\(503\) 555-01\d{2}$/);
    expect(localStorage.getItem('orderup-demo-code')).toBe(customer.name!);
    expect(JSON.parse(localStorage.getItem('orderup-customer')!)).toEqual(
      customer,
    );
    expect(telemetry.setCustomAttribute).toHaveBeenCalledWith(
      'demoCode',
      customer.name,
    );
    expect(telemetry.setUserId).toHaveBeenCalledWith(customer.name);
    expect(TestBed.inject(Router).navigate).not.toHaveBeenCalled();
    expect(fixture.nativeElement.querySelector('#name').value).toBe(
      customer.name,
    );
    const reloaded = TestBed.runInInjectionContext(() => new CustomerService());
    expect(reloaded.customer()).toEqual(customer);
  });

  it('still creates distinct values when the random generator repeats the previous ones', () => {
    const component = render();
    spyOn(Math, 'random').and.returnValue(0);
    component.resetCustomer();
    expect(component.customerForm()).toEqual({
      name: 'OU-AAAB',
      phone: '(503) 555-0101',
      address: '101 SE Morrison St, Portland, OR 97200',
    });
  });

  it('preserves a simulated visitor prefix and replaces a URL-pinned code', () => {
    history.replaceState(
      history.state,
      '',
      `${location.pathname}?demoCode=SIM-AAAA&callouts=on`,
    );
    const component = render();
    component.resetCustomer();
    const code = TestBed.inject(DemoIdentityService).code();
    expect(code).toMatch(/^SIM-[A-Z0-9]{4}$/);
    expect(code).not.toBe('SIM-AAAA');
    expect(component.customerForm().name).toBe(code);
    expect(TestBed.inject(Router).navigate).toHaveBeenCalledWith([], {
      queryParams: { demoCode: code },
      queryParamsHandling: 'merge',
      replaceUrl: true,
    });
  });

  it('keeps resetting in memory when storage is unavailable', () => {
    const component = render();
    spyOn(Storage.prototype, 'setItem').and.throwError('Storage unavailable');
    expect(() => component.resetCustomer()).not.toThrow();
    expect(component.customerForm().name).toBe(
      TestBed.inject(DemoIdentityService).code(),
    );
    expect(component.customerForm().name).not.toBe(initialCustomer.name);
  });
});
