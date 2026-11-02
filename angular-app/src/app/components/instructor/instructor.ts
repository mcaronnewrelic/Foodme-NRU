import { Component, ChangeDetectionStrategy, signal } from '@angular/core';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { HeaderComponent } from '../header/header';
import { NrConfigService, ScenarioKind, ArmedScenario } from '../../nr-config';

/**
 * Instructor controls (moved off How It Works 2026-11-01 at Michael's
 * request): arming the planted-failure scenario and the
 * investigations. Deliberately NOT linked from the menu - the route
 * is /instructor, for the instructor to bookmark - so students do not
 * stumble into changing what is armed. The endpoints behind these
 * buttons are unauthenticated by design (a teaching demo); the
 * separate page is about discoverability, not security.
 */
@Component({
  selector: 'app-instructor',
  imports: [RouterModule, FormsModule, HeaderComponent],
  templateUrl: './instructor.html',
  changeDetection: ChangeDetectionStrategy.Eager
})
export class InstructorComponent {
  protected readonly NrConfigService = NrConfigService;

  readonly restaurantNames = signal<string[]>([]);
  readonly itemNames = signal<string[]>([]);
  readonly selectedKind = signal<ScenarioKind>('order-item');
  readonly selectedTarget = signal<string>('');

  constructor(
    private http: HttpClient,
    public nrConfig: NrConfigService
  ) {
    // Current scenario + investigation state, and the pick-lists for
    // arming a different scenario.
    this.nrConfig.refreshDemoState();
    this.nrConfig.refreshInvestigationState();
    this.http.get<{ name: string; menuItems?: { name: string }[] }[]>('/api/restaurant').subscribe({
      next: restaurants => {
        this.restaurantNames.set(restaurants.map(r => r.name));
        this.itemNames.set([...new Set(restaurants.flatMap(r => (r.menuItems || []).map(m => m.name)))]);
        this.selectedTarget.set(this.targetsForKind()[0] || '');
      },
      error: () => {}
    });
  }

  currentDescription(): string | null {
    const state = this.nrConfig.demoState();
    if (!state?.armed) return null;
    return NrConfigService.describeScenario({ ...state.armed, source: state.source as ArmedScenario['source'] });
  }

  targetsForKind(): string[] {
    return this.selectedKind() === 'order-item' ? this.itemNames() : this.restaurantNames();
  }

  onKindChange(kind: ScenarioKind) {
    this.selectedKind.set(kind);
    this.selectedTarget.set(this.targetsForKind()[0] || '');
  }

  armSelected() {
    if (this.selectedTarget()) {
      this.nrConfig.armScenario(this.selectedKind(), this.selectedTarget());
    }
  }
}
