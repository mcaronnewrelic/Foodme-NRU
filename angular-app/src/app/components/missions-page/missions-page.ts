import { Component, ChangeDetectionStrategy } from '@angular/core';
import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';
import { MissionProgressService } from '../../services/mission-progress.service';
import { MISSIONS } from '../../services/missions';
import { DemoIdentityService } from '../../services/demo-identity.service';

/**
 * The Missions page: the student's home for the five missions (spec
 * section 6, moved off How It Works 2026-11-01 at Michael's request).
 * Always available - not gated on Behind the scenes. The checks
 * themselves still live in the callouts on each mission's pages; this
 * page is the map and the scoreboard.
 */
@Component({
  selector: 'app-missions-page',
  imports: [RouterModule, HeaderComponent],
  templateUrl: './missions-page.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './missions-page.css',
})
export class MissionsPageComponent {
  protected readonly missions = MISSIONS;

  /** What each mission has the student do, and what its check asks. */
  protected readonly blurbs: Record<string, string> = {
    'mission-1':
      'Use the site like a customer — every page you visit adds a kind of telemetry. The check asks how many kinds your visit has produced.',
    'mission-2':
      "Pick a restaurant and open its menu, using any of the filters on the way. The check sits in the menu's callout.",
    'mission-3':
      "Place an order and keep the receipt: the check asks for the last four characters of your order's request ID.",
    'mission-4':
      'Come back and find that order again by its phone number. The check asks which two keys tie the order to you.',
    'mission-5':
      'Break something on purpose: press Simulate an Error on How It Works and find its incident code in the failing transaction, or hunt the planted failure that is always live. Either check closes the mission.',
  };

  constructor(
    public progress: MissionProgressService,
    private identity: DemoIdentityService,
  ) {}

  get dashboardUrl(): string {
    return `/api/dashboard?${new URLSearchParams({ demoCode: this.identity.code() })}`;
  }
}
