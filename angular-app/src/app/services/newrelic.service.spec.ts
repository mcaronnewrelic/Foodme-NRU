import { TestBed } from '@angular/core/testing';
import { NewRelicService } from './newrelic.service';
import { EventTypesService } from './event-types.service';
import {
  initializeBrowserIdentity,
  loadOrCreateDemoCode,
} from './demo-identity-bootstrap';

describe('NewRelicService identity attributes', () => {
  let originalAgent: typeof window.newrelic;
  let service: NewRelicService;
  let originalCode: string | null;
  let originalUrl: string;

  beforeEach(() => {
    originalAgent = window.newrelic;
    originalCode = localStorage.getItem('orderup-demo-code');
    originalUrl = location.href;
    history.replaceState(history.state, '', location.pathname);
    localStorage.setItem('orderup-demo-code', 'OU-TEST');
    TestBed.configureTestingModule({
      providers: [{ provide: EventTypesService, useValue: { mark() {} } }],
    });
    service = TestBed.inject(NewRelicService);
    window.newrelic = jasmine.createSpyObj('browserAgent', [
      'setCustomAttribute',
      'setUserId',
    ]);
  });

  afterEach(() => {
    window.newrelic = originalAgent;
    if (originalCode === null) localStorage.removeItem('orderup-demo-code');
    else localStorage.setItem('orderup-demo-code', originalCode);
    history.replaceState(history.state, '', originalUrl);
  });

  it('persists identity attributes so they survive later page loads', () => {
    service.setCustomAttribute('demoCode', 'OU-TEST', true);
    expect(window.newrelic.setCustomAttribute).toHaveBeenCalledWith(
      'demoCode',
      'OU-TEST',
      true,
    );
  });

  it('sets the Browser enduser.id with the standard user ID API', () => {
    service.setUserId('OU-TEST');
    expect(window.newrelic.setUserId).toHaveBeenCalledWith('OU-TEST');
  });

  it('stamps the persisted identity synchronously before Angular bootstraps', () => {
    expect(initializeBrowserIdentity()).toBe('OU-TEST');
    expect(window.newrelic.setUserId).toHaveBeenCalledWith('OU-TEST');
    expect(window.newrelic.setCustomAttribute).toHaveBeenCalledWith(
      'demoCode',
      'OU-TEST',
      true,
    );
    expect(loadOrCreateDemoCode()).toBe('OU-TEST');
  });

  it('uses a URL-selected identity for both attributes before a page load', () => {
    history.replaceState(
      history.state,
      '',
      `${location.pathname}?demoCode=SIM-ABCD`,
    );
    initializeBrowserIdentity();
    expect(window.newrelic.setUserId).toHaveBeenCalledWith('SIM-ABCD');
    expect(window.newrelic.setCustomAttribute).toHaveBeenCalledWith(
      'demoCode',
      'SIM-ABCD',
      true,
    );
    expect(localStorage.getItem('orderup-demo-code')).toBe('SIM-ABCD');
  });

  it('allows a page to start when the Browser agent is disabled', () => {
    window.newrelic = undefined;
    expect(initializeBrowserIdentity()).toBe('OU-TEST');
  });

  it('does not persist unrelated custom attributes by default', () => {
    service.setCustomAttribute('page', '/customer');
    expect(window.newrelic.setCustomAttribute).toHaveBeenCalledWith(
      'page',
      '/customer',
      false,
    );
  });

  it('shares one initial identity when local storage is unavailable', () => {
    spyOn(Storage.prototype, 'getItem').and.throwError('Storage unavailable');
    const code = initializeBrowserIdentity();
    expect(loadOrCreateDemoCode()).toBe(code);
    expect(window.newrelic.setUserId).toHaveBeenCalledWith(code);
  });
});
