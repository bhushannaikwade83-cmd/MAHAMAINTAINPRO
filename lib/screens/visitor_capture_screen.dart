import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

/// The security guard's core screen: capture a photo of a guest/delivery
/// person, note which flat they're visiting, and log the entry.
///
/// Writes into the same 'visitors' SharedPreferences key that
/// VisitorGateScreen reads, so the entry appears there too.
///
/// NOTE: this is local-only right now (same device as the guard). A
/// resident on a different phone won't see this entry until the app has a
/// shared backend (Supabase table) wired up for visitor entries.
class VisitorCaptureScreen extends StatefulWidget {
  final String guardName;
  final String gate;

  const VisitorCaptureScreen({
    required this.guardName,
    required this.gate,
    Key? key,
  }) : super(key: key);

  @override
  State<VisitorCaptureScreen> createState() => _VisitorCaptureScreenState();
}

class _VisitorCaptureScreenState extends State<VisitorCaptureScreen> {
  final _flatController = TextEditingController();
  final _nameController = TextEditingController();
  Uint8List? _photoBytes;
  String _purpose = 'Guest';
  bool _saving = false;

  static const _purposes = ['Guest', 'Delivery', 'Cab/Auto', 'Service', 'Other'];

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Capture Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppTheme.saffron),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.saffron),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a photo first')),
      );
      return;
    }
    if (_flatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the flat number')),
      );
      return;
    }

    setState(() => _saving = true);

    final prefs = await SharedPreferences.getInstance();
    final visitors = prefs.getStringList('visitors') ?? [];
    visitors.add(jsonEncode({
      'name': _nameController.text.trim().isEmpty ? _purpose : _nameController.text.trim(),
      'phone': '',
      'purpose': _purpose,
      'flatNo': _flatController.text.trim(),
      'photoBase64': base64Encode(_photoBytes!),
      'guardName': widget.guardName,
      'gate': widget.gate,
      'status': 'pending', // awaiting the resident's approve/deny
      'timestamp': DateTime.now().toString(),
    }));
    await prefs.setStringList('visitors', visitors);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _photoBytes = null;
      _flatController.clear();
      _nameController.clear();
      _purpose = 'Guest';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Visitor logged'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _flatController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log a Visitor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.gate} • ${widget.guardName}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              // Photo capture
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_photoBytes!, fit: BoxFit.cover),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Retake',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, size: 48, color: AppTheme.saffron),
                            const SizedBox(height: 8),
                            Text('Tap to capture visitor photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Visitor Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _purposes.map((p) {
                  final isSelected = _purpose == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _purpose = p),
                    selectedColor: AppTheme.saffron,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text('Flat Number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _flatController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: 'e.g., A-204',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Text('Visitor Name (optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: 'e.g., Swiggy Delivery',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
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
                          'Log Visitor Entry',
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
