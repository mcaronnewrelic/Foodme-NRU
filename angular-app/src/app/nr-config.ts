import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

const NR_BASE_URL = 'https://one.newrelic.com';

@Injectable({ providedIn: 'root' })
export class NrConfigService {
  // Stays null until the server answers, or if NEW_RELIC_ACCOUNT_ID isn't set
  readonly accountId = signal<string | null>(null);

  readonly browserEntityGuid = signal<string | null>(null);

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
