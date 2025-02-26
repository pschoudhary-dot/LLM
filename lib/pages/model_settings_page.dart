import 'package:flutter/material.dart';
import '../services/model_service.dart';
import '../component/model_config_dialog.dart';
import '../component/model_list_item.dart';

class ModelSettingsPage extends StatefulWidget {
  const ModelSettingsPage({Key? key}) : super(key: key);

  @override
  _ModelSettingsPageState createState() => _ModelSettingsPageState();
}

class _ModelSettingsPageState extends State<ModelSettingsPage> {
  List<ModelConfig> _modelConfigs = [];
  String? _selectedModelId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModelConfigs();
  }

  Future<void> _loadModelConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await ModelService.getModelConfigs();
      final selectedId = await ModelService.getSelectedModel();

      setState(() {
        _modelConfigs = configs;
        _selectedModelId = selectedId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load model configurations: $e')),
      );
    }
  }

  void _addNewModel() {
    showDialog(
      context: context,
      builder: (context) => ModelConfigDialog(
        onSave: (config) async {
          await ModelService.saveModelConfig(config);
          
          // If this is the first model, set it as selected
          if (_modelConfigs.isEmpty) {
            await ModelService.setSelectedModel(config.id);
          }
          
          _loadModelConfigs();
        },
      ),
    );
  }

  void _editModel(ModelConfig config) async {
    await ModelService.saveModelConfig(config);
    _loadModelConfigs();
  }

  void _deleteModel(String id) async {
    await ModelService.deleteModelConfig(id);
    
    // If the deleted model was selected, select another one if available
    if (_selectedModelId == id && _modelConfigs.isNotEmpty) {
      final remainingConfigs = _modelConfigs.where((c) => c.id != id).toList();
      if (remainingConfigs.isNotEmpty) {
        await ModelService.setSelectedModel(remainingConfigs.first.id);
      } else {
        // If no models remain, we can't set a selected model
        // We'll handle this in the ModelService
        await ModelService.clearSelectedModel();
      }
    }
    
    _loadModelConfigs();
  }

  void _selectModel(String id) async {
    await ModelService.setSelectedModel(id);
    setState(() {
      _selectedModelId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Model Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFF8B5CF6), size: 28),
            onPressed: _addNewModel,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _modelConfigs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _modelConfigs.length,
                  itemBuilder: (context, index) {
                    final model = _modelConfigs[index];
                    return ModelListItem(
                      model: model,
                      isSelected: model.id == _selectedModelId,
                      onDelete: () => _deleteModel(model.id),
                      onEdit: _editModel,
                      onSelect: () => _selectModel(model.id),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Models Configured',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a model to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewModel,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Model',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 