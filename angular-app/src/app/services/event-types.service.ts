import { HttpInterceptorFn } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';

const STORAGE_KEY = 'orderup-event-types';

/** The browser event types Mission 1's Find query facets on (spec section 2). */
export const TRACKED_EVENT_TYPES = ['PageView', 'AjaxRequest', 'PageAction', 'JavaScriptError'] as const;
export type TrackedEventType = (typeof TRACKED_EVENT_TYPES)[number];

/**
 * Which of the tracked event types this visitor has produced so far.
 *
 * Mission 1's evidence check asks "how many event types carry your code?"
 * and the honest answer lives in New Relic - but the app also knows its
 * own actions exactly: every route is a PageView, every HttpClient call
 * is an AjaxRequest, every addPageAction is a PageAction and every
 * noticeError is a JavaScriptError. The hooks in NewRelicService, the
 * HTTP interceptor below and the identity service's route subscription
 * record them here, so the check can be judged against the same count
 * the Find query returns (persisted, so the count survives navigation).
 */
@Injectable({ providedIn: 'root' })
export class EventTypesService {
  readonly types = signal<ReadonlySet<string>>(new Set(this.load()));

  mark(type: TrackedEventType): void {
    if (this.types().has(type)) return;
    this.types.update(set => new Set(set).add(type));
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify([...this.types()]));
    } catch { /* storage unavailable: the count lasts for this page load only */ }
  }

  /** How many of the tracked types have fired - the Mission 1 answer. */
  count(): number {
    return TRACKED_EVENT_TYPES.filter(t => this.types().has(t)).length;
  }

  private load(): string[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) return parsed.filter(x => typeof x === 'string');
      }
    } catch { /* fall through to a fresh set */ }
    return [];
  }
}

/** Every HttpClient request the app makes is one of its AjaxRequests. */
export const ajaxEventTypeInterceptor: HttpInterceptorFn = (req, next) => {
  inject(EventTypesService).mark('AjaxRequest');
  return next(req);
};
