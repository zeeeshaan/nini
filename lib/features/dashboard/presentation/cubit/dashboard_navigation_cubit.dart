import 'package:flutter_bloc/flutter_bloc.dart';

enum DashboardTab { home, cart, create, search, profile }

class DashboardNavigationCubit extends Cubit<DashboardTab> {
  DashboardNavigationCubit({DashboardTab initialTab = DashboardTab.profile})
    : super(initialTab) {
    active = this;
  }

  /// Shell cubit for the visible dashboard — used by notification deep links
  /// that are pushed above the dashboard route (sibling, not descendant).
  static DashboardNavigationCubit? active;

  /// Wired by [DashboardScreen] so external opens also move the PageView.
  Future<void> Function(DashboardTab tab)? onExternalOpen;

  void selectTab(DashboardTab tab) {
    if (isClosed) return;
    if (state == tab) return;
    emit(tab);
  }

  /// Opens a tab from notification / deep-link handlers (updates page + nav).
  Future<void> openTab(DashboardTab tab) async {
    if (isClosed) return;
    final open = onExternalOpen;
    if (open != null) {
      await open(tab);
      return;
    }
    selectTab(tab);
  }

  void selectPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= DashboardTab.values.length) {
      return;
    }

    selectTab(DashboardTab.values[pageIndex]);
  }

  @override
  Future<void> close() {
    if (identical(active, this)) active = null;
    onExternalOpen = null;
    return super.close();
  }
}
