import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fin_track/utils/currency_format.dart';

class PdfInvoiceService {
  
  // Fungsi utama yang dipanggil dari UI
  static Future<void> generateAndPrintInvoice(Map<String, dynamic> transaction) async {
    final pdf = pw.Document();
    
    // Siapkan data
    final isExpense = transaction['type'] == 2;
    final date = DateTime.parse(transaction['date']);
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);
    final amount = CurrencyFormat.convertToIdr(transaction['amount'], 0);
    final id = "INV-${date.year}${date.month}${date.day}-${transaction['id']}"; // ID Unik buatan

    // Desain Halaman PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Ukuran kertas struk (80mm)
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // HEADER
                pw.Text("FIN TRACK", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text("Bukti Transaksi Digital", style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // STATUS BERHASIL
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text("TRANSAKSI BERHASIL", style: pw.TextStyle(color: PdfColors.green800, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.SizedBox(height: 20),

                // NOMINAL BESAR
                pw.Text("Total Nominal", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                pw.Text(amount, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: isExpense ? PdfColors.red900 : PdfColors.green900)),
                pw.SizedBox(height: 20),

                // DETAIL TABEL
                pw.Divider(style: pw.BorderStyle.dashed),
                _buildRow("Tanggal", dateStr),
                _buildRow("Referensi ID", id),
                _buildRow("Kategori", transaction['category_name'] ?? '-'),
                _buildRow("Sumber Dana", transaction['wallet_name'] ?? '-'),
                _buildRow("Keterangan", transaction['description'] ?? '-'),
                pw.Divider(style: pw.BorderStyle.dashed),
                
                pw.SizedBox(height: 20),
                pw.Text("Terima kasih telah menggunakan FinTrack", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    // Langsung buka preview print/share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice-$id', // Nama file saat dishare
    );
  }

  // Helper bikin baris biar rapi
  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}