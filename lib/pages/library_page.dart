import 'package:flutter/material.dart';
import '../component/models.dart';
import 'dart:ui';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _filterText = '';
  String _selectedCategory = 'All Models';
  final List<String> _categories = ['All Models', 'Language', 'Image', 'Audio'];

  Widget _buildModelCard(AIModel model) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade200, Colors.purple.shade400],
                    ),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.id,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        model.provider,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('Latest', Colors.blue),
                _buildTag('128K Context', Colors.purple),
                _buildTag('Fast', Colors.green),
              ],
            ),
            SizedBox(height: 12),
            Text(
              model.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Install'),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      Text('Configure'),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.search, color: Colors.grey[600], size: 20),
                                ),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search models...',
                                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) => setState(() => _filterText = value),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.tune, color: Colors.grey[600], size: 20),
                                  onPressed: () {
                                    // Handle filter options
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildCategoryChip('All Models', true),
                          SizedBox(width: 8),
                          _buildCategoryChip('Language', false),
                          SizedBox(width: 8),
                          _buildCategoryChip('Image', false),
                          SizedBox(width: 8),
                          _buildCategoryChip('Audio', false),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AIModel>>(
                future: ModelsRepository.getAvailableModels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading models'));
                  }
                  
                  final models = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) => _buildModelCard(models[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  
  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }