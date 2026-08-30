import { AfterViewInit, Component, ElementRef, ViewChild, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { IMenuItem, PublicSdkModule } from '@salesbuzz/public-sdk';

// Only "Alerts & Rules" goes anywhere real. The rest are decorative filler
// (path: '') so the sidebar reads as a full product nav like the reference
// screenshot - '' safely falls through to the '' -> /alerts redirect in
// app.routes.ts rather than erroring, so a stray click is harmless.
const MENU_ITEMS: IMenuItem[] = [
  { text: 'Alerts & Rules', icon: 'assets/icons/Dashboard.svg', path: '/alerts' },
  { text: 'Favorites', icon: 'assets/icons/Favorite.svg', path: '' },
  { text: 'Recent', icon: 'assets/icons/carbon--recently-viewed.svg', path: '' },
  { text: 'Customers', icon: 'assets/icons/supervisor.svg', path: '' },
  { text: 'Home', icon: 'assets/icons/Home.svg', path: '' },
  { text: 'Account', icon: 'assets/icons/account_circle_black_24dp.svg', path: '' },
  { text: 'Inventory', icon: 'assets/icons/InventoryManagement.svg', path: '' },
  { text: 'Point of Sale', icon: 'assets/icons/Point of Sale.svg', path: '' },
  { text: 'General Ledger', icon: 'assets/icons/GeneralLedger.svg', path: '' },
  { text: 'Workflow', icon: 'assets/icons/workflow.svg', path: '' },
  { text: 'Reports', icon: 'assets/icons/report.svg', path: '' }
];

interface SidebarInternals {
  collapsed: boolean;
  closed: boolean;
  changeBackGround?: () => void;
  CheckToggleDrawer?: () => void;
}

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, PublicSdkModule],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements AfterViewInit {
  private readonly elementRef = inject(ElementRef);

  @ViewChild('sidebar') private readonly sidebarRef?: SidebarInternals;

  protected readonly menuItems = MENU_ITEMS;

  constructor() {
    // Selects EnTranslateLoader's catalog - bi-modules' own components call
    // translateService.instant(key) throughout (toolbar messages, the delete
    // confirmation dialog), and with no language selected those calls return
    // the raw key instead of real English text.
    inject(TranslateService).use('en');
  }

  /**
   * "collapsed" isn't an @Input on BISideBarComponent - it's an internal
   * field only reachable by clicking its own toolbar button. Firing that
   * click once on load gives the icon-only rail look by default instead of
   * requiring the user to toggle it manually every visit.
   *
   * Simulating the DOM click turned out unreliable - timing against Kendo's
   * own initial drawer layout varied enough to sometimes never fire and
   * sometimes leave `collapsed` true internally while the drawer kept
   * rendering wide. Calling the exact same internal method the click handler
   * calls (`changeBackGround()`, plus the `closed = false` and
   * `CheckToggleDrawer()` it fires alongside) skips the DOM entirely, so it
   * doesn't depend on the toggle button existing yet or receiving a
   * synthetic click correctly - only on the component instance existing,
   * which @ViewChild guarantees by ngAfterViewInit.
   */
  ngAfterViewInit(): void {
    const host: HTMLElement = this.elementRef.nativeElement;
    const isCollapsed = () => {
      const toolbar = host.querySelector('.custom-toolbar');
      if (!toolbar) return false;
      const width = toolbar.getBoundingClientRect().width;
      return width > 0 && width <= 60;
    };
    let attempts = 0;
    const tryCollapse = () => {
      const sidebar = this.sidebarRef;
      if (!sidebar || isCollapsed() || attempts++ >= 20) return;
      sidebar.changeBackGround?.();
      sidebar.closed = false;
      sidebar.CheckToggleDrawer?.();
      setTimeout(tryCollapse, 150);
    };
    setTimeout(tryCollapse, 150);
  }
}
