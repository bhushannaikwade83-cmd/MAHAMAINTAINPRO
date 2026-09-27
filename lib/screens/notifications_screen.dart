import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _apiBase = 'https://digitrixmedia.com/mahamaintainpro/api';

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(
            Uri.parse('$_apiBase/get-notifications.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Could not load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) _notifications[index]['is_read'] = true;
    });
    try {
      await http.post(
        Uri.parse('$_apiBase/mark-notifications-read.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({'id': id}),
      );
    } catch (_) {
      // Local state already updated; a background retry isn't critical here.
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _notifications) {
        n['is_read'] = true;
      }
    });
    try {
      await http.post(
        Uri.parse('$_apiBase/mark-notifications-read.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({}),
      );
    } catch (_) {}
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'order':
        return Icons.local_shipping_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => n['is_read'] != true);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade600))),
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: _loadNotifications, child: const Text('Retry')),
          ),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final isRead = notif['is_read'] == true;
        return ListTile(
          onTap: () {
            if (!isRead) _markAsRead(notif['id'] as int);
          },
          leading: CircleAvatar(
            backgroundColor: isRead ? Colors.grey.shade200 : AppTheme.saffron.withOpacity(0.15),
            child: Icon(
              _iconForType(notif['type'] as String?),
              color: isRead ? Colors.grey.shade500 : AppTheme.saffron,
              size: 20,
            ),
          ),
          title: Text(
            notif['title'] ?? '',
            style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700),
          ),
          subtitle: Text(notif['body'] ?? ''),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(notif['created_at'] as String?),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (!isRead) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: AppTheme.saffron, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
