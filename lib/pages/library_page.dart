import 'package:flutter/material.dart';
import '../component/models.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/model_service.dart' as service;
import '../services/termux_service.dart';
import '../component/model_input_dialog.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin {
  String _filterText = '';
  String _selectedCategory = 'All Models';
  final List<String> _categories = ['All Models', 'Language', 'Image', 'Audio'];
  List<Map<String, dynamic>> _ollamaModels = [];
  List<Map<String, dynamic>> _downloadedModels = [];
  bool _isLoading = true;
  String _selectedSort = 'Latest';
  final List<String> _sortOptions = ['Latest', 'Name', 'Size', 'Downloads'];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    _fetchOllamaModels();
    _fetchDownloadedModels();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDownloadedModels() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:11434/api/tags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _downloadedModels = List<Map<String, dynamic>>.from(data['models'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching downloaded models: $e');
    }
  }

  Future<void> _fetchOllamaModels() async {
    setState(() => _isLoading = true);
    try {
      // Fetch models from Ollama library
      final response = await http.get(Uri.parse('https://ollama.com/api/library'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ollamaModels = List<Map<String, dynamic>>.from(data['models'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load models');
      }
    } catch (e) {
      print('Error fetching models: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _sortOptions.map((sort) => ChoiceChip(
                  label: Text(sort),
                  selected: _selectedSort == sort,
                  onSelected: (selected) {
                    if (selected) {
                      this.setState(() => _selectedSort = sort);
                      Navigator.pop(context);
                    }
                  },
                )).toList(),
              ),
              SizedBox(height: 20),
              Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _categories.map((category) => ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      this.setState(() => _selectedCategory = category);
                      Navigator.pop(context);
                    }
                  },
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstallOptions(Map<String, dynamic> model) {
    final List<String> parameters = ['7B', '13B', '34B', '70B'];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Model Parameters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: parameters.map((param) => ActionChip(
                label: Text(param),
                onPressed: () {
                  final modelName = '${model['name']}:$param';
                  Navigator.pop(context);
                  _installModel(modelName);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> model) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: 'Delete Model',
        description: 'Are you sure you want to delete ${model['name']}? This action cannot be undone.',
        onContinue: () async {
          Navigator.pop(context);
          try {
            await TermuxService.runCommand(
              context,
              'ollama rm ${model['name']}',
            );
            _fetchDownloadedModels();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Model deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting model: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _configureModel(Map<String, dynamic> model) async {
    try {
      final config = service.ModelConfig(
        id: model['name'],
        name: model['name'],
        provider: service.ModelProvider.ollama,
        baseUrl: 'http://localhost:11434',
      );
      await service.ModelService.saveModelConfig(config);
      await service.ModelService.setSelectedModel(config.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model configured successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error configuring model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _installModel(String modelName) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: 'Install Model',
        description: 'Do you want to install $modelName?',
        onContinue: () async {
          Navigator.pop(context);
          try {
            await TermuxService.runCommand(
              context,
              'ollama pull $modelName',
            );
            _fetchDownloadedModels();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Installing $modelName...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error installing model: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        title: Text(
          'Model Library',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController!,
          labelColor: Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Downloaded'),
            Tab(text: 'Available'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _fetchOllamaModels();
              _fetchDownloadedModels();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildDownloadedModelsTab(),
          _buildAvailableModelsTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadedModelsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: _buildSearchBar(),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _downloadedModels.length,
            itemBuilder: (context, index) {
              final model = _downloadedModels[index];
              if (_filterText.isNotEmpty &&
                  !model['name'].toString().toLowerCase().contains(_filterText.toLowerCase())) {
                return SizedBox.shrink();
              }
              return _buildDownloadedModelCard(model);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableModelsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: _buildSearchBar(),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: category == _selectedCategory,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _ollamaModels.length,
                  itemBuilder: (context, index) {
                    final model = _ollamaModels[index];
                    if (_filterText.isNotEmpty &&
                        !model['name'].toString().toLowerCase().contains(_filterText.toLowerCase())) {
                      return SizedBox.shrink();
                    }
                    return _buildAvailableModelCard(model);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
            onPressed: _showFilterOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedModelCard(Map<String, dynamic> model) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
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
                        model['name'].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Size: ${model['size'] ?? 'Unknown'}',
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
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _configureModel(model),
                    icon: Icon(Icons.settings),
                    label: Text('Configure'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF8B5CF6),
                      side: BorderSide(color: Color(0xFF8B5CF6)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(model),
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableModelCard(Map<String, dynamic> model) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
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
                        model['name'].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (model['category'] != null)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            model['category'].toString(),
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (model['description'] != null) ...[
              SizedBox(height: 12),
              Text(
                model['description'].toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
            if (model['parameters'] != null) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (model['parameters'] as List).map((param) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    param.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showInstallOptions(model),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}