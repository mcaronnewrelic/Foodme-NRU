import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';
import { initializeBrowserIdentity } from './app/services/demo-identity-bootstrap';

initializeBrowserIdentity();
bootstrapApplication(App, appConfig).catch((err) => console.error(err));
