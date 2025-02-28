import 'package:flutter/material.dart';
import 'ollama_model.dart';

class ModelParameterDialog extends StatefulWidget {
  final OllamaModel model;
  final Function(String, String) onInstall;

  const ModelParameterDialog({
    Key? key,
    required this.model,
    required this.onInstall,
  }) : super(key: key);

  @override
  _ModelParameterDialogState createState() => _ModelParameterDialogState();
}

class _ModelParameterDialogState extends State<ModelParameterDialog> {
  String? _selectedParameter;

  @override
  void initState() {
    super.initState();
    if (widget.model.parameters.isNotEmpty) {
      _selectedParameter = widget.model.parameters.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Install ${widget.model.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select parameter size:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.model.parameters.isEmpty)
            const Text('No parameters available for this model')
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedParameter,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(8),
                  items: widget.model.parameters
                      .where((param) => param.contains('b') || param.contains('m'))
                      .map((param) {
                    return DropdownMenuItem<String>(
                      value: param,
                      child: Text(param),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedParameter = value;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Command to run:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'ollama pull ${widget.model.name}${_selectedParameter != null ? ":$_selectedParameter" : ""}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onInstall(
              widget.model.name,
              _selectedParameter != null ? "${widget.model.name}:$_selectedParameter" : widget.model.name,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Install'),
        ),
      ],
    );
  }
}
