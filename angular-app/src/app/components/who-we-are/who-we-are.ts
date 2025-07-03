import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';

@Component({
  selector: 'app-who-we-are',
  imports: [CommonModule, RouterModule, HeaderComponent],
  templateUrl: './who-we-are.html',
  styleUrl: './who-we-are.css'
})
export class WhoWeAreComponent {
}
