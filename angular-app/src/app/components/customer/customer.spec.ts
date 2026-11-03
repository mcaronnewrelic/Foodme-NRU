import { signal } from '@angular/core';
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
  let originalMissions: string | null;
  let originalEventTypes: string | null;
  let originalUrl: string;
  const showCallouts = signal(false);
  const telemetry = jasmine.createSpyObj('NewRelicService', [
    'setCustomAttribute',
    'setUserId',
    'recordCustomEvent',
  ]);
  const initialCustomer = {
    name: 'OU-AAAA',
    phone: '(503) 555-0100',
    address: '100 SE Morrison St, Portland, OR 97200',
  };

  beforeEach(async () => {
    originalCode = localStorage.getItem('orderup-demo-code');
    originalCustomer = localStorage.getItem('orderup-customer');
    originalMissions = localStorage.getItem('orderup-missions');
    originalEventTypes = localStorage.getItem('orderup-event-types');
    originalUrl = location.href;
    history.replaceState(history.state, '', location.pathname);
    localStorage.setItem('orderup-demo-code', initialCustomer.name);
    localStorage.setItem('orderup-customer', JSON.stringify(initialCustomer));
    localStorage.removeItem('orderup-missions');
    localStorage.removeItem('orderup-event-types');
    telemetry.setCustomAttribute.calls.reset();
    telemetry.setUserId.calls.reset();
    showCallouts.set(false);
    await TestBed.configureTestingModule({
      imports: [CustomerComponent],
      providers: [
        provideHttpClient(),
        provideRouter([]),
        { provide: NewRelicService, useValue: telemetry },
        {
          provide: NrConfigService,
          useValue: {
            showCallouts,
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
    if (originalMissions === null) localStorage.removeItem('orderup-missions');
    else localStorage.setItem('orderup-missions', originalMissions);
    if (originalEventTypes === null)
      localStorage.removeItem('orderup-event-types');
    else localStorage.setItem('orderup-event-types', originalEventTypes);
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

  it('clears mission attempts, completion, tried/found flags, and event-type evidence for the new customer', () => {
    const component = render();
    const progress = TestBed.inject(MissionProgressService);
    const eventTypes = TestBed.inject(EventTypesService);
    progress.markTried('mission-1');
    progress.markFound('mission-1');
    progress.recordAttempt('mission-1', 'event-type-count', true);
    progress.recordAttempt('mission-2', 'filter-no-request', false);
    eventTypes.mark('JavaScriptError');
    eventTypes.mark('PageAction');
    expect(progress.checkedCount()).toBe(1);
    component.resetCustomer();
    expect(progress.checkedCount()).toBe(0);
    expect(progress.firstTryCount()).toBe(0);
    expect(progress.solvedCount()).toBe(0);
    expect(progress.missionState('mission-1')).toEqual({
      tried: false,
      found: false,
    });
    expect(progress.progress('mission-1', 'event-type-count')).toEqual({
      attempts: 0,
      solved: false,
    });
    expect(progress.progress('mission-2', 'filter-no-request')).toEqual({
      attempts: 0,
      solved: false,
    });
    expect(eventTypes.count()).toBe(0);
    expect(JSON.parse(localStorage.getItem('orderup-missions')!)).toEqual({
      questions: {},
      missions: {},
    });
    expect(JSON.parse(localStorage.getItem('orderup-event-types')!)).toEqual(
      [],
    );
    const reloadedProgress = new MissionProgressService();
    expect(reloadedProgress.checkedCount()).toBe(0);
    expect(new EventTypesService().count()).toBe(0);
  });

  it('resets the loaded mission state even after storage has already been deleted', () => {
    const component = render();
    const progress = TestBed.inject(MissionProgressService);
    progress.recordAttempt('mission-1', 'event-type-count', true);
    localStorage.removeItem('orderup-missions');
    expect(progress.checkedCount()).toBe(1);
    component.resetCustomer();
    expect(progress.checkedCount()).toBe(0);
    progress.markTried('mission-1');
    expect(
      JSON.parse(localStorage.getItem('orderup-missions')!).questions,
    ).toEqual({});
  });

  it('clears the visible answer selection and feedback for the new customer', () => {
    showCallouts.set(true);
    const component = render();
    const option: HTMLInputElement = fixture.nativeElement.querySelector(
      'input[value="3 or more"]',
    );
    option.click();
    fixture.detectChanges();
    fixture.nativeElement.querySelector('.nr-check-btn').click();
    fixture.detectChanges();
    expect(fixture.nativeElement.textContent).toContain(
      'Not what the data says',
    );
    component.resetCustomer();
    fixture.detectChanges();
    expect(fixture.nativeElement.textContent).not.toContain(
      'Not what the data says',
    );
    expect(
      fixture.nativeElement.querySelector('input[type="radio"]:checked'),
    ).toBeNull();
    expect(
      fixture.nativeElement.querySelector('.nr-check-btn').disabled,
    ).toBeTrue();
  });
});
