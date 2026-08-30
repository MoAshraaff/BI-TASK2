import { Injectable, inject } from '@angular/core';
import { NavInfo } from 'bi-interfaces';
import { Observable, map, shareReplay } from 'rxjs';
import { PublicApiClient } from '@salesbuzz/public-sdk';
import { API_BASE_URL } from './api';

/**
 * `bi-interfaces` declares `NavInfo` as an abstract injection token with no
 * default implementation - BiNavComponent's constructor requires it (its
 * "Info" toolbar button calls `getBUDesc(...).subscribe(...)` to show the
 * business unit name in the record-information popup), so instantiating
 * <BI-Nav> anywhere without providing this throws a DI error - the same
 * pattern as PublicApiClient.
 */
// Registered against the `NavInfo` token explicitly in app.config.ts (same
// pattern as PublicApiClient) - providedIn: 'root' would only register this
// class under its own type, not under the abstract NavInfo token BiNavComponent
// actually injects.
@Injectable()
export class HttpNavInfo extends NavInfo {
  private readonly apiClient = inject(PublicApiClient);
  private lookup$: Observable<Record<string, string>> | null = null;

  getBUDesc(buid: string): Observable<string> {
    this.lookup$ ??= this.apiClient
      .get<{ buid: string; description?: string }[]>(`${API_BASE_URL}/api/business-units`)
      .pipe(
        map((rows) => Object.fromEntries((rows ?? []).map((r) => [r.buid, r.description ?? r.buid]))),
        shareReplay(1)
      );

    return this.lookup$.pipe(map((byId) => byId[buid] ?? buid));
  }
}
