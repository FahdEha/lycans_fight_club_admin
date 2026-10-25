import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import '../widgets/kpi_card.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _searchQuery = '';
  String _filter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Unpaid'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final invoices = provider.invoices.where((i) {
      final matchesSearch = i.playerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Paid' && i.isPaid) ||
          (_filter == 'Unpaid' && !i.isPaid);
      return matchesSearch && matchesFilter;
    }).toList();

    final now = DateTime.now();
    final todayRevenue = invoices
        .where((i) => i.date.year == now.year && i.date.month == now.month && i.date.day == now.day && i.isPaid)
        .fold<double>(0, (sum, i) => sum + i.amount);

    final monthlyRevenue = invoices
        .where((i) => i.date.year == now.year && i.date.month == now.month && i.isPaid)
        .fold<double>(0, (sum, i) => sum + i.amount);

    final unpaid = invoices.where((i) => !i.isPaid).fold<double>(0, (sum, i) => sum + i.amount);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: constraints.maxWidth ~/ 180,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  KpiCard(
                    icon: Icons.attach_money,
                    value: '${todayRevenue.toStringAsFixed(0)}',
                    label: "Today's Revenue (EGP)",
                    isHighlighted: true,
                  ),
                  KpiCard(
                    icon: Icons.bar_chart,
                    value: '${monthlyRevenue.toStringAsFixed(0)}',
                    label: 'Monthly Revenue (EGP)',
                  ),
                  KpiCard(
                    icon: Icons.trending_up,
                    value: '${(monthlyRevenue * 1.14).toStringAsFixed(0)}',
                    label: 'Expected Revenue (EGP)',
                  ),
                  KpiCard(
                    icon: Icons.pending_actions,
                    value: '${unpaid.toStringAsFixed(0)}',
                    label: 'Unpaid (EGP)',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppConstants.bgCard2,
                        border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 15, color: AppConstants.inkFaint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(fontSize: 12.5, color: AppConstants.ink),
                              decoration: const InputDecoration(
                                hintText: 'Search transactions...',
                                hintStyle: TextStyle(fontSize: 12.5, color: AppConstants.inkFaint),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._filters.map((filter) {
                    return GestureDetector(
                      onTap: () => setState(() => _filter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _filter == filter
                              ? AppConstants.gold.withValues(alpha: 0.12)
                              : AppConstants.bgCard2,
                          border: Border.all(
                            color: _filter == filter
                                ? AppConstants.gold.withValues(alpha: 0.16)
                                : AppConstants.ink.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _filter == filter ? AppConstants.goldSoft : AppConstants.inkDim,
                          ),
                        ),
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => _exportToPdf(invoices),
                    icon: const Icon(Icons.picture_as_pdf, size: 14),
                    label: const Text('EXPORT PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.ink,
                      side: BorderSide(color: AppConstants.gold.withValues(alpha: 0.16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportToCsv(invoices),
                    icon: const Icon(Icons.table_chart, size: 14),
                    label: const Text('EXPORT EXCEL'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.ink,
                      side: BorderSide(color: AppConstants.gold.withValues(alpha: 0.16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppConstants.bgCard,
                  border: Border.all(color: AppConstants.ink.withValues(alpha: 0.07)),
                ),
                child: invoices.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 13, color: AppConstants.inkFaint),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return _buildInvoiceRow(invoice, index == invoices.length - 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(invoice, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: AppConstants.ink.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppConstants.goldSoft,
                  ),
                ),
                Text(
                  invoice.playerName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.ink),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice.packageName,
              style: const TextStyle(fontSize: 12, color: AppConstants.inkDim),
            ),
          ),
          Expanded(
            child: Text(
              '${invoice.amount.toStringAsFixed(0)} EGP',
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: AppConstants.goldSoft,
              ),
            ),
          ),
          Expanded(
            child: Text(
              invoice.paymentMethod,
              style: const TextStyle(fontSize: 11, color: AppConstants.inkDim),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd MMM').format(invoice.date),
              style: const TextStyle(fontSize: 11, color: AppConstants.inkFaint),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: invoice.isPaid
                  ? AppConstants.green.withValues(alpha: 0.12)
                  : AppConstants.ember.withValues(alpha: 0.12),
              border: Border.all(
                color: invoice.isPaid
                    ? AppConstants.green.withValues(alpha: 0.3)
                    : AppConstants.ember.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              invoice.isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9.5,
                color: invoice.isPaid ? AppConstants.green : AppConstants.emberGlow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(List invoices) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('T2 Academy - Finance Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Invoice #', 'Player', 'Package', 'Amount', 'Method', 'Date', 'Status'],
            data: invoices.map((i) => [
              i.invoiceNumber,
              i.playerName,
              i.packageName,
              '${i.amount.toStringAsFixed(0)} EGP',
              i.paymentMethod,
              DateFormat('yyyy-MM-dd').format(i.date),
              i.isPaid ? 'Paid' : 'Unpaid',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported'), backgroundColor: AppConstants.green),
      );
    }
  }

  // / _exportToCsv metodunu şu şekilde değiştir:
  Future<void> _exportToCsv(List invoices) async {
    // Manuel CSV oluştur
    final StringBuffer buffer = StringBuffer();

    // Başlık satırı
    buffer.writeln('Invoice #,Player,Package,Amount,Method,Date,Status');

    // Veri satırları
    for (final invoice in invoices) {
      buffer.writeln(
          '${invoice.invoiceNumber},${invoice.playerName},${invoice.packageName},${invoice.amount.toStringAsFixed(0)},${invoice.paymentMethod},${DateFormat('yyyy-MM-dd').format(invoice.date)},${invoice.isPaid ? 'Paid' : 'Unpaid'}'
      );
    }

    final csvData = buffer.toString();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Text(csvData, style: const pw.TextStyle(fontSize: 8)),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel/CSV exported'), backgroundColor: AppConstants.green),
      );
    }
  }
}