import { Component, Input, inject, ChangeDetectionStrategy } from '@angular/core';
import { NrConfigService } from '../../nr-config';

@Component({
  selector: 'app-nr-callout',
  templateUrl: './nr-callout.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './nr-callout.css'
})
export class NrCalloutComponent {
  protected config = inject(NrConfigService);

  @Input({ required: true }) title!: string;
  @Input({ required: true }) nrql!: string;
  @Input() buttonLabel = 'Open in New Relic';
  @Input() showBrowserErrors = false;

  protected copied = false;

  get url(): string | null {
    return this.config.nrqlUrl(this.nrql);
  }

  // The printed NRQL is the permanent fallback if a query link ever breaks,
  // so it must be copyable even when no button is shown (spec section 5.1).
  protected async copyNrql(): Promise<void> {
    try {
      await navigator.clipboard.writeText(this.nrql);
      this.copied = true;
      setTimeout(() => (this.copied = false), 2000);
    } catch {
      // Clipboard unavailable (permissions / insecure context): the NRQL
      // stays on screen to copy by hand.
    }
  }

  get browserErrorsUrl(): string | null {
    return this.showBrowserErrors ? this.config.browserErrorsUrl() : null;
  }
}
