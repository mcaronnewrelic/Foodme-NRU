import { Component, ChangeDetectionStrategy } from '@angular/core';

import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';

@Component({
  selector: 'app-who-we-are',
  imports: [RouterModule, HeaderComponent],
  templateUrl: './who-we-are.html',
  changeDetection: ChangeDetectionStrategy.Eager,
  styleUrl: './who-we-are.css'
})
export class WhoWeAreComponent {
}
