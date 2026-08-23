import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PublicApiClient } from '@salesbuzz/public-sdk';
import { API_BASE_URL } from '../core/api';

type RulePriority = 1 | 2 | 3;

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
  selector: 'app-inactive-customer-alert-rules',
  imports: [FormsModule],
  templateUrl: './inactive-customer-alert-rules.html',
  styleUrl: './inactive-customer-alert-rules.scss'
})
export class InactiveCustomerAlertRules {
  private readonly apiClient = inject(PublicApiClient);
  private readonly apiUrl = `${API_BASE_URL}/api/inactive-customer-alert-rules`;

  protected readonly priorities = PRIORITIES;
  protected readonly priorityLabel = priorityLabel;
  protected readonly priorityBadgeClass = priorityBadgeClass;

  protected readonly rules = signal<InactiveCustomerAlertRule[]>([]);
  protected readonly loading = signal(true);
  protected readonly loadError = signal<string | null>(null);
  protected readonly busy = signal(false);
  protected readonly message = signal<{ text: string; kind: 'ok' | 'error' } | null>(null);

  /* ------------------------------------------------------------ summary */

  protected readonly totalRules = computed(() => this.rules().length);
  protected readonly activeRules = computed(() => this.rules().filter((r) => r.isActive).length);
  protected readonly inactiveRules = computed(() => this.rules().filter((r) => !r.isActive).length);

  /* ------------------------------------------------------------- filters */

  protected readonly searchDraft = signal('');
  protected readonly priorityFilterDraft = signal<RulePriority | null>(null);
  protected readonly sortDraft = signal<'name' | 'days'>('name');
  protected readonly search = signal('');
  protected readonly priorityFilter = signal<RulePriority | null>(null);
  protected readonly sort = signal<'name' | 'days'>('name');

  protected readonly filteredRules = computed(() => {
    const term = this.search().trim().toLowerCase();
    const priority = this.priorityFilter();
    let rows = this.rules().filter((r) => {
      if (priority && r.priority !== priority) return false;
      if (!term) return true;
      return r.ruleName.toLowerCase().includes(term) || r.ruleCode.toLowerCase().includes(term);
    });
    rows = [...rows].sort((a, b) =>
      this.sort() === 'days' ? a.inactiveDays - b.inactiveDays : a.ruleName.localeCompare(b.ruleName));
    return rows;
  });

  /* ----------------------------------------------------------------- form */

  protected readonly editing = signal<RuleFormModel | null>(null);

  constructor() {
    this.refresh();
  }

  private refresh(): void {
    this.loading.set(true);
    this.loadError.set(null);
    this.apiClient.get<InactiveCustomerAlertRule[]>(this.apiUrl).subscribe({
      next: (rows) => {
        this.rules.set(rows ?? []);
        this.loading.set(false);
      },
      error: (err) => {
        this.loadError.set(this.describe(err, 'Could not load the alert rules.'));
        this.loading.set(false);
      }
    });
  }

  protected applyFilters(): void {
    this.search.set(this.searchDraft());
    this.priorityFilter.set(this.priorityFilterDraft());
    this.sort.set(this.sortDraft());
  }

  protected resetFilters(): void {
    this.searchDraft.set('');
    this.priorityFilterDraft.set(null);
    this.sortDraft.set('name');
    this.search.set('');
    this.priorityFilter.set(null);
    this.sort.set('name');
  }

  /* --------------------------------------------------------- rule actions */

  protected startAdd(): void {
    this.message.set(null);
    this.editing.set(emptyForm());
  }

  protected startEdit(rule: InactiveCustomerAlertRule): void {
    this.message.set(null);
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
      this.message.set({ text: problem, kind: 'error' });
      return;
    }

    const payload = {
      ruleName: form.ruleName.trim(),
      ruleNameA: form.ruleNameA.trim() || null,
      inactiveDays: form.inactiveDays,
      priority: form.priority,
      isActive: form.isActive
    };

    this.busy.set(true);
    this.message.set(null);
    const request = form.id === null
      ? this.apiClient.post<InactiveCustomerAlertRule>(this.apiUrl, payload)
      : this.apiClient.put<InactiveCustomerAlertRule>(`${this.apiUrl}/${form.id}`, payload);

    request.subscribe({
      next: () => {
        this.busy.set(false);
        this.editing.set(null);
        this.message.set({ text: form.id === null ? 'Rule created.' : 'Rule updated.', kind: 'ok' });
        this.refresh();
      },
      error: (err) => {
        this.busy.set(false);
        this.message.set({ text: this.describe(err, 'Could not save the rule.'), kind: 'error' });
      }
    });
  }

  protected remove(rule: InactiveCustomerAlertRule): void {
    if (!confirm(`Are you sure you want to delete the inactive customer alert rule "${rule.ruleName}"?`)) return;

    this.busy.set(true);
    this.message.set(null);
    this.apiClient.delete(`${this.apiUrl}/${rule.id}`).subscribe({
      next: () => {
        this.busy.set(false);
        this.message.set({ text: 'Rule deleted.', kind: 'ok' });
        this.refresh();
      },
      error: (err) => {
        this.busy.set(false);
        this.message.set({ text: this.describe(err, 'Could not delete the rule.'), kind: 'error' });
      }
    });
  }

  protected toggleActive(rule: InactiveCustomerAlertRule): void {
    this.busy.set(true);
    this.message.set(null);
    const payload = {
      ruleName: rule.ruleName,
      ruleNameA: rule.ruleNameA,
      inactiveDays: rule.inactiveDays,
      priority: rule.priority,
      isActive: !rule.isActive
    };
    this.apiClient.put<InactiveCustomerAlertRule>(`${this.apiUrl}/${rule.id}`, payload).subscribe({
      next: () => {
        this.busy.set(false);
        this.message.set({ text: rule.isActive ? 'Rule deactivated.' : 'Rule activated.', kind: 'ok' });
        this.refresh();
      },
      error: (err) => {
        this.busy.set(false);
        this.message.set({ text: this.describe(err, 'Could not update the rule.'), kind: 'error' });
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

  private describe(err: any, fallback: string): string {
    const apiErrors = err?.error?.errors;
    if (apiErrors) {
      return (Object.values(apiErrors) as string[][]).flat().join(' ');
    }
    return err?.error?.message ?? err?.message ?? fallback;
  }
}
