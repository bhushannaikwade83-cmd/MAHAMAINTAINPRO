import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';
import '../widgets/error_retry_view.dart';

/// Standalone directory of registered vendors, using the same
/// get-active-vendors.php backend the "Assign Vendor to Complaint" picker
/// already calls - previously there was no way to just browse vendors
/// without going through a complaint first.
class SocietyVendorsScreen extends StatefulWidget {
  const SocietyVendorsScreen({Key? key}) : super(key: key);

  @override
  State<SocietyVendorsScreen> createState() => _SocietyVendorsScreenState();
}

class _SocietyVendorsScreenState extends State<SocietyVendorsScreen> {
  List<dynamic> _vendors = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final response = await http
          .get(
            Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/get-active-vendors.php'),
            headers: SupabaseAuthRepository.staticAuthHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _vendors = data['vendors'] ?? [];
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _loading = false;
        _hasError = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('Vendors'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? ErrorRetryView(onRetry: _loadVendors)
              : _vendors.isEmpty
                  ? Center(
                      child: Text('No active vendors found', style: TextStyle(color: Colors.grey.shade600)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVendors,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final vendor = _vendors[index];
                          final rating = (vendor['rating'] as num?)?.toStringAsFixed(1);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.saffron.withOpacity(0.15),
                                  child: Icon(Icons.build_rounded, color: AppTheme.saffron),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(vendor['name'] ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(vendor['phone'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                if (rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                      const SizedBox(width: 2),
                                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
