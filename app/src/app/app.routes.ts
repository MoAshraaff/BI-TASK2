import { Routes } from '@angular/router';
import { CustomerInactivity } from './customer-inactivity/customer-inactivity';
// Kept routable (just not linked in the nav) so the merged page below can be
// reverted instantly by deleting customer-inactivity/ and restoring the two
// nav links in app.html - see that file's comment.
import { InactiveCustomerAlertRules } from './inactive-customer-alert-rules/inactive-customer-alert-rules';
import { InactiveCustomerAlerts } from './inactive-customer-alerts/inactive-customer-alerts';

export const routes: Routes = [
  { path: '', redirectTo: 'customer-inactivity', pathMatch: 'full' },
  { path: 'customer-inactivity', component: CustomerInactivity },
  { path: 'inactive-customer-alert-rules', component: InactiveCustomerAlertRules },
  { path: 'inactive-customer-alerts', component: InactiveCustomerAlerts }
];
