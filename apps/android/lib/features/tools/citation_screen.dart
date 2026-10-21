import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';

class CitationScreen extends StatefulWidget {
  final String? initialSource;

  const CitationScreen({super.key, this.initialSource});

  @override
  State<CitationScreen> createState() => _CitationScreenState();
}

class _CitationScreenState extends State<CitationScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  String _selectedStyle = 'apa'; // 'apa' | 'mla' | 'chicago' | 'harvard'
  bool _isGenerating = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;
  bool _copiedFull = false;
  bool _copiedInText = false;

  final List<Map<String, String>> _styles = const [
    {'id': 'apa', 'label': 'APA 7th'},
    {'id': 'mla', 'label': 'MLA 9th'},
    {'id': 'chicago', 'label': 'Chicago'},
    {'id': 'harvard', 'label': 'Harvard'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSource != null && widget.initialSource!.isNotEmpty) {
      _sourceController.text = widget.initialSource!;
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _sourceController.text = data.text!;
      });
    }
  }

  Future<void> _generateCitation() async {
    final source = _sourceController.text.trim();
    if (source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL, book title, or research source.'),
          backgroundColor: SaynColors.wineMaroon,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _copiedFull = false;
      _copiedInText = false;
    });

    try {
      final res = await _apiClient.generateCitation(
        sourceTextOrUrl: source,
        style: _selectedStyle,
      );
      if (mounted) {
        setState(() {
          _result = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaynColors.paperBg,
      appBar: AppBar(
        backgroundColor: SaynColors.paperBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SaynColors.wineMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Citation Generator',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: SaynColors.wineMaroon,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Style Selection Tabs
            Row(
              children: _styles.map((st) {
                final isSelected = _selectedStyle == st['id'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedStyle = st['id']!);
                        if (_result != null && _sourceController.text.isNotEmpty) {
                          _generateCitation();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? SaynColors.wineMaroon : SaynColors.paperCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? SaynColors.wineMaroon : SaynColors.paperBorder,
                            width: 1.1,
                          ),
                        ),
                        child: Text(
                          st['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : SaynColors.wineMaroon,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 2. Source Input Card
            Container(
              decoration: BoxDecoration(
                color: SaynColors.paperCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SaynColors.paperBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBECE6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.paste_rounded, size: 13, color: SaynColors.wineMaroon),
                                SizedBox(width: 5),
                                Text(
                                  'Paste link',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: SaynColors.wineMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _sourceController.clear();
                            setState(() => _result = null);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: SaynColors.wineMaroon,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: SaynColors.paperBorder),
                  TextField(
                    controller: _sourceController,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(fontSize: 14.5, color: SaynColors.paperText, height: 1.45),
                    decoration: const InputDecoration(
                      hintText: 'Enter website URL, book title, author, or research paper...',
                      hintStyle: TextStyle(fontSize: 13.5, color: SaynColors.paperTextMuted),
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateCitation,
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.wineMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_quote_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Generate Citation',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFC92A2A), fontSize: 13),
                ),
              ),
            ],

            // 3. Formatted Citation Output
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildCitationOutput(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCitationOutput(Map<String, dynamic> res) {
    final fullCitation = res['fullCitation'] as String? ?? '';
    final inTextCitation = res['inTextCitation'] as String? ?? '';
    final meta = res['metadata'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bibliography Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SaynColors.paperCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SaynColors.paperBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Full Reference (${_selectedStyle.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: fullCitation));
                      HapticFeedback.lightImpact();
                      setState(() => _copiedFull = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copiedFull = false);
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _copiedFull ? const Color(0xFF2B8A3E) : const Color(0xFFFBECE6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _copiedFull ? Icons.check_rounded : Icons.copy_rounded,
                            size: 13,
                            color: _copiedFull ? Colors.white : SaynColors.wineMaroon,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _copiedFull ? 'Copied' : 'Copy',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _copiedFull ? Colors.white : SaynColors.wineMaroon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                fullCitation,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14.5,
                  color: SaynColors.paperText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // In-Text Citation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SaynColors.paperCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SaynColors.paperBorder, width: 1.1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'In-Text Citation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SaynColors.paperTextMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      inTextCitation,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: SaynColors.wineMaroon,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: inTextCitation));
                  HapticFeedback.lightImpact();
                  setState(() => _copiedInText = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedInText = false);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _copiedInText ? const Color(0xFF2B8A3E) : const Color(0xFFFBECE6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _copiedInText ? Icons.check_rounded : Icons.copy_rounded,
                        size: 13,
                        color: _copiedInText ? Colors.white : SaynColors.wineMaroon,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copiedInText ? 'Copied' : 'Copy',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _copiedInText ? Colors.white : SaynColors.wineMaroon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Metadata breakdown
        if (meta['title'] != null || meta['year'] != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SaynColors.paperSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted Metadata',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SaynColors.wineMaroon,
                  ),
                ),
                const SizedBox(height: 6),
                if (meta['title'] != null)
                  Text('• Title: ${meta['title']}',
                      style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted)),
                if (meta['year'] != null)
                  Text('• Year: ${meta['year']}',
                      style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted)),
                if (meta['publisherOrSite'] != null)
                  Text('• Publisher / Source: ${meta['publisherOrSite']}',
                      style: const TextStyle(fontSize: 12, color: SaynColors.paperTextMuted)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
