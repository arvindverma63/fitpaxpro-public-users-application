import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndSharePlan(Map<String, dynamic> messageData) async {
    final pdf = pw.Document();

    final exercises = messageData['exercises'] as List<dynamic>? ?? [];
    final nutrition = messageData['nutrition'] as List<dynamic>? ?? [];
    final text = messageData['text'] ?? '';

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
                    pw.Text('MASTER PLAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: accentColor, letterSpacing: 2)),
                  ],
                ),
                pw.Text('Generated: $formattedDate', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
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
                pw.Text('Powered by FitPax AI', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
          );
        },

        // --- MAIN CONTENT ---
        build: (pw.Context context) {
          return [

            // AI SUMMARY BLOCK
            if (text.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border(left: pw.BorderSide(color: accentColor, width: 4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('COACH\'S SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.SizedBox(height: 8),
                    pw.Text(text, style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5, color: PdfColor.fromHex('#374151'))),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),
            ],

            // EXERCISES SECTION
            if (exercises.isNotEmpty) ...[
              pw.Text('WORKOUT ROUTINE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1)),
              pw.SizedBox(height: 16),
              pw.ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 16),
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(ex['name'].toString().toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: primaryColor)),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: pw.BoxDecoration(color: accentColor, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                                  child: pw.Text('Target: ${ex['muscles']}', style: pw.TextStyle(fontSize: 9, color: accentColor, fontWeight: pw.FontWeight.bold)),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(ex['instruction'] ?? 'Perform the exercise with proper form.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 1.3)),
                            pw.SizedBox(height: 12),

                            // PRINTABLE WORKOUT TRACKER (Sets & Reps Checkboxes)
                            pw.Divider(color: PdfColors.grey200),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (i) => pw.Row(
                                  children: [
                                    pw.Container(width: 12, height: 12, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), shape: pw.BoxShape.circle)),
                                    pw.SizedBox(width: 4),
                                    pw.Text('Set ${i + 1} (    reps)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                                  ]
                              )),
                            )
                          ],
                        )
                    );
                  }
              ),
              pw.SizedBox(height: 32),
            ],

            // NUTRITION SECTION
            if (nutrition.isNotEmpty) ...[
              pw.Text('NUTRITION TARGETS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor, letterSpacing: 1)),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                context: context,
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                data: [
                  ['Food Item', 'Calories', 'Protein', 'Carbs', 'Fat'],
                  ...nutrition.map((n) => [
                    n['name'].toString(),
                    '${n['calories']} kcal',
                    '${n['protein']} g',
                    '${n['carbohydrate'] ?? '0'} g',
                    '${n['fat'] ?? '0'} g',
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