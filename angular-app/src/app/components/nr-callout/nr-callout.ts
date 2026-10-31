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

  get url(): string | null {
    return this.config.nrqlUrl(this.nrql);
  }

  get browserErrorsUrl(): string | null {
    return this.showBrowserErrors ? this.config.browserErrorsUrl() : null;
  }
}
