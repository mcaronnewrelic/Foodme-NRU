import { Injectable, inject, signal } from '@angular/core';
import { NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs';
import { NewRelicService } from './newrelic.service';

const DEMO_CODE_STORAGE_KEY = 'foodme-demo-code';
// Unambiguous alphabet: no 0/O, 1/I/L to confuse when read aloud or copied.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const CODE_PATTERN = /^FM-[A-Z0-9]{4}$/;

/**
 * The visitor's demoCode (spec: try-learn-find-spec.md section 1).
 *
 * Names collide in a workshop and several event types are easier to filter
 * by a short code, so every visitor gets an FM-XXXX code alongside their
 * enduser.id. It is stamped on everything the browser agent sends, and the
 * cart service includes it in orders so the server can stamp it on the
 * order transaction and the Order event too.
 */
@Injectable({
  providedIn: 'root'
})
export class DemoIdentityService {
  private newRelicService = inject(NewRelicService);
  private router = inject(Router);

  readonly code = signal(this.loadOrCreateCode());

  constructor() {
    this.stamp();
    // SPA route changes create new page views; re-stamp so every view and
    // everything under it carries the code.
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => this.stamp());
  }

  private stamp(): void {
    this.newRelicService.setCustomAttribute('demoCode', this.code());
  }

  private loadOrCreateCode(): string {
    try {
      const stored = localStorage.getItem(DEMO_CODE_STORAGE_KEY);
      if (stored && CODE_PATTERN.test(stored)) return stored;
      const created = this.generateCode();
      localStorage.setItem(DEMO_CODE_STORAGE_KEY, created);
      return created;
    } catch {
      // Storage unavailable (private mode etc.): a per-load code still
      // ties this visit's data together.
      return this.generateCode();
    }
  }

  private generateCode(): string {
    let suffix = '';
    for (let i = 0; i < 4; i++) {
      suffix += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
    }
    return `FM-${suffix}`;
  }
}
