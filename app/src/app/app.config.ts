import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { PublicApiClient } from '@salesbuzz/public-sdk';

import { routes } from './app.routes';
import { HttpApiClient } from './core/http-api-client';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(),
    { provide: PublicApiClient, useClass: HttpApiClient }
  ]
};
