import { Component, inject, signal, ChangeDetectionStrategy } from '@angular/core';
import { NavigationEnd, Router, RouterLink } from '@angular/router';
import { filter } from 'rxjs';
import { NrConfigService } from '../../nr-config';
import { MissionProgressService } from '../../services/mission-progress.service';
import { MISSIONS, Mission, missionForUrl } from '../../services/missions';

/**
 * The mission progress strip (spec section 2): shown at the top of every
 * page in Behind-the-scenes mode only. Names the mission the current
 * page belongs to ("Mission 2 of 5 · Find a menu in the data") and shows
 * the five stops as ticks - filled once a mission's check is solved,
 * outlined once its Try or Find step has happened. Ticks link to each
 * mission's starting page.
 */
@Component({
  selector: 'app-mission-strip',
  imports: [RouterLink],
  templateUrl: './mission-strip.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './mission-strip.css'
})
export class MissionStripComponent {
  protected config = inject(NrConfigService);
  protected progress = inject(MissionProgressService);
  private router = inject(Router);

  protected readonly missions = MISSIONS;
  private url = signal(this.router.url);

  constructor() {
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe(() => this.url.set(this.router.url));
  }

  protected get current(): Mission | null {
    return missionForUrl(this.url());
  }

  protected get checkedCount(): number {
    return this.progress.checkedCount();
  }

  protected tickState(mission: Mission): 'checked' | 'started' | 'todo' {
    if (this.progress.isChecked(mission.id)) return 'checked';
    const state = this.progress.missionState(mission.id);
    return state.tried || state.found ? 'started' : 'todo';
  }
}
