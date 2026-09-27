import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';
import 'visitor_capture_screen.dart';

/// Dashboard shell for the Security Guard role. First run collects the
/// guard's name and which gate they're posted at; after that, a simple
/// 3-tab shell: Capture (log a visitor), Gate Log (recent entries),
/// Profile (edit name/gate, logout).
class SecurityGuardDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SecurityGuardDashboardScreen({required this.onLogout, Key? key}) : super(key: key);

  @override
  State<SecurityGuardDashboardScreen> createState() => _SecurityGuardDashboardScreenState();
}

class _SecurityGuardDashboardScreenState extends State<SecurityGuardDashboardScreen> {
  bool _loaded = false;
  String? _guardName;
  String? _gate;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadGuardInfo();
  }

  Future<void> _loadGuardInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _guardName = prefs.getString('guard_name');
      _gate = prefs.getString('guard_gate');
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_guardName == null || _guardName!.isEmpty || _gate == null || _gate!.isEmpty) {
      return _GuardSetupScreen(onSaved: _loadGuardInfo);
    }

    final tabs = [
      VisitorCaptureScreen(guardName: _guardName!, gate: _gate!),
      _GateLogScreen(guardName: _guardName!),
      _GuardProfileScreen(
        guardName: _guardName!,
        gate: _gate!,
        onEdit: _loadGuardInfo,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        elevation: 0,
        title: Text('🛡️ $_gate'),
        centerTitle: false,
      ),
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _selectedTab,
        onNavItemTap: (index) => setState(() => _selectedTab = index),
        userRole: 'guard',
      ),
    );
  }
}

class _GuardSetupScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const _GuardSetupScreen({required this.onSaved});

  @override
  State<_GuardSetupScreen> createState() => _GuardSetupScreenState();
}

class _GuardSetupScreenState extends State<_GuardSetupScreen> {
  final _nameController = TextEditingController();
  final _gateController = TextEditingController();
  bool _saving = false;

  static const _suggestedGates = ['Main Gate', 'Gate A', 'Gate B', 'Service Gate', 'Rear Gate'];

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _gateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and gate')),
      );
      return;
    }

    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guard_name', _nameController.text.trim());
    await prefs.setString('guard_gate', _gateController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('🛡️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'Welcome, Security Guard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Set up your posting once, then start logging visitors.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),

              Text('Your Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: 'e.g., Ramesh Yadav',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Text('Which Gate Are You Posted At?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _gateController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: 'e.g., Main Gate',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.door_front_door_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedGates.map((g) {
                  return ActionChip(
                    label: Text(g, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.white,
                    onPressed: () => setState(() => _gateController.text = g),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Start Duty',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateLogScreen extends StatelessWidget {
  final String guardName;

  const _GateLogScreen({required this.guardName});

  Future<List<dynamic>> _loadVisitors() async {
    final prefs = await SharedPreferences.getInstance();
    final visitors = prefs.getStringList('visitors') ?? [];
    return visitors.reversed.map((item) => jsonDecode(item)).toList();
  }

  String _formatTime(String? timestamp) {
    final date = DateTime.tryParse(timestamp ?? '');
    if (date == null) return '';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF3ED),
      child: FutureBuilder<List<dynamic>>(
        future: _loadVisitors(),
        builder: (context, snapshot) {
          final visitors = snapshot.data ?? [];
          if (visitors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No visitor entries yet', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final v = visitors[index];
              final photoBase64 = v['photoBase64'] as String?;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: photoBase64 != null
                            ? Image.memory(base64Decode(photoBase64), width: 48, height: 48, fit: BoxFit.cover)
                            : Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person_outline, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['name'] ?? 'Visitor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${v['purpose'] ?? ''}${v['flatNo'] != null ? ' • Flat ${v['flatNo']}' : ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(_formatTime(v['timestamp']), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GuardProfileScreen extends StatelessWidget {
  final String guardName;
  final String gate;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _GuardProfileScreen({
    required this.guardName,
    required this.gate,
    required this.onEdit,
    required this.onLogout,
  });

  Future<void> _editPosting(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guard_name');
    await prefs.remove('guard_gate');
    onEdit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF3ED),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.saffron.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 40))),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(guardName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Posted at $gate', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _editPosting(context),
              icon: const Icon(Icons.edit_outlined, color: AppTheme.saffron),
              label: const Text('Edit Name / Gate', style: TextStyle(color: AppTheme.saffron, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.saffron)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
