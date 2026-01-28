import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fin_track/utils/theme.dart';
import 'package:fin_track/utils/currency_format.dart';
import 'package:fin_track/services/pdf_invoice_service.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction['type'] == 2;
    final date = DateTime.parse(transaction['date']);
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
    final amount = CurrencyFormat.convertToIdr(transaction['amount'], 0);

    return Scaffold(
      backgroundColor: kPrimaryColor, // Background Biru Navy biar elegan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Detail Transaksi", style: whiteTextStyle),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Biar kotaknya pas sama isi
            children: [
              // 1. Icon Check
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.check, color: Colors.green, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                "Transaksi Berhasil",
                style: blackTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // 2. Nominal
              Text(
                amount,
                style: blackTextStyle.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? kExpenseColor : kIncomeColor,
                ),
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 24),

              // 3. Detail
              _buildDetailRow("Tanggal", dateStr),
              _buildDetailRow("Kategori", transaction['category_name'] ?? '-'),
              _buildDetailRow("Dompet", transaction['wallet_name'] ?? '-'),
              _buildDetailRow("Catatan", transaction['description'] ?? '-'),

              const SizedBox(height: 32),

              // 4. Tombol Aksi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // PANGGIL SERVICE PDF DISINI
                    PdfInvoiceService.generateAndPrintInvoice(transaction);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    "Bagikan / Simpan PDF",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: greyTextStyle),
          Text(
            value,
            style: blackTextStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
