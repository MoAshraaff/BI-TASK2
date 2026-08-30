import { Component, computed, inject, signal } from '@angular/core';
import {
  ControlTypes, DataTypes, IChangeset, IColumns, INavBtn, PublicApiClient, PublicSdkModule
} from '@salesbuzz/public-sdk';
import { ApiGridDataSource } from '../core/api-grid-data-source';
import { API_BASE_URL, col, selectCol } from '../core/api';

interface AlertRow {
  alertID: number;
  customerNo: string;
  customerName?: string;
  salesmanNo?: string;
  ruleName: string;
  alertDate: string;
  lastOrderDate?: string;
  metricValue?: number;
  alertMessage: string;
  severity: number;
  status: number;
}

const SEVERITIES = [
  { value: 1, text: 'Low' },
  { value: 2, text: 'Medium' },
  { value: 3, text: 'High' }
];

// BI-Grid falls back to a fixed 350px scroll height whenever [height] isn't
// bound - fine for a full page, but with 5-row paging it leaves a large dead
// gap under whatever's actually on the last (often partial) page. Sizing
// height to the current page's real row count removes that gap instead.
const GRID_HEADER_HEIGHT = 28;
const ROW_HEIGHT = 36;

/**
 * The Attachments feature (bi-modules' BiAttachmentsComponent, wired through
 * BI-Nav's Attach button) needs a real attachment-storage table this schema
 * does not have, so it is switched off here rather than left to fail.
 */
const NAV_BUTTONS: INavBtn = {
  attach: { visibility: false, disable: false }
};

@Component({
  selector: 'app-alerts',
  imports: [PublicSdkModule],
  templateUrl: './alerts.html',
  styleUrl: './alerts.scss'
})
export class Alerts {
  private readonly apiClient = inject(PublicApiClient);

  protected readonly navButtons = NAV_BUTTONS;
  protected readonly rulesRowTitle = signal('');
  /** Surfaces add/edit/delete failures (e.g. a duplicate rule code) that
   * otherwise fail silently - BI-Nav's toolbar has no error display of its own. */
  protected readonly rulesError = signal<string | null>(null);

  /**
   * Populated asynchronously after construction (see the fetch in the
   * constructor) - selectCol's "Scope" column below holds this same array
   * reference, so pushing customers into it in place is enough for the
   * dropdown to pick them up once the request resolves, no rebuild needed.
   * '' stands for "no scope" (every customer), since the dropdown can't bind
   * a real `null` value.
   */
  protected readonly customerOptions: { value: string; text: string }[] = [{ value: '', text: 'All' }];

  protected readonly alertsRowCount = signal(0);
  protected readonly rulesRowCount = signal(0);
  protected readonly alertsGridHeight = computed(
    () => GRID_HEADER_HEIGHT + Math.max(this.alertsRowCount(), 1) * ROW_HEIGHT
  );
  protected readonly rulesGridHeight = computed(
    () => GRID_HEADER_HEIGHT + Math.max(this.rulesRowCount(), 1) * ROW_HEIGHT
  );

  protected readonly alertsChangeSet: IChangeset = { changesetArr: [] };
  protected readonly rulesChangeSet: IChangeset = { changesetArr: [] };

  /* ------------------------------------------------------------- alerts */

  // Exactly the reference screenshot's column set/order. "Inactive Days" is
  // metricValue - the actual figure that tripped the rule (a day count for
  // NO_ORDER_DAYS alerts, but a percentage for SALES_DROP_PCT ones, same
  // caveat as Threshold on the rules grid below).
  protected readonly alertColumns: IColumns[] = [
    col('customerName', 'Customer', DataTypes.Text, ControlTypes.Text, { IsFilterable: false }),
    // Reference screenshot calls this "Sales Rep" too, despite it being the
    // salesman's code (e.g. "SM02") rather than their name.
    col('salesmanNo', 'Sales Rep', DataTypes.Text, ControlTypes.Text, { IsFilterable: false }),
    col('lastOrderDate', 'Last Order', DataTypes.Date, ControlTypes.Date, { IsFilterable: false }),
    col('metricValue', 'Inactive Days', DataTypes.NUMERIC, ControlTypes.Number, { IsFilterable: false }),
    col('ruleName', 'Applied Rule', DataTypes.Text, ControlTypes.Text, { IsFilterable: false }),
    // Named "Priority" to match the reference screenshot's naming for this
    // same High/Medium/Low concept.
    col('severityText', 'Priority', DataTypes.Text, ControlTypes.Text, { IsFilterable: false })
  ];

  protected readonly alertsDataSource = new ApiGridDataSource(this.apiClient, {
    apiUrl: `${API_BASE_URL}/api/alerts`,
    columns: this.alertColumns.map((c) => ({ Name: c.Name, DataType: c.DataType })),
    key: 'alertID',
    readOnly: true,
    pageSize: 5,
    mapRow: (r: AlertRow) => ({
      ...r,
      severityText: SEVERITIES.find((s) => s.value === r.severity)?.text ?? String(r.severity)
    })
  });

  /** Acknowledge/Resolve aren't grid-editable fields, so they're driven by
   * row selection rather than a BI-Nav toolbar (which only knows Add/Save/
   * Delete/Cancel). */
  protected readonly selectedAlert = signal<AlertRow | null>(null);

  protected onAlertCellClick(event: any): void {
    this.selectedAlert.set(event?.dataItem ?? null);
  }

  protected setAlertStatus(status: 2 | 3): void {
    const row = this.selectedAlert();
    if (!row) return;
    this.apiClient.patch(`${API_BASE_URL}/api/alerts/${row.alertID}/status/${status}`, {}).subscribe(() => {
      this.selectedAlert.set(null);
      this.alertsDataSource.read();
    });
  }

  /* ---------------------------------------------------------------- rules */

  // Exactly the reference screenshot's column set/order. RuleType and
  // NotifyTarget are required by the database (CHECK constraints) but have no
  // column here to edit them from, so new rows get sane fixed defaults via
  // rulesDataSource's addDefaults below rather than failing to save.
  protected readonly ruleColumns: IColumns[] = [
    // BIGridComponent builds each row's edit form from exactly this column
    // list - ruleID has to be one of them (even hidden) or the form never
    // gets a control for it, and Save's PUT ends up targeting ".../undefined"
    // for an edit on an existing row.
    col('ruleID', 'Rule ID', DataTypes.NUMERIC, ControlTypes.Number, { IsVisible: false, IsFilterable: false }),
    col('ruleName', 'Rule Name', DataTypes.Text, ControlTypes.Text, { IsEditable: true, IsFilterable: false }),
    // Limits a rule to one specific customer ("All" = every customer in the
    // rule's business unit). selectCol resolves the stored customer code to
    // the matching option's text automatically (same mechanism Priority/
    // Notify already relied on), so this shows the customer's name, not code.
    selectCol('scopeCustomerNo', 'Scope', this.customerOptions, { IsFilterable: false }),
    // Named "Inactive Days" per the reference - accurate for NO_ORDER_DAYS
    // rules, but this same field is a percentage for the SALES_DROP_PCT rule.
    col('thresholdValue', 'Inactive Days', DataTypes.NUMERIC, ControlTypes.Number, { IsEditable: true, IsFilterable: false }),
    // Named "Priority" to match the reference screenshot's naming for this
    // same High/Medium/Low concept.
    selectCol('severity', 'Priority', SEVERITIES, { IsFilterable: false }),
    // BIGridComponent's own template switches on the literal string 'boolean'
    // for its checkbox editor - ControlTypes.CheckBox ('checkbox') matches no
    // case there and silently renders no column at all. No enum member for
    // 'boolean' exists either, so this is cast past the type rather than
    // using ControlTypes.CheckBox as the interface implies it should work.
    // Named "Status" to match the reference screenshot - this is the rule's
    // active/inactive status, just rendered as a checkbox rather than text.
    col('isActive', 'Status', DataTypes.Boolean, 'boolean' as ControlTypes, { IsEditable: true, IsFilterable: false }),
    col('createdby', 'Created By', DataTypes.Text, ControlTypes.Text, { IsFilterable: false }),
    col('createdOn', 'Created At', DataTypes.Date, ControlTypes.Date, { IsFilterable: false })
  ];

  protected readonly rulesDataSource = new ApiGridDataSource(this.apiClient, {
    apiUrl: `${API_BASE_URL}/api/alert-rules`,
    columns: this.ruleColumns.map((c) => ({ Name: c.Name, DataType: c.DataType })),
    key: 'ruleID',
    pageSize: 5,
    // severity/thresholdValue are real editable columns (Priority/Inactive
    // Days), so a row saved without touching them submits 0 - valid as far as
    // the form is concerned, but rejected by the database's own CHECK
    // constraints (Severity 1-3, ThresholdValue > 0). That 400 has nowhere to
    // surface today, so it just looks like Save silently did nothing while
    // actually leaving the row stuck pending. Defaulting here means Save
    // always succeeds; the user can still edit either value in place after.
    addDefaults: { ruleType: 'NO_ORDER_DAYS', notifyTarget: 'MANAGER', severity: 2, thresholdValue: 30 },
    // The Scope dropdown's "All" option is keyed by '' (a select column can't
    // bind a real null) - normalizing here means an existing unscoped row
    // (scopeCustomerNo: null) still resolves to it instead of showing blank.
    mapRow: (r: any) => ({
      ...r,
      scopeCustomerNo: r.scopeCustomerNo ?? ''
    })
  });

  constructor() {
    this.alertsDataSource.subscribe((r) => this.alertsRowCount.set(r.data.length));
    this.rulesDataSource.subscribe((r) => this.rulesRowCount.set(r.data.length));
    this.rulesDataSource.error$.subscribe((message) => this.rulesError.set(message));
    this.alertsDataSource.read();
    this.rulesDataSource.read();

    this.apiClient.get<{ customerNo: string; customerNameE?: string }[]>(`${API_BASE_URL}/api/customers`)
      .subscribe((rows) => {
        this.customerOptions.push(
          ...(rows ?? []).map((c) => ({ value: c.customerNo, text: c.customerNameE || c.customerNo }))
        );
      });
  }

  protected onRulesCellClick(event: any): void {
    const row = event?.dataItem;
    this.rulesRowTitle.set(row ? `( Rule ID: ${row.ruleID ?? '—'}, Name: ${row.ruleName ?? ''} )` : '');
  }
}
