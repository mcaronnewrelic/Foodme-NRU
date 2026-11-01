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
    // The legacy Insights query URL is the pattern verified working on
    // browser.nru.to (2026-10-28): it redirects into one.newrelic.com with the
    // query pre-filled and scoped to this account. The NR1 launcher `pane=`
    // form was tested the same day and failed - the URL is rewritten to an
    // opaque state= form, the query does not pre-fill, and the UI can land in
    // the wrong account. Keep all query-link building in this one function so
    // a future pattern change stays a one-place change; the printed NRQL and
    // its Copy button are the permanent fallback if this surface is retired.
    return `https://insights.newrelic.com/accounts/${accountId}/query?query=${encodeURIComponent(nrql)}`;
  }
}
