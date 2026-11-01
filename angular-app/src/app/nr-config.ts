import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const NR_BASE_URL = 'https://one.newrelic.com';
const CALLOUTS_STORAGE_KEY = 'foodme-nr-callouts';
const CALLOUTS_SHOWN_BY_DEFAULT = false;

@Injectable({ providedIn: 'root' })
export class NrConfigService {
  // Stays null until the server answers, or if NEW_RELIC_ACCOUNT_ID isn't set
  readonly accountId = signal<string | null>(null);

  readonly browserEntityGuid = signal<string | null>(null);
  readonly showCallouts = signal(this.loadShowCallouts());

  constructor(http: HttpClient) {
    http.get<{ accountId: string | null; browserEntityGuid: string | null }>('/api/nr-config')
      .subscribe({
        next: config => {
          this.accountId.set(config.accountId);
          this.browserEntityGuid.set(config.browserEntityGuid);
        },
        error: () => {}
      });
  }

  toggleCallouts(): void {
    this.showCallouts.update(shown => !shown);
    localStorage.setItem(CALLOUTS_STORAGE_KEY, String(this.showCallouts()));
  }

  private loadShowCallouts(): boolean {
    // Instructor override (spec section 7): ?callouts=1 on a handout or QR
    // link shows the callouts for this visit without changing the visitor's
    // stored preference; ?callouts=0 forces them off the same way.
    if (typeof location !== 'undefined') {
      const param = new URLSearchParams(location.search).get('callouts');
      if (param === '1' || param === 'true') return true;
      if (param === '0' || param === 'false') return false;
    }
    const stored = typeof localStorage === 'undefined' ? null : localStorage.getItem(CALLOUTS_STORAGE_KEY);
    return stored === null ? CALLOUTS_SHOWN_BY_DEFAULT : stored === 'true';
  }

  browserErrorsUrl(): string | null {
    const guid = this.browserEntityGuid();
    return guid ? `${NR_BASE_URL}/nr1-core/errors-inbox/entity-inbox/${guid}` : null;
  }

  nrqlUrl(nrql: string): string | null {
    const accountId = Number(this.accountId());
    if (!accountId) return null;
    const pane = {
      nerdletId: 'data-exploration.query-builder',
      initialActiveInterface: 'nrqlEditor',
      initialQueries: [{ accountId, nrql }],
      initialAccountId: accountId
    };
    return `${NR_BASE_URL}/launcher/data-exploration.query-builder?pane=${btoa(JSON.stringify(pane))}`;
  }
}
