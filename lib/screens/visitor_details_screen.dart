import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class VisitorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> visitor;
  final int index;
  final Function(int) onDelete;

  const VisitorDetailsScreen({
    required this.visitor,
    required this.index,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  late bool _isApproved;

  @override
  void initState() {
    super.initState();
    _isApproved = widget.visitor['status'] == 'Approved';
  }

  Future<void> _updateStatus() async {
    setState(() {
      _isApproved = !_isApproved;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_isApproved ? 'Approved' : 'Pending'}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('Visitor Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        widget.visitor['photoBase64'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(widget.visitor['photoBase64']),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.saffron.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: AppTheme.saffron,
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.visitor['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isApproved ? 'Approved ✓' : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isApproved ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.visitor['flatNo'] != null) ...[
                      _buildInfoRow('Flat', widget.visitor['flatNo'], Icons.home_outlined),
                      const SizedBox(height: 12),
                    ],
                    _buildInfoRow('Phone', widget.visitor['phone'] ?? 'N/A', Icons.phone),
                    const SizedBox(height: 12),
                    _buildInfoRow('Purpose', widget.visitor['purpose'] ?? 'N/A', Icons.info),
                    const SizedBox(height: 12),
                    if (widget.visitor['guardName'] != null) ...[
                      _buildInfoRow('Logged By', '${widget.visitor['guardName']} (${widget.visitor['gate'] ?? ''})', Icons.shield_outlined),
                      const SizedBox(height: 12),
                    ],
                    _buildInfoRow(
                      'Visit Date',
                      widget.visitor['timestamp'] != null
                          ? DateTime.parse(widget.visitor['timestamp']).toString().split('.')[0]
                          : 'N/A',
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isApproved ? Colors.orange : Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                _isApproved ? 'Mark as Pending' : 'Approve Visitor',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Visitor'),
                    content: const Text('Are you sure you want to delete this visitor record?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onDelete(widget.index);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Visitor deleted'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Delete Visitor',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.saffron, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
