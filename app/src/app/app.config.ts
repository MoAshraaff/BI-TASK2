import { ApplicationConfig, importProvidersFrom, provideBrowserGlobalErrorListeners, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { DecimalPipe } from '@angular/common';
import { provideAnimations } from '@angular/platform-browser/animations';
import { TranslateLoader, TranslateModule } from '@ngx-translate/core';
import { MessageService } from '@progress/kendo-angular-l10n';
import { NavInfo } from 'bi-interfaces';
import { CreateDialog, PublicApiClient } from '@salesbuzz/public-sdk';

import { routes } from './app.routes';
import { HttpApiClient } from './core/http-api-client';
import { HttpNavInfo } from './core/nav-info';
import { EnTranslateLoader } from './core/translate-loader';

// Everything below provideHttpClient() exists to satisfy DI that
// BIGridComponent / BiNavComponent / BISideBarComponent need internally -
// see CLAUDE.md for the reverse-engineered reasons behind each one:
//   - provideAnimations() + TranslateModule: TranslateService is injected
//     but bi-modules never provides it itself.
//   - MessageService, from @progress/kendo-angular-l10n directly: bi-modules'
//     own providers array registers a *different* class also named
//     MessageService (a bundling collision), which doesn't satisfy what
//     BIGridComponent actually asks for.
//   - 'CreateDialog' as a factory-returning-a-factory: BIGridComponent and
//     BiNavComponent call it as `this._dialog()`, i.e. they want a function,
//     not a CreateDialog instance.
//   - DecimalPipe: same naming-collision pattern as MessageService, this
//     time for LocalizedNumberPipe.
//   - NavInfo: bi-interfaces declares it as an abstract token with no
//     implementation; BiNavComponent's "Info" toolbar button needs a
//     concrete one to look up a business unit's description.
export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(),
    provideAnimations(),
    importProvidersFrom(TranslateModule.forRoot({ loader: { provide: TranslateLoader, useClass: EnTranslateLoader } })),
    { provide: PublicApiClient, useClass: HttpApiClient },
    { provide: NavInfo, useClass: HttpNavInfo },
    { provide: 'CreateDialog', useFactory: () => () => new CreateDialog() },
    MessageService,
    DecimalPipe
  ]
};
