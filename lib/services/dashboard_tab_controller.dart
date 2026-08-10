/// Lets deeply-nested screens (e.g. BookingAddressScreen, reached via
/// Home/Search/All Categories -> ServiceCategoryScreen -> here) switch the
/// dashboard's bottom-nav tab without needing a callback threaded through
/// every intermediate screen.
///
/// IndividualDashboardScreen registers itself on initState/dispose; any
/// screen further down the tree can call [switchTo] directly.
class DashboardTabController {
  static void Function(int index)? _switchTab;

  static void register(void Function(int index) switchTab) {
    _switchTab = switchTab;
  }

  static void unregister() {
    _switchTab = null;
  }

  static void switchTo(int index) {
    _switchTab?.call(index);
  }
}
