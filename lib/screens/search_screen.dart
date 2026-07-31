import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.saffron,
        title: const Text('Search Services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services, society issues...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchItem('⚡ Insta Help', '46 min available'),
                _buildSearchItem('🧹 Cleaning Service', '52 min available'),
                _buildSearchItem('🔧 Electrical Repair', '1 hour available'),
                _buildSearchItem('💆 Salon Services', '2 hours available'),
                _buildSearchItem('🚗 Vehicle Care', '3 hours available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchItem(String title, String subtitle) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.search, color: AppTheme.saffron),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {},
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
