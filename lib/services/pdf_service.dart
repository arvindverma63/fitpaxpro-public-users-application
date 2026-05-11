import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Helper to remove emojis and unsupported Unicode characters for standard PDF fonts
  static String _sanitizeText(String text) {
    if (text.isEmpty) return "";
    // Allow more characters but still exclude most Unicode that causes crashes in standard PDF fonts
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  static Future<void> generateAndSharePlan(Map<String, dynamic> messageData) async {
    final pdf = pw.Document();

    final exercises = messageData['exercises'] as List<dynamic>? ?? [];
    final nutrition = messageData['nutrition'] as List<dynamic>? ?? [];
    final String rawText = messageData['text'] ?? '';
    final String sanitizedSummary = _sanitizeText(rawText);

    // Define Premium Brand Colors
    final PdfColor primaryColor = PdfColor.fromHex('#111827'); // Deep Slate
    final PdfColor accentColor = PdfColor.fromHex('#3B82F6'); // Bright Blue
    final PdfColor lightBg = PdfColor.fromHex('#F3F4F6'); // Light Gray

    // Get current date
    final now = DateTime.now();
    final String formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),

        // --- PROFESSIONAL HEADER ---
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            margin: const pw.EdgeInsets.only(bottom: 24),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FITPAX PRO', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1.5)),
                    pw.SizedBox(height: 4),
                    pw.Text('PREMIUM AI MASTER PLAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentColor, letterSpacing: 2)),
                  ],
                ),
                pw.Text('Gen ID: ${now.millisecondsSinceEpoch.toString().substring(7)} | $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },

        // --- PROFESSIONAL FOOTER ---
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 16),
            margin: const pw.EdgeInsets.only(top: 24),
            decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Official FitPax AI Optimization Document', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          );
        },

        // --- MAIN CONTENT ---
        build: (pw.Context context) {
          // Split the summary into paragraphs to allow MultiPage to break across pages
          final List<String> paragraphs = sanitizedSummary.split('\n').where((p) => p.trim().isNotEmpty).toList();

          return [

            // AI SUMMARY BLOCK
            if (sanitizedSummary.isNotEmpty) ...[
              pw.Row(
                children: [
                  pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle)),
                  pw.SizedBox(width: 8),
                  pw.Text('COACH\'S STRATEGY', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey200, thickness: 1),
              pw.SizedBox(height: 12),
              
              ...paragraphs.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(p.trim(), style: pw.TextStyle(fontSize: 11, lineSpacing: 1.6, color: PdfColor.fromHex('#374151'))),
              )),
              
              pw.SizedBox(height: 24),
            ],

            // EXERCISES SECTION
            if (exercises.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle)),
                  pw.SizedBox(width: 8),
                  pw.Text('WORKOUT PROTOCOL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                ]
              ),
              pw.SizedBox(height: 16),
              ...exercises.map((ex) {
                final String name = _sanitizeText(ex['name'].toString().toUpperCase());
                final String target = _sanitizeText(ex['muscles'] ?? 'General');
                final String instruction = _sanitizeText(ex['instruction'] ?? 'Follow form.');

                return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey200, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      color: PdfColors.white,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primaryColor)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(color: primaryColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                              child: pw.Text(target, style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(instruction, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 1.3)),
                        pw.SizedBox(height: 12),

                        // SETS TRACKER
                        pw.Row(
                          children: [
                            pw.Text('TRACKER:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor)),
                            pw.SizedBox(width: 12),
                            ...List.generate(4, (i) => pw.Row(
                              children: [
                                pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 4),
                                pw.Text('S${i+1}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                                pw.SizedBox(width: 12),
                              ]
                            )),
                          ]
                        )
                      ],
                    )
                );
              }),
              pw.SizedBox(height: 24),
            ],

            // NUTRITION SECTION
            if (nutrition.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle)),
                  pw.SizedBox(width: 8),
                  pw.Text('NUTRITION GUIDELINES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                ]
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                context: context,
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 1),
                data: [
                  ['ITEM', 'CAL', 'PRO', 'CARB', 'FAT'],
                  ...nutrition.map((n) => [
                    _sanitizeText(n['name'].toString()),
                    '${n['calories']}',
                    '${n['protein']}g',
                    '${n['carbohydrate'] ?? '0'}g',
                    '${n['fat'] ?? '0'}g',
                  ]),
                ],
              ),
            ],
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'FitPax_Master_Plan.pdf');
  }
}