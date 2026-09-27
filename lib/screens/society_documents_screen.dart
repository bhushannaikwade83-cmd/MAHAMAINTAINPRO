import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class SocietyDocumentsScreen extends StatefulWidget {
  final bool isCommittee;

  const SocietyDocumentsScreen({this.isCommittee = false, Key? key}) : super(key: key);

  @override
  State<SocietyDocumentsScreen> createState() => _SocietyDocumentsScreenState();
}

class _SocietyDocumentsScreenState extends State<SocietyDocumentsScreen> {
  final _titleController = TextEditingController();
  PlatformFile? _pickedFile;
  List<dynamic> _documents = [];
  bool _loading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _societyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('societyId') ?? 1;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final societyId = await _societyId();
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/get-society-documents.php?society_id=$societyId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => _documents = data['documents']);
      }
    } catch (e) {
      // Silent fail - list just shows empty
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (files != null && files.isNotEmpty) {
      setState(() => _pickedFile = files.first);
    }
  }

  Future<void> _addDocument() async {
    if (_titleController.text.trim().isEmpty || _pickedFile == null || _pickedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and a file are required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final societyId = await _societyId();

      // Step 1: upload the real file
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/upload-society-document.php'),
      );
      final authToken = SupabaseAuthRepository.currentToken;
      if (authToken != null) {
        uploadRequest.headers['Authorization'] = 'Bearer $authToken';
      }
      uploadRequest.files.add(await http.MultipartFile.fromPath('document', _pickedFile!.path!));
      final uploadStreamed = await uploadRequest.send();
      final uploadResponse = await http.Response.fromStream(uploadStreamed);
      final uploadData = jsonDecode(uploadResponse.body);

      if (uploadResponse.statusCode != 200 || uploadData['success'] != true) {
        throw Exception(uploadData['error'] ?? 'Failed to upload file');
      }

      // Step 2: record it against the society
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/add-society-document.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'title': _titleController.text.trim(),
          'file_url': uploadData['url'],
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to add document');
      }

      _titleController.clear();
      setState(() => _pickedFile = null);
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('📄 Society Documents'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isCommittee) ...[
                const Text('Add Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Document Title',
                            hintText: 'e.g., Society Bye-laws',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file, color: AppTheme.saffron),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _pickedFile?.name ?? 'Choose a file (PDF, image, DOC)',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: _pickedFile != null ? Colors.black87 : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _addDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.saffron,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('Add Document', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text('All Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No documents uploaded yet')),
                )
              else
                ..._documents.map((d) {
                  final createdAt = DateTime.tryParse(d['created_at'] ?? '');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(d['title'] ?? ''),
                      subtitle: createdAt != null ? Text(DateFormat('d MMM yyyy').format(createdAt)) : null,
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () async {
                        final url = d['file_url'] as String?;
                        if (url == null) return;
                        final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        if (!launched && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open document')),
                          );
                        }
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
