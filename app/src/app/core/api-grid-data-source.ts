import { BehaviorSubject, Observable, map, of, tap } from 'rxjs';
import { PublicApiClient } from '@salesbuzz/public-sdk';

export interface GridResult {
  data: any[];
  total: number;
}

export interface GridColumnRef {
  Name: string;
  DataType: any;
}

export interface ApiGridOptions {
  /** REST collection endpoint, e.g. `${API_BASE_URL}/api/alert-rules`. */
  apiUrl: string;
  /** Columns the grid renders; also what the SDK filters against. */
  columns: GridColumnRef[];
  /** Property holding the row's identity - the grid resolves ids from it. */
  key: string;
  /** Blocks the write methods. Display-only grids should set this. */
  readOnly?: boolean;
  /** Optional per-row transform applied after fetching (display-friendly fields). */
  mapRow?: (row: any) => any;
  /**
   * Values merged into a new row before it's posted, for fields the grid
   * requires server-side but doesn't expose as a visible/editable column.
   * Real submitted values (if any) still win - see add().
   */
  addDefaults?: Record<string, unknown>;
  /**
   * Enables BI-Grid's built-in pager at this page size. The API has no
   * server-side $skip/$top support, so paging is done client-side here over
   * the already-fetched rows - fine at this data volume.
   */
  pageSize?: number;
}

/**
 * Feeds `BI-Grid` (and, through it, `BI-Nav`'s Add/Save/Delete toolbar) from
 * a REST endpoint.
 *
 * The SDK's `IDataSource` is not a plain object the grid reads from - the
 * grid calls `.subscribe()` on the data source itself, so this has to *be*
 * an observable. Hence extending BehaviorSubject rather than holding one.
 *
 * Method contract, as called by BIGridComponent (itself invoked by BiNavComponent's
 * AddRow()/Save()/DeleteRow() methods):
 *   add(row)        -> POST   {apiUrl}
 *   edit(row, id)   -> PUT    {apiUrl}/{id}
 *   patch(row, id)  -> PATCH  {apiUrl}/{id}
 *   delete(id)      -> DELETE {apiUrl}/{id}
 * `id` arrives already resolved by the grid from the `Key` column.
 */
export class ApiGridDataSource extends BehaviorSubject<GridResult> {
  Params: { Name: string; Operator: string; value: string; DataType: any }[] = [];
  Key: string;
  Key2 = '';
  Key3 = '';
  Key4 = '';
  Key5 = '';
  Key6 = '';
  Columns: GridColumnRef[];
  Type: any = 'api';
  IsClientSideFilter = true;
  LocalData = false;
  data: any[] = [];
  HasPaging = false;
  state: { skip: number; take: number; sort: [] } = { skip: 0, take: 0, sort: [] };
  loading = false;
  APIURL: string;
  POSTAPIURL: string | undefined;
  PUTAPIURL: string | undefined;
  DELETEAPIURL: string | undefined;
  excludeDataFromReq: string[] = [];
  excludeTimeFromReq: string[] = [];

  /** Latest request failure, for the host component to display. */
  readonly error$ = new BehaviorSubject<string | null>(null);

  private readonly options: ApiGridOptions;
  private readonly pageSize?: number;

  constructor(private readonly apiClient: PublicApiClient, options: ApiGridOptions) {
    super({ data: [], total: 0 });
    this.options = options;
    this.APIURL = options.apiUrl;
    this.Columns = options.columns;
    this.Key = options.key;
    this.pageSize = options.pageSize;
    if (this.pageSize) {
      // BIGridComponent's own changePage() only ever updates state.skip, so
      // state.take has to start out (and stay) at the fixed page size.
      this.HasPaging = true;
      this.state.take = this.pageSize;
    }
  }

  read(_filter = ''): void {
    this.loading = true;
    this.error$.next(null);
    this.apiClient.get<any[]>(this.APIURL).subscribe({
      next: (rows) => {
        const mapped = this.options.mapRow ? (rows ?? []).map(this.options.mapRow) : (rows ?? []);
        this.data = mapped;
        this.loading = false;
        const page = this.pageSize ? mapped.slice(this.state.skip, this.state.skip + this.pageSize) : mapped;
        this.next({ data: page, total: mapped.length });
      },
      error: (err) => {
        this.loading = false;
        this.error$.next(this.describe(err));
        this.next({ data: [], total: 0 });
      }
    });
  }

  /**
   * BIGridComponent calls this itself right after a successful Add/Save, with
   * a `?$filter=<key> eq <value>` URL, to fetch back the one row it just
   * wrote - then reads the result as `data?.value[0]` (an OData envelope).
   * The API has no OData support and just returns every row unfiltered, so
   * without help here `data.value` is undefined and `data?.value[0]` throws
   * before the SDK's own "saved" handling (success toast, clearing the row's
   * pending-edit state) ever runs - the write itself still succeeds
   * server-side, it just looks stuck and blocks the next Add/Save.
   */
  get(apiUrl: string): Observable<{ value: any[] }> {
    return this.apiClient.get<any[]>(this.APIURL).pipe(
      map((rows) => {
        const mapped = this.options.mapRow ? (rows ?? []).map(this.options.mapRow) : (rows ?? []);
        return { value: this.filterByODataQuery(mapped, apiUrl) };
      })
    );
  }

  /** Parses the one `$filter=field eq value` clause BIGridComponent generates. */
  private filterByODataQuery(rows: any[], url: string): any[] {
    const filterMatch = /\$filter=([^&]+)/.exec(url);
    if (!filterMatch) return rows;
    const clause = decodeURIComponent(filterMatch[1]);
    const condition = /(\w+)\s+eq\s+'?([^'&]+?)'?(?:\s+and\s|$)/.exec(clause);
    if (!condition) return rows;
    const [, field, value] = condition;
    return rows.filter((row) => String(row[field]) === value);
  }

  add(data: any): Observable<any> {
    if (this.options.readOnly) return of(null);
    const payload = { ...data };
    // Falsy, not just missing: a required numeric column (e.g. Priority) a
    // user never touched submits as 0, which is present in `data` and would
    // survive a plain `{...defaults, ...data}` spread untouched, still
    // failing the same server-side check the default exists to avoid.
    for (const [key, fallback] of Object.entries(this.options.addDefaults ?? {})) {
      if (!payload[key]) payload[key] = fallback;
    }
    return this.apiClient.post(this.APIURL, this.strip(payload)).pipe(this.reportErrors());
  }

  edit(data: any, id: string): Observable<any> {
    if (this.options.readOnly) return of(null);
    return this.apiClient
      .put(`${this.APIURL}/${encodeURIComponent(id)}`, this.strip(data))
      .pipe(this.reportErrors());
  }

  patch(data: any, id: string): Observable<any> {
    if (this.options.readOnly) return of(null);
    return this.apiClient
      .patch(`${this.APIURL}/${encodeURIComponent(id)}`, this.strip(data))
      .pipe(this.reportErrors());
  }

  delete(id: string): Observable<any> {
    if (this.options.readOnly) return of(null);
    return this.apiClient
      .delete(`${this.APIURL}/${encodeURIComponent(id)}`)
      .pipe(this.reportErrors());
  }

  batch(): Observable<any> {
    return of(null);
  }

  formatAPIURLWithFilter(_filter: string) {
    return this.APIURL;
  }

  formatFilter(filter: string) {
    return filter;
  }

  /**
   * Only reports errors - BIGridComponent already calls back into
   * `DataService.read()` itself once add/edit/delete succeeds (its own
   * Save()/DeleteRow()/AddRow() completion handlers), so refreshing here
   * too would just double the request.
   */
  private reportErrors<T>() {
    return (source: Observable<T>) =>
      source.pipe(tap({ error: (err) => this.error$.next(this.describe(err)) }));
  }

  /**
   * The grid hands back its own bookkeeping fields (row id placeholder,
   * change-set status, display-only fields added by mapRow) alongside real
   * values. Dropping the ones that would confuse the API's model binding
   * keeps every endpoint free of defensive parsing. mapRow-added fields end
   * in "Text" by this app's own convention, so they're filtered out too.
   */
  private strip(row: any): any {
    const { RowID, ChangeSetStatus, __status, ...rest } = row ?? {};
    return Object.fromEntries(Object.entries(rest).filter(([k]) => !k.endsWith('Text')));
  }

  /** Prefers the API's own message over a generic HTTP status line. */
  private describe(err: any): string {
    return err?.error?.message ?? err?.message ?? 'The request failed.';
  }
}
