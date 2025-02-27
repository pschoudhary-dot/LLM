import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/config_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../services/model_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String appName;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    required this.appName,
    required this.onSettingsPressed,
  });

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  List<ModelConfig> _modelConfigs = [];
  String? _selectedModelId;
  bool _isLoading = false;

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
      print('Failed to load model configurations: $e');
    }
  }

  void _selectModel(String id) async {
    await ModelService.setSelectedModel(id);
    setState(() {
      _selectedModelId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Find the selected model
    final selectedModel = _modelConfigs.isNotEmpty && _selectedModelId != null
        ? _modelConfigs.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _modelConfigs.first,
          )
        : null;

    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: InkWell(
                onTap: () {
                  _showModelSelector(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedModel != null ? selectedModel.name : 'PocketLLM',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.black87),
                  onPressed: () {
                    // Handle new chat
                    print('New Chat pressed');
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    if (_modelConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No models configured. Add models in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Model',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _modelConfigs.length,
                  itemBuilder: (context, index) {
                    final model = _modelConfigs[index];
                    final isSelected = model.id == _selectedModelId;
                    
                    return ListTile(
                      leading: _getProviderIcon(model.provider),
                      title: Text(
                        model.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(model.provider.displayName),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Color(0xFF8B5CF6))
                          : null,
                      onTap: () {
                        _selectModel(model.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6)),
                title: Text('Add New Model'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getProviderIcon(ModelProvider provider) {
    IconData iconData;
    Color iconColor;

    switch (provider) {
      case ModelProvider.ollama:
        iconData = Icons.terminal;
        iconColor = Colors.orange;
        break;
      case ModelProvider.openAI:
        iconData = Icons.auto_awesome;
        iconColor = Colors.green;
        break;
      case ModelProvider.anthropic:
        iconData = Icons.psychology;
        iconColor = Colors.purple;
        break;
      case ModelProvider.lmStudio:
        iconData = Icons.science;
        iconColor = Colors.blue;
        break;
      case ModelProvider.pocketLLM:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ModelProvider.mistral:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ModelProvider.deepseek:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  void _selectedMenuItem(BuildContext context, int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LibraryPage(),
          ),
        );
        break;
      case 1:
        print('Chat History selected');
        break;
      case 2:
        print('Docs selected');
        break;
      case 3:
        print('About selected');
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigPage(appName: widget.appName),
          ),
        );
        break;
    }
  }
}