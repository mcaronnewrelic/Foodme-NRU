import { Component, ChangeDetectionStrategy } from '@angular/core';
import { HeaderComponent } from '../header/header';
import { InvestigationComponent } from '../investigation/investigation';
import { INVESTIGATIONS } from '../../services/investigations';

/**
 * The Investigations page (spec section 11, moved off How It Works
 * 2026-11-01 at Michael's request). Always available - not gated on
 * Behind the scenes. An investigation's checkpoints open only while
 * that investigation is live: the instructor arms one (on the
 * unlisted Instructor page), or I6 arms itself with its burst.
 */
@Component({
  selector: 'app-investigations-page',
  imports: [HeaderComponent, InvestigationComponent],
  templateUrl: './investigations-page.html',
  changeDetection: ChangeDetectionStrategy.Eager
})
export class InvestigationsPageComponent {
  protected readonly investigations = INVESTIGATIONS;
}
