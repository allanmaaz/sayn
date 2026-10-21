import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../services/document_reader_service.dart';

class AiDetectorScreen extends StatefulWidget {
  final String? initialText;

  const AiDetectorScreen({super.key, this.initialText});

  @override
  State<AiDetectorScreen> createState() => _AiDetectorScreenState();
}

class _AiDetectorScreenState extends State<AiDetectorScreen> {
  final TextEditingController _textController = TextEditingController();
  final SaynApiClient _apiClient = SaynApiClient();

  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  // Document upload state
  bool _isExtractingDoc = false;
  ExtractedDocumentResult? _currentDocument;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _textController.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _textController.text = data.text!;
      });
    }
  }

  Future<void> _uploadDocument() async {
    setState(() => _isExtractingDoc = true);
    try {
      final result = await DocumentReaderService.instance.pickAndExtractDocument();
      if (result != null && mounted) {
        setState(() {
          _currentDocument = result;
          _textController.text = result.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${result.fileName} (${result.wordCount} words, ${result.pageCount} page${result.pageCount > 1 ? 's' : ''})'),
            duration: const Duration(seconds: 2),
            backgroundColor: SaynColors.wineMaroon,
          ),
        );
        // Automatically start scanning the extracted document
        if (result.text.trim().isNotEmpty) {
          _runDetection();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFC92A2A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExtractingDoc = false);
      }
    }
  }

  Future<void> _runDetection() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste text to scan for AI content.'),
          backgroundColor: SaynColors.wineMaroon,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.detectAi(text);
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
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'likely_ai':
        return const Color(0xFFC92A2A);
      case 'mixed_or_uncertain':
        return const Color(0xFFD97706);
      case 'likely_human':
      default:
        return const Color(0xFF2B8A3E);
    }
  }

  String _getVerdictLabel(String verdict) {
    switch (verdict) {
      case 'likely_ai':
        return 'Likely AI-Generated';
      case 'mixed_or_uncertain':
        return 'Mixed Signals / Uncertain';
      case 'likely_human':
      default:
        return 'Likely Human-Written';
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
          'AI Content Detector',
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
            // 1. Text Input Card
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
                                  'Paste text',
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
                        const SizedBox(width: 8),
                        // Upload Doc button
                        InkWell(
                          onTap: _isExtractingDoc ? null : _uploadDocument,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBECE6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isExtractingDoc)
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SaynColors.wineMaroon,
                                    ),
                                  )
                                else
                                  const Icon(Icons.upload_file_rounded, size: 13, color: SaynColors.wineMaroon),
                                const SizedBox(width: 5),
                                const Text(
                                  'Upload Doc',
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
                            _textController.clear();
                            setState(() {
                              _result = null;
                              _currentDocument = null;
                            });
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

                  // Optional Document pill banner if loaded
                  if (_currentDocument != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: SaynColors.warmCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SaynColors.paperBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_rounded, size: 14, color: SaynColors.wineMaroon),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentDocument!.fileName} (${_currentDocument!.fileExtension.toUpperCase()} • ${_currentDocument!.pageCount} pg • ${_currentDocument!.wordCount} w)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: SaynColors.wineMaroon,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _currentDocument = null);
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: SaynColors.paperTextMuted),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    minLines: 4,
                    style: const TextStyle(fontSize: 14.5, color: SaynColors.paperText, height: 1.45),
                    decoration: const InputDecoration(
                      hintText: 'Paste essay, article, or message to scan for AI patterns...',
                      hintStyle: TextStyle(fontSize: 13.5, color: SaynColors.paperTextMuted),
                      contentPadding: EdgeInsets.all(14),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scan Action Button
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _runDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: SaynColors.wineMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Scan for AI Content',
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

            // 2. Results Section
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultsOverview(_result!),
              const SizedBox(height: 20),
              _buildSentenceBreakdown(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsOverview(Map<String, dynamic> res) {
    final aiPct = (res['overallAiPercentage'] as num?)?.toInt() ?? 0;
    final humanPct = (res['humanPercentage'] as num?)?.toInt() ?? (100 - aiPct);
    final verdict = res['verdict'] as String? ?? 'likely_human';
    final verdictColor = _getVerdictColor(verdict);
    final summary = res['analysisSummary'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SaynColors.paperCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SaynColors.paperBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: verdictColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: verdictColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _getVerdictLabel(verdict),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: verdictColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${res['wordCount'] ?? 0} words analyzed',
                style: const TextStyle(fontSize: 11.5, color: SaynColors.paperTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$aiPct%',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: verdictColor,
                      ),
                    ),
                    const Text(
                      'AI Probability',
                      style: TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: SaynColors.paperBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$humanPct%',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: SaynColors.wineMaroon,
                        ),
                      ),
                      const Text(
                        'Human Resonance',
                        style: TextStyle(fontSize: 12, color: SaynColors.paperTextMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: aiPct / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFF2B8A3E),
              valueColor: AlwaysStoppedAnimation<Color>(verdictColor),
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                color: SaynColors.paperText,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentenceBreakdown(Map<String, dynamic> res) {
    final List sentences = res['sentences'] as List? ?? [];
    if (sentences.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sentence-by-Sentence Breakdown',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: SaynColors.wineMaroon,
          ),
        ),
        const SizedBox(height: 10),
        ...sentences.map((s) {
          final sText = s['sentence'] as String? ?? '';
          final verdict = s['verdict'] as String? ?? 'human';
          final aiProb = ((s['aiProbability'] as num?)?.toDouble() ?? 0.0) * 100;
          final reason = s['reason'] as String?;

          Color cardColor;
          Color borderColor;
          if (verdict == 'ai') {
            cardColor = const Color(0xFFFFF5F5);
            borderColor = const Color(0xFFC92A2A);
          } else if (verdict == 'uncertain') {
            cardColor = const Color(0xFFFFF9DB);
            borderColor = const Color(0xFFD97706);
          } else {
            cardColor = SaynColors.paperCard;
            borderColor = const Color(0xFF2B8A3E);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: borderColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: SaynColors.paperText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'AI: ${aiProb.round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: borderColor,
                      ),
                    ),
                    if (reason != null && reason.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 11, color: SaynColors.paperTextMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
