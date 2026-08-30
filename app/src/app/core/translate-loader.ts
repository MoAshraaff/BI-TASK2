import { Injectable } from '@angular/core';
import { TranslateLoader } from '@ngx-translate/core';
import { Observable, of } from 'rxjs';
import { EN_TRANSLATIONS } from './en-translations';

/**
 * A static, in-memory TranslateLoader - the app only ever needs English, so
 * this skips fetching a JSON asset entirely and just resolves immediately
 * with the one catalog regardless of which locale ngx-translate asks for.
 */
@Injectable()
export class EnTranslateLoader implements TranslateLoader {
  getTranslation(_lang: string): Observable<Record<string, string>> {
    return of(EN_TRANSLATIONS);
  }
}
