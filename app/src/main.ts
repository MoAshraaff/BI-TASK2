import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

// bi-modules provides LOCALE_ID via useFactory: () => localStorage.getItem('lang'),
// which resolves to null (crashing Kendo's CldrIntlService) if this key is unset
// before BIGridComponent/BiNavComponent first instantiate.
if (!localStorage.getItem('lang')) {
  localStorage.setItem('lang', 'en-US');
}

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
