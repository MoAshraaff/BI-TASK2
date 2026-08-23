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

@Component({
  selector: 'app-inactive-customer-alerts',
  imports: [FormsModule, DatePipe],
  templateUrl: './inactive-customer-alerts.html',
  styleUrl: './inactive-customer-alerts.scss'
})
export class InactiveCustomerAlerts {
  private readonly apiClient = inject(PublicApiClient);
  private readonly apiUrl = `${API_BASE_URL}/api/inactive-customer-alerts`;

  protected readonly priorities = PRIORITIES;
  protected readonly priorityLabel = priorityLabel;
  protected readonly priorityBadgeClass = priorityBadgeClass;

  protected readonly alerts = signal<InactiveCustomerAlert[]>([]);
  protected readonly loading = signal(true);
  protected readonly loadError = signal<string | null>(null);

  /* ------------------------------------------------------------ summary */

  protected readonly totalAlerts = computed(() => this.alerts().length);
  protected readonly highPriorityAlerts = computed(() => this.alerts().filter((a) => a.priority === 3).length);
  protected readonly customersAffected = computed(
    () => new Set(this.alerts().map((a) => a.customerNo)).size
  );

  /* ------------------------------------------------------------- filters */

  protected readonly searchDraft = signal('');
  protected readonly priorityFilterDraft = signal<RulePriority | null>(null);
  protected readonly sortDraft = signal<'days' | 'name'>('days');
  protected readonly search = signal('');
  protected readonly priorityFilter = signal<RulePriority | null>(null);
  protected readonly sort = signal<'days' | 'name'>('days');

  protected readonly filteredAlerts = computed(() => {
    const term = this.search().trim().toLowerCase();
    const priority = this.priorityFilter();
    let rows = this.alerts().filter((a) => {
      if (priority && a.priority !== priority) return false;
      if (!term) return true;
      return a.customerName.toLowerCase().includes(term) || a.customerNo.toLowerCase().includes(term);
    });
    rows = [...rows].sort((a, b) =>
      this.sort() === 'name' ? a.customerName.localeCompare(b.customerName) : b.daysInactive - a.daysInactive);
    return rows;
  });

  constructor() {
    this.refresh();
  }

  protected refresh(): void {
    this.loading.set(true);
    this.loadError.set(null);
    this.apiClient.get<InactiveCustomerAlert[]>(this.apiUrl).subscribe({
      next: (rows) => {
        this.alerts.set(rows ?? []);
        this.loading.set(false);
      },
      error: (err) => {
        this.loadError.set(err?.error?.message ?? err?.message ?? 'Could not load inactive customer alerts.');
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
    this.sortDraft.set('days');
    this.search.set('');
    this.priorityFilter.set(null);
    this.sort.set('days');
  }
}
