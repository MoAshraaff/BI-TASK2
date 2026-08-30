import { Routes } from '@angular/router';
import { Alerts } from './alerts/alerts';

export const routes: Routes = [
  { path: '', redirectTo: 'alerts', pathMatch: 'full' },
  { path: 'alerts', component: Alerts },
  // Old routes folded into /alerts (Alert Rules) - redirect rather than 404
  // in case anything still links to them.
  { path: 'alert-rules', redirectTo: 'alerts' }
];
