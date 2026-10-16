import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  String _selectedMode = 'grammar';
  String _selectedTone = 'neutral';
  bool _isLoading = false;
  String? _errorMessage;
  bool _copied = false;

  final List<Map<String, String>> _modes = const [
    {'id': 'grammar', 'label': 'Grammar & Fix'},
    {'id': 'paraphrase', 'label': 'Paraphrase'},
    {'id': 'professional', 'label': 'Professional'},
    {'id': 'casual', 'label': 'Casual'},
    {'id': 'concise', 'label': 'Concise'},
    {'id': 'clarity', 'label': 'Clarity'},
  ];

  Future<void> _refine() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter text to refine.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.refineText(
        text: text,
        mode: _selectedMode,
        tone: _selectedTone,
      );
      setState(() {
        _outputController.text = res['refinedText'] ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyOutput() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SAYN Workspace',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _modes.map((m) {
                  final isSelected = _selectedMode == m['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m['label']!),
                      selected: isSelected,
                      selectedColor: SaynColors.darkAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : SaynColors.darkSecondary,
                      ),
                      backgroundColor: SaynColors.darkSurface,
                      side: const BorderSide(color: SaynColors.darkDivider),
                      onSelected: (val) {
                        if (val) setState(() => _selectedMode = m['id']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Source Input Card
            Container(
              decoration: BoxDecoration(
                color: SaynColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SaynColors.darkDivider),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Source Text',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SaynColors.darkSecondary,
                          ),
                        ),
                        if (_inputController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: SaynColors.darkSecondary,
                            onPressed: () {
                              _inputController.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, color: SaynColors.darkText),
                    decoration: const InputDecoration(
                      hintText: 'Type or dictate rough thoughts here...',
                      hintStyle: TextStyle(fontSize: 14, color: SaynColors.darkMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Refine Button
            ElevatedButton(
              onPressed: _isLoading ? null : _refine,
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.darkAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Refine Text',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Error Display
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: SaynColors.darkError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SaynColors.darkError.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: SaynColors.darkError, fontSize: 12),
                ),
              ),

            // Output Card
            if (_outputController.text.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: SaynColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SaynColors.darkDivider),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Refined Output',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SaynColors.darkAccent,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _copyOutput,
                            icon: Icon(
                              _copied ? Icons.check : Icons.copy,
                              size: 16,
                              color: _copied ? SaynColors.darkSuccess : SaynColors.darkSecondary,
                            ),
                            label: Text(
                              _copied ? 'Copied' : 'Copy',
                              style: TextStyle(
                                fontSize: 12,
                                color: _copied ? SaynColors.darkSuccess : SaynColors.darkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    TextField(
                      controller: _outputController,
                      readOnly: true,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14, color: SaynColors.darkText),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
