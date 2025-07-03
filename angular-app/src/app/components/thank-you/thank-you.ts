import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { HeaderComponent } from '../header/header';

@Component({
  selector: 'app-thank-you',
  imports: [CommonModule, RouterModule, HeaderComponent],
  templateUrl: './thank-you.html',
  styleUrl: './thank-you.css'
})
export class ThankYouComponent {

}
