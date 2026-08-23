import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';
import { PublicApiClient } from '@salesbuzz/public-sdk';
import { API_BASE_URL } from '../core/api';

type RulePriority = 1 | 2 | 3;

interface InactiveCustomerAlert {
  ruleId: number;
  ruleName: string;
  ruleCode: string;
  inactiveDaysThreshold: number;
  priority: RulePriority;
  customerNo: string;
  customerName: string;
  salesmanNo: string | null;
  mobile: string | null;
  lastOrderDate: string;
  daysInactive: number;
}

interface InactiveCustomerAlertRule {
  id: number;
  ruleCode: string;
  ruleName: string;
  ruleNameA: string | null;
  inactiveDays: number;
  priority: RulePriority;
  isActive: boolean;
  lastRunOn: string | null;
  createdOn: string;
  createdBy: string | null;
  modifiedOn: string | null;
  modifiedBy: string | null;
}

interface RuleFormModel {
  id: number | null;
  ruleName: string;
  ruleNameA: string;
  inactiveDays: number;
  priority: RulePriority;
  isActive: boolean;
}

const PRIORITIES: { value: RulePriority; label: string }[] = [
  { value: 1, label: 'Low' },
  { value: 2, label: 'Medium' },
  { value: 3, label: 'High' }
];

function priorityLabel(p: RulePriority): string {
  return PRIORITIES.find((x) => x.value === p)?.label ?? String(p);
}

function priorityBadgeClass(p: RulePriority): string {
  return p === 3 ? 'badge-high' : p === 2 ? 'badge-medium' : 'badge-low';
}

function emptyForm(): RuleFormModel {
  return { id: null, ruleName: '', ruleNameA: '', inactiveDays: 30, priority: 2, isActive: true };
}

@Component({
  selector: 'app-customer-inactivity',
  imports: [FormsModule, DatePipe],
  templateUrl: './customer-inactivity.html',
  styleUrl: './customer-inactivity.scss'
})
export class CustomerInactivity {
  private readonly apiClient = inject(PublicApiClient);
  private readonly alertsApiUrl = `${API_BASE_URL}/api/inactive-customer-alerts`;
  private readonly rulesApiUrl = `${API_BASE_URL}/api/inactive-customer-alert-rules`;

  protected readonly priorities = PRIORITIES;
  protected readonly priorityLabel = priorityLabel;
  protected readonly priorityBadgeClass = priorityBadgeClass;

  constructor() {
    this.refreshAlerts();
    this.refreshRules();
  }

  /* ============================================================== alerts */

  protected readonly alerts = signal<InactiveCustomerAlert[]>([]);
  protected readonly alertsLoading = signal(true);
  protected readonly alertsLoadError = signal<string | null>(null);
  protected readonly expandedAlertKey = signal<string | null>(null);

  protected readonly alertSearch = signal('');
  protected readonly alertPriorityFilter = signal<RulePriority | null>(null);
  protected readonly alertSalesRepFilter = signal<string | null>(null);

  protected readonly salesReps = computed(() =>
    Array.from(new Set(this.alerts().map((a) => a.salesmanNo).filter((x): x is string => !!x))).sort()
  );

  protected readonly totalAlerts = computed(() => this.alerts().length);
  protected readonly highPriorityAlerts = computed(() => this.alerts().filter((a) => a.priority === 3).length);
  protected readonly customersAffected = computed(() => new Set(this.alerts().map((a) => a.customerNo)).size);

  protected readonly filteredAlerts = computed(() => {
    const term = this.alertSearch().trim().toLowerCase();
    const priority = this.alertPriorityFilter();
    const salesRep = this.alertSalesRepFilter();
    return this.alerts()
      .filter((a) => {
        if (priority && a.priority !== priority) return false;
        if (salesRep && a.salesmanNo !== salesRep) return false;
        if (term && !a.customerName.toLowerCase().includes(term) && !a.customerNo.toLowerCase().includes(term)) return false;
        return true;
      })
      .sort((a, b) => b.daysInactive - a.daysInactive);
  });

  protected readonly alertsPageSize = 5;
  protected readonly alertsPage = signal(1);
  protected readonly alertsTotalPages = computed(() =>
    Math.max(1, Math.ceil(this.filteredAlerts().length / this.alertsPageSize))
  );
  protected readonly alertsPageNumbers = computed(() =>
    Array.from({ length: this.alertsTotalPages() }, (_, i) => i + 1)
  );
  protected readonly pagedAlerts = computed(() => {
    const page = Math.min(this.alertsPage(), this.alertsTotalPages());
    const start = (page - 1) * this.alertsPageSize;
    return this.filteredAlerts().slice(start, start + this.alertsPageSize);
  });

  protected setAlertsPage(page: number): void {
    this.alertsPage.set(page);
  }

  protected alertKey(a: InactiveCustomerAlert): string {
    return `${a.ruleId}-${a.customerNo}`;
  }

  protected toggleAlertDetail(a: InactiveCustomerAlert): void {
    const key = this.alertKey(a);
    this.expandedAlertKey.set(this.expandedAlertKey() === key ? null : key);
  }

  protected contactHref(a: InactiveCustomerAlert): string | null {
    return a.mobile ? `tel:${a.mobile.replace(/\s+/g, '')}` : null;
  }

  protected setAlertSearch(value: string): void {
    this.alertSearch.set(value);
    this.alertsPage.set(1);
  }

  protected setAlertPriorityFilter(value: RulePriority | null): void {
    this.alertPriorityFilter.set(value);
    this.alertsPage.set(1);
  }

  protected setAlertSalesRepFilter(value: string | null): void {
    this.alertSalesRepFilter.set(value);
    this.alertsPage.set(1);
  }

  protected clearAlertFilters(): void {
    this.alertSearch.set('');
    this.alertPriorityFilter.set(null);
    this.alertSalesRepFilter.set(null);
    this.alertsPage.set(1);
  }

  protected refreshAlerts(): void {
    this.alertsLoading.set(true);
    this.alertsLoadError.set(null);
    this.apiClient.get<InactiveCustomerAlert[]>(this.alertsApiUrl).subscribe({
      next: (rows) => {
        this.alerts.set(rows ?? []);
        this.alertsLoading.set(false);
      },
      error: (err) => {
        this.alertsLoadError.set(err?.error?.message ?? err?.message ?? 'Could not load inactive customer alerts.');
        this.alertsLoading.set(false);
      }
    });
  }

  /* =============================================================== rules */

  protected readonly rules = signal<InactiveCustomerAlertRule[]>([]);
  protected readonly rulesLoading = signal(true);
  protected readonly rulesLoadError = signal<string | null>(null);
  protected readonly rulesBusy = signal(false);
  protected readonly rulesMessage = signal<{ text: string; kind: 'ok' | 'error' } | null>(null);
  protected readonly editing = signal<RuleFormModel | null>(null);

  protected readonly sortedRules = computed(() => [...this.rules()].sort((a, b) => a.inactiveDays - b.inactiveDays));

  protected readonly rulesPageSize = 5;
  protected readonly rulesPage = signal(1);
  protected readonly rulesTotalPages = computed(() =>
    Math.max(1, Math.ceil(this.sortedRules().length / this.rulesPageSize))
  );
  protected readonly rulesPageNumbers = computed(() =>
    Array.from({ length: this.rulesTotalPages() }, (_, i) => i + 1)
  );
  protected readonly pagedRules = computed(() => {
    const page = Math.min(this.rulesPage(), this.rulesTotalPages());
    const start = (page - 1) * this.rulesPageSize;
    return this.sortedRules().slice(start, start + this.rulesPageSize);
  });

  protected setRulesPage(page: number): void {
    this.rulesPage.set(page);
  }

  private refreshRules(): void {
    this.rulesLoading.set(true);
    this.rulesLoadError.set(null);
    this.apiClient.get<InactiveCustomerAlertRule[]>(this.rulesApiUrl).subscribe({
      next: (rows) => {
        this.rules.set(rows ?? []);
        this.rulesLoading.set(false);
      },
      error: (err) => {
        this.rulesLoadError.set(err?.error?.message ?? err?.message ?? 'Could not load the alert rules.');
        this.rulesLoading.set(false);
      }
    });
  }

  protected startAdd(): void {
    this.rulesMessage.set(null);
    this.editing.set(emptyForm());
  }

  protected startEdit(rule: InactiveCustomerAlertRule): void {
    this.rulesMessage.set(null);
    this.editing.set({
      id: rule.id,
      ruleName: rule.ruleName,
      ruleNameA: rule.ruleNameA ?? '',
      inactiveDays: rule.inactiveDays,
      priority: rule.priority,
      isActive: rule.isActive
    });
  }

  protected cancelEdit(): void {
    this.editing.set(null);
  }

  protected save(): void {
    const form = this.editing();
    if (!form) return;

    const problem = this.validate(form);
    if (problem) {
      this.rulesMessage.set({ text: problem, kind: 'error' });
      return;
    }

    const payload = {
      ruleName: form.ruleName.trim(),
      ruleNameA: form.ruleNameA.trim() || null,
      inactiveDays: form.inactiveDays,
      priority: form.priority,
      isActive: form.isActive
    };

    this.rulesBusy.set(true);
    this.rulesMessage.set(null);
    const request = form.id === null
      ? this.apiClient.post<InactiveCustomerAlertRule>(this.rulesApiUrl, payload)
      : this.apiClient.put<InactiveCustomerAlertRule>(`${this.rulesApiUrl}/${form.id}`, payload);

    request.subscribe({
      next: () => {
        this.rulesBusy.set(false);
        this.editing.set(null);
        this.rulesMessage.set({ text: form.id === null ? 'Rule created.' : 'Rule updated.', kind: 'ok' });
        this.refreshRules();
        this.refreshAlerts();
      },
      error: (err) => {
        this.rulesBusy.set(false);
        this.rulesMessage.set({ text: this.describeError(err, 'Could not save the rule.'), kind: 'error' });
      }
    });
  }

  protected remove(rule: InactiveCustomerAlertRule): void {
    if (!confirm(`Are you sure you want to delete the inactive customer alert rule "${rule.ruleName}"?`)) return;

    this.rulesBusy.set(true);
    this.rulesMessage.set(null);
    this.apiClient.delete(`${this.rulesApiUrl}/${rule.id}`).subscribe({
      next: () => {
        this.rulesBusy.set(false);
        this.rulesMessage.set({ text: 'Rule deleted.', kind: 'ok' });
        this.refreshRules();
        this.refreshAlerts();
      },
      error: (err) => {
        this.rulesBusy.set(false);
        this.rulesMessage.set({ text: this.describeError(err, 'Could not delete the rule.'), kind: 'error' });
      }
    });
  }

  protected toggleActive(rule: InactiveCustomerAlertRule): void {
    this.rulesBusy.set(true);
    this.rulesMessage.set(null);
    const payload = {
      ruleName: rule.ruleName,
      ruleNameA: rule.ruleNameA,
      inactiveDays: rule.inactiveDays,
      priority: rule.priority,
      isActive: !rule.isActive
    };
    this.apiClient.put<InactiveCustomerAlertRule>(`${this.rulesApiUrl}/${rule.id}`, payload).subscribe({
      next: () => {
        this.rulesBusy.set(false);
        this.rulesMessage.set({ text: rule.isActive ? 'Rule deactivated.' : 'Rule activated.', kind: 'ok' });
        this.refreshRules();
        this.refreshAlerts();
      },
      error: (err) => {
        this.rulesBusy.set(false);
        this.rulesMessage.set({ text: this.describeError(err, 'Could not update the rule.'), kind: 'error' });
      }
    });
  }

  private validate(form: RuleFormModel): string | null {
    if (!form.ruleName.trim()) return 'Rule name is required.';
    if (!Number.isInteger(form.inactiveDays) || form.inactiveDays <= 0) {
      return 'Inactive days must be a whole number greater than 0.';
    }
    if (!PRIORITIES.some((p) => p.value === form.priority)) return 'Priority must be Low, Medium, or High.';
    return null;
  }

  private describeError(err: any, fallback: string): string {
    const apiErrors = err?.error?.errors;
    if (apiErrors) {
      return (Object.values(apiErrors) as string[][]).flat().join(' ');
    }
    return err?.error?.message ?? err?.message ?? fallback;
  }
}
