import { Component, ElementRef, Input, OnInit, inject, viewChild, ChangeDetectionStrategy } from '@angular/core';
import { NrConfigService } from '../../nr-config';
import { DemoIdentityService } from '../../services/demo-identity.service';
import { MissionProgressService } from '../../services/mission-progress.service';

@Component({
  selector: 'app-nr-callout',
  templateUrl: './nr-callout.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './nr-callout.css'
})
export class NrCalloutComponent implements OnInit {
  protected config = inject(NrConfigService);
  private identity = inject(DemoIdentityService);
  private progress = inject(MissionProgressService);

  @Input({ required: true }) title!: string;
  @Input({ required: true }) nrql!: string;
  @Input() buttonLabel = 'Open in New Relic';
  @Input() showBrowserErrors = false;
  /** 'cohort' callouts show a "Shows everyone's data" chip (spec 5.3). */
  @Input() scope: 'personal' | 'cohort' = 'personal';
  /**
   * Extra placeholder values for the NRQL (spec 5.2): a token written as
   * <key> in the nrql input is replaced by tokens[key]. The visitor's
   * demoCode is always available as <code>; pass e.g. { requestId } for
   * <requestId> when the page knows it.
   */
  @Input() tokens: Record<string, string> = {};
  /** Mission framing (spec section 2): the mission this callout belongs to, if any. */
  @Input() missionId = '';
  /** The mission's Try line, rendered first in the callout body. */
  @Input() tryText = '';

  protected onFindClick(): void {
    if (this.missionId) this.progress.markFound(this.missionId);
  }

  protected showAccountNote = false;

  ngOnInit(): void {
    if (this.config.showCallouts()) {
      this.showAccountNote = this.config.claimAccountNote();
    }
  }

  /** The NRQL with every placeholder resolved - what is printed, copied and opened. */
  get resolvedNrql(): string {
    let query = this.nrql.replaceAll('<code>', this.identity.code());
    for (const [key, value] of Object.entries(this.tokens)) {
      query = query.replaceAll(`<${key}>`, value);
    }
    return query;
  }

  protected copyState: 'idle' | 'copied' | 'selected' = 'idle';
  private readonly nrqlText = viewChild<ElementRef<HTMLElement>>('nrqlText');

  get url(): string | null {
    return this.config.nrqlUrl(this.resolvedNrql);
  }

  // The printed NRQL is the permanent fallback if a query link ever breaks,
  // so it must be copyable even when no button is shown (spec section 5.1).
  // Layered because the Clipboard API alone is not enough: it only exists in
  // secure contexts, and the demo runs over plain HTTP, so on mobile Chrome
  // navigator.clipboard is simply undefined and the first version of this
  // button silently did nothing there.
  protected async copyNrql(): Promise<void> {
    if ((await this.tryClipboardApi(this.resolvedNrql)) || this.tryLegacyCopy(this.resolvedNrql)) {
      this.flashCopyState('copied');
    } else if (this.selectPrintedNrql()) {
      // Last resort: leave the text selected so the browser's own
      // long-press copy takes over.
      this.flashCopyState('selected');
    }
  }

  private async tryClipboardApi(text: string): Promise<boolean> {
    try {
      if (!navigator.clipboard?.writeText) return false;
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      return false;
    }
  }

  private tryLegacyCopy(text: string): boolean {
    const textarea = document.createElement('textarea');
    textarea.value = text;
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
