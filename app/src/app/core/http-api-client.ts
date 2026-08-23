import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { PublicApiClient, PublicApiRequestOptions } from '@salesbuzz/public-sdk';

// The @salesbuzz/public-sdk package ships PublicApiClient as an abstract DI
// token - this is the concrete HttpClient-backed implementation every screen
// injects it through, so there is one API communication path in the app.
@Injectable({ providedIn: 'root' })
export class HttpApiClient implements PublicApiClient {
  private readonly http = inject(HttpClient);

  get<T>(url: string, options?: PublicApiRequestOptions): Observable<T> {
    return this.http.get<T>(url, { headers: options?.headers, params: options?.params as any });
  }

  post<T>(url: string, body: unknown, options?: PublicApiRequestOptions): Observable<T> {
    return this.http.post<T>(url, body, { headers: options?.headers, params: options?.params as any });
  }

  put<T>(url: string, body: unknown, options?: PublicApiRequestOptions): Observable<T> {
    return this.http.put<T>(url, body, { headers: options?.headers, params: options?.params as any });
  }

  patch<T>(url: string, body: unknown, options?: PublicApiRequestOptions): Observable<T> {
    return this.http.patch<T>(url, body, { headers: options?.headers, params: options?.params as any });
  }

  delete<T>(url: string, options?: PublicApiRequestOptions): Observable<T> {
    return this.http.delete<T>(url, { headers: options?.headers, params: options?.params as any });
  }
}
