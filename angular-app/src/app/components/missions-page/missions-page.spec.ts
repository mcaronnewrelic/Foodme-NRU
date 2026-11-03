import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { MissionsPageComponent } from './missions-page';
import { MissionProgressService } from '../../services/mission-progress.service';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { CartService } from '../../services/cart.service';
import { NrConfigService } from '../../nr-config';

describe('Missions dashboard links', () => {
  const code = signal('OU-TEST');

  beforeEach(async () => {
    code.set('OU-TEST');
    await TestBed.configureTestingModule({
      imports: [MissionsPageComponent],
      providers: [
        provideRouter([]),
        { provide: DemoIdentityService, useValue: { code } },
        {
          provide: MissionProgressService,
          useValue: {
            checkedCount: () => 5,
            firstTryCount: () => 5,
            isChecked: () => true,
            missionState: () => ({ tried: true, found: true }),
          },
        },
        {
          provide: CartService,
          useValue: { totalItems: () => 0, totalPrice: () => 0 },
        },
        {
          provide: NrConfigService,
          useValue: {
            showCallouts: () => false,
            armedScenario: () => null,
            armedInvestigation: () => null,
          },
        },
      ],
    }).compileComponents();
  });

  it('passes the current session code through both dashboard links', () => {
    const fixture = TestBed.createComponent(MissionsPageComponent);
    fixture.detectChanges();
    const links: HTMLAnchorElement[] = Array.from(
      fixture.nativeElement.querySelectorAll('a[href^="/api/dashboard"]'),
    );
    expect(links.length).toBe(2);
    for (const link of links) {
      expect(link.getAttribute('href')).toBe('/api/dashboard?demoCode=OU-TEST');
      expect(link.target).toBe('newrelic');
    }
    code.set('OU-NEW2');
    fixture.detectChanges();
    for (const link of links)
      expect(link.getAttribute('href')).toBe('/api/dashboard?demoCode=OU-NEW2');
  });
});
