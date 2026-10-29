import 'package:flutter_bloc/flutter_bloc.dart';

enum DashboardTab { home, cart, create, search, profile }

class DashboardNavigationCubit extends Cubit<DashboardTab> {
  DashboardNavigationCubit({DashboardTab initialTab = DashboardTab.profile})
    : super(initialTab);

  void selectTab(DashboardTab tab) {
    if (state == tab) return;
    emit(tab);
  }

  void selectPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= DashboardTab.values.length) {
      return;
    }

    selectTab(DashboardTab.values[pageIndex]);
  }
}
