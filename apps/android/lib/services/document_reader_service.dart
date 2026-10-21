import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedDocumentResult {
  final String fileName;
  final String text;
  final int pageCount;
  final int wordCount;
  final int fileSizeBytes;
  final String extension;

  ExtractedDocumentResult({
    required this.fileName,
    required this.text,
    required this.pageCount,
    required this.wordCount,
    required this.fileSizeBytes,
    required this.extension,
  });

  String get fileExtension => extension;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DocumentReaderService {
  DocumentReaderService._();
  static final DocumentReaderService instance = DocumentReaderService._();

  /// Prompts system file picker for PDF, TXT, or Markdown documents and extracts plain text.
  Future<ExtractedDocumentResult?> pickAndExtractDocument() async {
    try {
      final List<PlatformFile> pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'text'],
      );

      if (pickedFiles.isEmpty) {
        return null;
      }

      final PlatformFile file = pickedFiles.first;
      final Uint8List fileBytes = await file.xFile.readAsBytes();

      if (fileBytes.isEmpty) {
        throw Exception('Could not read file data. Please try another document.');
      }

      final int fileLength = await file.xFile.length();
      final ext = (file.extension ?? '').toLowerCase();
      String extractedText = '';
      int pageCount = 1;

      if (ext == 'pdf') {
        // Parse PDF using Syncfusion pure Dart engine with precise word boundaries
        PdfDocument? document;
        try {
          document = PdfDocument(inputBytes: fileBytes);
          pageCount = document.pages.count;
          final extractor = PdfTextExtractor(document);

          final buffer = StringBuffer();
          for (int p = 0; p < pageCount; p++) {
            final lines = extractor.extractTextLines(startPageIndex: p, endPageIndex: p);
            for (int i = 0; i < lines.length; i++) {
              final lineWords = lines[i].wordCollection.map((w) => w.text).join(' ');
              if (lineWords.trim().isNotEmpty) {
                buffer.writeln(lineWords.trim());
              }
            }
            if (p < pageCount - 1) {
              buffer.writeln();
            }
          }
          extractedText = buffer.toString();

          // Reconstitute hyphenated words across linebreaks (e.g., "predic-\ntive" -> "predictive")
          extractedText = extractedText.replaceAllMapped(
            RegExp(r'(\b\w+)-\s*\n\s*(\w+\b)'),
            (m) => '${m[1]}${m[2]}',
          );
        } catch (e) {
          throw Exception('Unable to open PDF: $e. The file may be password-protected or corrupted.');
        } finally {
          document?.dispose();
        }

        if (extractedText.trim().isEmpty) {
          throw Exception(
            'This PDF appears to be a scanned image without an embedded text layer. Please use OCR or copy/paste the text directly.',
          );
        }
      } else {
        // Plain text or Markdown document
        try {
          extractedText = utf8.decode(fileBytes);
        } catch (_) {
          extractedText = String.fromCharCodes(fileBytes);
        }
        pageCount = (extractedText.split('\n').length / 45).ceil().clamp(1, 9999);
      }

      final words = extractedText.trim().isEmpty
          ? 0
          : RegExp(r'\S+').allMatches(extractedText.trim()).length;

      return ExtractedDocumentResult(
        fileName: file.name,
        text: extractedText.trim(),
        pageCount: pageCount,
        wordCount: words,
        fileSizeBytes: fileLength > 0 ? fileLength : fileBytes.length,
        extension: ext,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to import document: $e');
    }
  }
}
