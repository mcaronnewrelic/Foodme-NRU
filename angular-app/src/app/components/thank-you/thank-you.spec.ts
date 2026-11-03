import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { ThankYouComponent } from './thank-you';
import { CartService } from '../../services/cart.service';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { MissionProgressService } from '../../services/mission-progress.service';
import { NrConfigService } from '../../nr-config';
import { CartItem } from '../../models/restaurant.model';

describe('ThankYouComponent receipt and telemetry', () => {
  let fixture: ComponentFixture<ThankYouComponent>;
  let originalState: unknown;
  const showCallouts = signal(false);
  const markTried = jasmine.createSpy('markTried');
  const orderId = 'abc12345-1234-1234-1234-123456789abc';
  const item: CartItem = {
    restaurant: {
      id: 'a',
      name: 'Restaurant A',
      cuisine: 'Test',
      price: 1,
      rating: 5,
    },
    menuItem: {
      id: 'soup',
      name: 'Soup',
      description: '',
      price: 5.95,
      category: 'Main',
    },
    quantity: 3,
  };

  beforeEach(async () => {
    originalState = history.state;
    history.replaceState({ orderId, items: [item] }, '');
    showCallouts.set(false);
    markTried.calls.reset();
    await TestBed.configureTestingModule({
      imports: [ThankYouComponent],
      providers: [
        provideRouter([]),
        {
          provide: CartService,
          useValue: { totalItems: () => 0, totalPrice: () => 0 },
        },
        { provide: DemoIdentityService, useValue: { code: () => 'OU-TEST' } },
        {
          provide: MissionProgressService,
          useValue: {
            markTried,
            markFound() {},
            isSolved: () => false,
            progress: () => ({ attempts: 0, solved: false }),
          },
        },
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
  });

  afterEach(() => history.replaceState(originalState, ''));

  function render() {
    fixture = TestBed.createComponent(ThankYouComponent);
    fixture.detectChanges();
    return fixture.componentInstance;
  }

  it('shows the server-returned ID and receipt with exact cents', () => {
    const component = render();
    const text = fixture.nativeElement.textContent;
    expect(text).toContain(orderId);
    expect(text).toContain('Restaurant A');
    expect(text).toContain('Soup');
    expect(text).toContain('$17.85');
    expect(component.orderIdTail).toBe('9abc');
    expect(markTried).toHaveBeenCalledWith('mission-3');
  });

  it('joins item details to Transaction summaries by the string orderId', () => {
    const component = render();
    expect(component.joinedItemsNrql).toContain('FROM ItemsOrdered');
    expect(component.joinedItemsNrql).toContain('JOIN (FROM Transaction');
    expect(component.joinedItemsNrql).toContain('ON orderId');
    expect(component.joinedItemsNrql).toContain(
      "name = 'WebTransaction/Expressjs/POST//api/order'",
    );
    expect(component.joinedItemsNrql).toContain(`orderId = '${orderId}'`);
    expect(component.joinedItemsNrql).toContain('http.statusCode');
    expect(component.joinedItemsNrql).not.toContain('requestId');
    expect(component.metricsNrql).not.toContain(orderId);
    expect(component.metricsNrql).toContain(
      "metricTimesliceName = 'Custom/total'",
    );
  });

  it('keeps the receipt visible while explanations follow Behind the scenes', () => {
    render();
    expect(fixture.nativeElement.textContent).not.toContain('More lines');
    expect(fixture.nativeElement.textContent).not.toContain('JOIN the order');
    showCallouts.set(true);
    fixture.detectChanges();
    expect(fixture.nativeElement.textContent).toContain('JOIN the order');
    expect(fixture.nativeElement.textContent).toContain('Custom/total');
    showCallouts.set(false);
    fixture.detectChanges();
    expect(fixture.nativeElement.textContent).not.toContain('JOIN the order');
    expect(fixture.nativeElement.textContent).toContain(orderId);
  });

  it('does not claim success or mark a mission when opened without an order', () => {
    history.replaceState({}, '');
    render();
    expect(fixture.nativeElement.textContent).toContain('No Recent Order');
    expect(fixture.nativeElement.textContent).not.toContain(
      'successfully placed',
    );
    expect(markTried).not.toHaveBeenCalled();
  });
});
