import { Injectable, inject, signal } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import { EventTypesService } from './event-types.service';
import { NewRelicService } from './newrelic.service';
import {
  CODE_ALPHABET,
  DEMO_CODE_STORAGE_KEY,
  generateDemoCode,
  loadOrCreateDemoCode,
} from './demo-identity-bootstrap';

/**
 * The visitor's demoCode (spec: try-learn-find-spec.md section 1).
 *
 * Names collide in a workshop and several event types are easier to filter
 * by a short code, so every visitor gets an OU-XXXX code alongside their
 * enduser.id. It is stamped on everything the browser agent sends, and the
 * cart service includes it in orders so the server can stamp it on the
 * order transaction and the ItemsOrdered events too.
 *
 * Simulated visitors carry SIM-XXXX instead (the browser.nru.to
 * convention), so cohort queries can leave them out with
 * demoCode NOT LIKE 'SIM-%'. A code is pinned for a visit either by
 * pre-seeding localStorage before the app loads, or with a ?demoCode=
 * URL parameter - the same trick ?callouts= plays for the callouts.
 */
@Injectable({
  providedIn: 'root',
})
export class DemoIdentityService {
  private newRelicService = inject(NewRelicService);
  private eventTypes = inject(EventTypesService);
  private router = inject(Router);

  readonly code = signal(loadOrCreateDemoCode());

  constructor() {
    this.stamp();
    this.eventTypes.mark('PageView');
    // SPA route changes create new page views; re-stamp so every view and
    // everything under it carries the code.
    this.router.events
      .pipe(filter((event) => event instanceof NavigationEnd))
      .subscribe(() => {
        this.stamp();
        this.eventTypes.mark('PageView');
      });
  }

  private stamp(): void {
    this.newRelicService.setUserId(this.code());
    this.newRelicService.setCustomAttribute('demoCode', this.code(), true);
  }

  resetCode(): string {
    const prefix = this.code().startsWith('SIM-') ? 'SIM-' : 'OU-';
    let code = prefix + generateDemoCode().slice(3);
    if (code === this.code()) {
      const lastCharacter = code.slice(-1);
      const nextIndex =
        (CODE_ALPHABET.indexOf(lastCharacter) + 1) % CODE_ALPHABET.length;
      code = code.slice(0, -1) + CODE_ALPHABET[nextIndex];
    }
    this.code.set(code);
    try {
      localStorage.setItem(DEMO_CODE_STORAGE_KEY, code);
    } catch {}
    if (new URLSearchParams(location.search).has('demoCode')) {
      void this.router.navigate([], {
        queryParams: { demoCode: code },
        queryParamsHandling: 'merge',
        replaceUrl: true,
      });
    }
    this.stamp();
    return code;
  }
}
