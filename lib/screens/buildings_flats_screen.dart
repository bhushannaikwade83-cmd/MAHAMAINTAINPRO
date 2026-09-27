import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_theme.dart';
import '../repositories/auth_repository.dart';

const String _apiBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';

class BuildingsFlatsScreen extends StatefulWidget {
  const BuildingsFlatsScreen({Key? key}) : super(key: key);

  @override
  State<BuildingsFlatsScreen> createState() => _BuildingsFlatsScreenState();
}

class _BuildingsFlatsScreenState extends State<BuildingsFlatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _buildingNameController = TextEditingController();
  final _buildingWingController = TextEditingController();
  final _flatNumberController = TextEditingController();
  int? _selectedBuildingId;
  bool _isSaving = false;
  List<dynamic> _buildings = [];
  List<dynamic> _flats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  Future<int> _societyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('societyId') ?? 1;
  }

  Future<void> _refresh() async {
    final societyId = await _societyId();
    try {
      final buildingsResp = await http.get(
        Uri.parse('$_apiBaseUrl/get-buildings.php?society_id=$societyId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));
      final flatsResp = await http.get(
        Uri.parse('$_apiBaseUrl/get-flats.php?society_id=$societyId'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      ).timeout(const Duration(seconds: 10));

      List<dynamic> buildings = [];
      List<dynamic> flats = [];
      final buildingsData = jsonDecode(buildingsResp.body);
      if (buildingsData['success'] == true) buildings = buildingsData['buildings'];
      final flatsData = jsonDecode(flatsResp.body);
      if (flatsData['success'] == true) flats = flatsData['flats'];

      if (mounted) {
        setState(() {
          _buildings = buildings;
          _flats = flats;
        });
      }
    } catch (e) {
      // Silent fail - sections just stay empty
    }
  }

  Future<void> _addBuilding() async {
    if (_buildingNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Building/Wing name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final societyId = await _societyId();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/add-building.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'name': _buildingNameController.text.trim(),
          if (_buildingWingController.text.trim().isNotEmpty) 'wing': _buildingWingController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to add building');
      }

      _buildingNameController.clear();
      _buildingWingController.clear();
      await _refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Building added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addFlat() async {
    if (_flatNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flat number is required')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final societyId = await _societyId();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/add-flat.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'society_id': societyId,
          'flat_number': _flatNumberController.text.trim(),
          if (_selectedBuildingId != null) 'building_id': _selectedBuildingId,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to add flat');
      }

      _flatNumberController.clear();
      await _refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flat added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleOccupancy(Map<String, dynamic> flat) async {
    final societyId = await _societyId();
    final newStatus = flat['occupancy_status'] == 'occupied' ? 'vacant' : 'occupied';
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/update-flat.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({'id': flat['id'], 'society_id': societyId, 'occupancy_status': newStatus}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to update flat');
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buildingNameController.dispose();
    _buildingWingController.dispose();
    _flatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('🏢 Buildings & Flats'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Buildings/Wings'),
            Tab(text: 'Flats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuildingsTab(),
          _buildFlatsTab(),
        ],
      ),
    );
  }

  Widget _buildBuildingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Building / Wing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _buildingNameController,
                    decoration: InputDecoration(
                      labelText: 'Building Name',
                      hintText: 'e.g., Building A',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _buildingWingController,
                    decoration: InputDecoration(
                      labelText: 'Wing (optional)',
                      hintText: 'e.g., Wing 1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _addBuilding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Add Building', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('All Buildings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_buildings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No buildings added yet')),
            )
          else
            ..._buildings.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.apartment, color: Colors.blue),
                    title: Text(b['name'] ?? ''),
                    subtitle: Text([
                      if (b['wing'] != null) 'Wing: ${b['wing']}',
                      if (b['total_floors'] != null) '${b['total_floors']} floors',
                    ].join(' • ')),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildFlatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Flat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _flatNumberController,
                    decoration: InputDecoration(
                      labelText: 'Flat Number',
                      hintText: 'e.g., A-101',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedBuildingId,
                    decoration: InputDecoration(
                      labelText: 'Building (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _buildings
                        .map((b) => DropdownMenuItem<int>(value: b['id'], child: Text(b['name'] ?? '')))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBuildingId = value),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _addFlat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saffron,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Add Flat', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('All Flats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_flats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No flats added yet')),
            )
          else
            ..._flats.map((f) {
              final occupied = f['occupancy_status'] == 'occupied';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.door_front_door, color: occupied ? Colors.green : Colors.orange),
                  title: Text(f['flat_number'] ?? ''),
                  subtitle: Text([
                    if (f['building_name'] != null) f['building_name'],
                    if (f['owner_name'] != null) 'Owner: ${f['owner_name']}',
                    if (f['tenant_name'] != null) 'Tenant: ${f['tenant_name']}',
                  ].join(' • ')),
                  trailing: TextButton(
                    onPressed: () => _toggleOccupancy(f),
                    child: Text(occupied ? 'Occupied' : 'Vacant'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
