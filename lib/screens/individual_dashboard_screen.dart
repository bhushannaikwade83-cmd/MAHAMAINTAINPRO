import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/dashboard_tab_controller.dart';
import '../widgets/custom_footer.dart';
import 'individual_home_screen.dart';
import 'search_list_screen.dart';
import 'ai_chat_screen.dart';
import 'society_screen.dart';
import 'society_dashboard.dart';
import 'committee_dashboard_screen.dart';
import 'approval_pending_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';

/// Resolves which Society screen to show for tab 3.
///
/// Checks society_customers_individual table by user_id:
/// - If is_enabled=1 and is_committee=1: CommitteeDashboardScreen
/// - If is_enabled=1 and is_committee=0: SocietyDashboardScreen
/// - If is_enabled=0: ApprovalPendingScreen (Access Disabled)
/// - If not found: SocietyScreen (registration form)
class _SocietyTabRoot extends StatefulWidget {
  final String userRole;

  const _SocietyTabRoot({required this.userRole});

  @override
  State<_SocietyTabRoot> createState() => _SocietyTabRootState();
}

class _SocietyTabRootState extends State<_SocietyTabRoot> with WidgetsBindingObserver {
  bool _loading = true;
  bool _isMember = false;
  bool _isCommittee = false;
  bool _isEnabled = false;
  String? _secretaryName;
  String? _secretaryPhone;
  DateTime? _lastCheckTime;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial check
    if (widget.userRole != 'society') {
      _checkSocietyMember();

      // Start auto-refresh timer - every 10 seconds
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        print('⏰ Timer tick - auto-fetching from database');
        if (mounted) {
          _checkSocietyMember();
        }
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.userRole != 'society') {
        print('🔄 App resumed - rechecking society member status');
        _checkSocietyMember();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    print('🛑 Disposed _SocietyTabRoot - timer cancelled');
    super.dispose();
  }

  Future<void> _checkSocietyMember() async {
    print('\n📡 ═══ _checkSocietyMember() CALLED ═══');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      print('   📍 userId: $userId, mounted: $mounted');

      if (userId == null || userId <= 0) {
        print('⚠️ userId not found in SharedPreferences');
        setState(() => _loading = false);
        return;
      }

      final url = 'https://digitrixmedia.com/mahamaintainpro/api/check-society-member.php?user_id=$userId';
      print('📡 Calling API: $url');

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 20));

      print('📊 API Response: statusCode=${response.statusCode}, body=${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Success: $data');

        if (data['success'] == true && data['exists'] == true) {
          final member = data['member'];
          print('🎉 Member found! is_committee=${member['is_committee']}, is_enabled=${member['is_enabled']}');

          // Fetch secretary details
          try {
            final secretaryUrl = 'https://digitrixmedia.com/mahamaintainpro/api/get-secretary-details.php?user_id=$userId';
            print('📡 Fetching secretary details from: $secretaryUrl');

            final secretaryResponse = await http.get(Uri.parse(secretaryUrl)).timeout(const Duration(seconds: 20));

            if (!mounted) return;

            if (secretaryResponse.statusCode == 200) {
              final secretaryData = jsonDecode(secretaryResponse.body);
              if (secretaryData['success'] == true && secretaryData['exists'] == true) {
                final secretary = secretaryData['secretary'];
                print('📋 Secretary details found: ${secretary['name']}, ${secretary['phone']}');

                final isCommitteeValue = member['is_committee'];
                final isEnabledValue = member['is_enabled'];

                print('🔍 Raw values: is_committee=$isCommitteeValue (type: ${isCommitteeValue.runtimeType}), is_enabled=$isEnabledValue (type: ${isEnabledValue.runtimeType})');

                if (!mounted) return;
                setState(() {
                  _isMember = true;
                  _isCommittee = (isCommitteeValue == 1 || isCommitteeValue == '1' || isCommitteeValue == true);
                  _isEnabled = (isEnabledValue == 1 || isEnabledValue == '1' || isEnabledValue == true);
                  _secretaryName = secretary['name'];
                  _secretaryPhone = secretary['phone'];

                  print('✅ Parsed values: is_committee=$_isCommittee, is_enabled=$_isEnabled');
                });
              } else {
                if (!mounted) return;
                setState(() {
                  _isMember = true;
                  _isCommittee = member['is_committee'] == 1;
                  _isEnabled = member['is_enabled'] == 1;
                  _secretaryName = null;
                  _secretaryPhone = null;
                });
              }
            }
          } catch (e) {
            print('⚠️ Error fetching secretary details: $e');
            if (!mounted) return;
            setState(() {
              _isMember = true;
              _isCommittee = member['is_committee'] == 1;
              _isEnabled = member['is_enabled'] == 1;
              _secretaryName = null;
              _secretaryPhone = null;
            });
          }
        } else {
          print('⚠️ Not a society member');
          setState(() {
            _isMember = false;
            _isCommittee = false;
            _isEnabled = false;
            _secretaryName = null;
            _secretaryPhone = null;
          });
        }
      } else {
        print('❌ API Error: statusCode=${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error checking society member: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('\n🏗️ BUILD - _loading=$_loading, _isMember=$_isMember, userRole=${widget.userRole}');

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // For society role users, always show full dashboard
    if (widget.userRole == 'society') {
      return const SocietyDashboardScreen();
    }

    // For individual users, check membership
    if (_isMember) {
      if (_isEnabled) {
        // Member with access
        if (_isCommittee) {
          print('🏛️ Showing CommitteeDashboardScreen (is_committee=true, is_enabled=true)');
          return CommitteeDashboardScreen(onLogout: () {});
        } else {
          print('👤 Showing SocietyDashboardScreen (is_committee=false, is_enabled=true)');
          return const SocietyDashboardScreen();
        }
      } else {
        // Member but access disabled - show pending with secretary details
        print('⏳ Showing ApprovalPendingScreen (is_enabled=false)');
        return ApprovalPendingScreen(
          secretaryName: _secretaryName ?? 'Society Secretary',
          secretaryPhone: _secretaryPhone ?? 'Pending approval',
          onRetry: () async {
            setState(() => _loading = true);
            await Future.delayed(const Duration(milliseconds: 300));
            _checkSocietyMember();
          },
        );
      }
    }

    // Not a member, show registration form
    return SocietyScreen(
      onRegistrationSuccess: () async {
        print('📝 Form submitted! Refreshing membership check...');
        setState(() => _loading = true);
        await Future.delayed(const Duration(milliseconds: 500));
        _checkSocietyMember();
      },
    );
  }
}

/// Individual user dashboard screen - completely independent from society dashboard.
/// This screen manages its own state and navigation independently.
///
/// Each bottom-nav tab owns its own nested [Navigator], so pushing a screen
/// from within a tab (Visitor Gate, Parking, a booking detail, etc.) stays
/// inside that tab's stack instead of covering the whole dashboard - the
/// bottom nav bar stays visible no matter how deep the user navigates.
class IndividualDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userRole;

  const IndividualDashboardScreen({
    required this.onLogout,
    this.userRole = 'individual',
    Key? key,
  }) : super(key: key);

  @override
  State<IndividualDashboardScreen> createState() => _IndividualDashboardScreenState();
}

class _IndividualDashboardScreenState extends State<IndividualDashboardScreen> {
  static const int _tabCount = 6;

  int _selectedTab = 0;
  late final List<Widget> _screens;
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(_tabCount, (_) => GlobalKey<NavigatorState>());
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    print('👤 User Role in IndividualDashboard: ${widget.userRole}');
    DashboardTabController.register((index) => setState(() => _selectedTab = index));
    _screens = [
      IndividualHomeScreen(                       // Tab 0: Home
        onNavigateToTab: (index) => setState(() => _selectedTab = index),
        userRole: widget.userRole,
      ),
      const SearchListScreen(),                   // Tab 1: Search
      const AiChatScreen(),                        // Tab 2: AI Chat
      _SocietyTabRoot(userRole: widget.userRole),   // Tab 3: Society
      const BookingsScreen(),                      // Tab 4: Bookings
      const ProfileScreen(),                        // Tab 5: Profile
    ];
  }

  @override
  void dispose() {
    DashboardTabController.unregister();
    super.dispose();
  }

  Future<bool> _handleBackButton() async {
    // If on home page (tab 0), check double-tap to exit
    if (_selectedTab == 0) {
      final now = DateTime.now();
      if (_lastBackPressTime != null &&
          now.difference(_lastBackPressTime!) < const Duration(seconds: 2)) {
        // Double tap within 2 seconds - exit app
        print('🚪 Double back tap - Exiting app');
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        }
        return false;
      }

      // First tap - show snackbar
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
      return false;
    }

    // If not on home, always navigate directly to home page (Tab 0)
    // Ignore any internal navigation stack
    print('🏠 Back button - Navigating to home');
    setState(() {
      _selectedTab = 0;
    });
    return false;
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          MaterialPageRoute(
            builder: (context) => _screens[index],
          ),
        ];
      },
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => _screens[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: List.generate(_tabCount, _buildTabNavigator),
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: _selectedTab,
          onNavItemTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          userRole: 'individual',
        ),
      ),
    );
  }
}
