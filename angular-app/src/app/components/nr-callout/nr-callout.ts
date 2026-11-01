import { Component, ElementRef, Input, inject, viewChild, ChangeDetectionStrategy } from '@angular/core';
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

  protected copyState: 'idle' | 'copied' | 'selected' = 'idle';
  private readonly nrqlText = viewChild<ElementRef<HTMLElement>>('nrqlText');

  get url(): string | null {
    return this.config.nrqlUrl(this.nrql);
  }

  // The printed NRQL is the permanent fallback if a query link ever breaks,
  // so it must be copyable even when no button is shown (spec section 5.1).
  // Layered because the Clipboard API alone is not enough: it only exists in
  // secure contexts, and the demo runs over plain HTTP, so on mobile Chrome
  // navigator.clipboard is simply undefined and the first version of this
  // button silently did nothing there.
  protected async copyNrql(): Promise<void> {
    if ((await this.tryClipboardApi()) || this.tryLegacyCopy()) {
      this.flashCopyState('copied');
    } else if (this.selectPrintedNrql()) {
      // Last resort: leave the text selected so the browser's own
      // long-press copy takes over.
      this.flashCopyState('selected');
    }
  }

  private async tryClipboardApi(): Promise<boolean> {
    try {
      if (!navigator.clipboard?.writeText) return false;
      await navigator.clipboard.writeText(this.nrql);
      return true;
    } catch {
      return false;
    }
  }

  private tryLegacyCopy(): boolean {
    const textarea = document.createElement('textarea');
    textarea.value = this.nrql;
    textarea.readOnly = true;
    // On-screen but invisible: mobile browsers refuse to copy from
    // display:none or far-off-screen elements, and a font under 16px makes
    // iOS zoom the page when the field is focused.
    textarea.style.cssText =
      'position:fixed;top:0;left:0;width:2em;height:2em;opacity:0.01;font-size:16px;';
    document.body.appendChild(textarea);
    try {
      textarea.focus();
      textarea.select();
      textarea.setSelectionRange(0, textarea.value.length); // iOS needs the explicit range
      return document.execCommand('copy');
    } catch {
      return false;
    } finally {
      textarea.remove();
    }
  }

  private selectPrintedNrql(): boolean {
    const el = this.nrqlText()?.nativeElement;
    if (!el) return false;
    try {
      const range = document.createRange();
      range.selectNodeContents(el);
      const selection = window.getSelection();
      if (!selection) return false;
      selection.removeAllRanges();
      selection.addRange(range);
      return selection.rangeCount > 0;
    } catch {
      return false;
    }
  }

  private flashCopyState(state: 'copied' | 'selected'): void {
    this.copyState = state;
    setTimeout(() => (this.copyState = 'idle'), state === 'copied' ? 2000 : 4000);
  }

  get browserErrorsUrl(): string | null {
    return this.showBrowserErrors ? this.config.browserErrorsUrl() : null;
  }
}
