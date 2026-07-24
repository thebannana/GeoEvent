import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/widgets.dart' as widgets;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/admin_profile/models/admin_dashboard_stats.dart';
import '../../../../shared/admin_profile/providers/admin_dashboard_providers.dart';

class AdminDashboardPanel extends ConsumerStatefulWidget {
  const AdminDashboardPanel({super.key});

  @override
  ConsumerState<AdminDashboardPanel> createState() =>
      _AdminDashboardPanelState();
}

class _AdminDashboardPanelState extends ConsumerState<AdminDashboardPanel> {
  static const List<String> _tabs = [
    'Users',
    'Events',
    'Revenue',
    'Reservations',
  ];

  int _selectedTabIndex = 0;
  bool _isGeneratingMoneyReport = false;
  bool _isGeneratingStatsReport = false;


Future<void> _downloadMoneyAndSalesReport(
  AdminDashboardStatsBundle bundle,
) async {
  if (_isGeneratingMoneyReport) return;
  setState(() => _isGeneratingMoneyReport = true);

  try {
    final bytes = await _buildMoneyAndSalesReport(bundle);
    final reportDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FileSaver.instance.saveFile(
      name: 'GeoEvent sales report $reportDate',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );

    if (!mounted) return;
    _showSnack(
      'Money and sales report downloaded. Check your browser Downloads folder or your system Downloads directory.',
    );
  } catch (_) {
    if (!mounted) return;
    _showSnack('Failed to download money and sales report.');
  } finally {
    if (mounted) {
      setState(() => _isGeneratingMoneyReport = false);
    }
  }
}

Future<void> _downloadStatisticsReport(
  AdminDashboardStatsBundle bundle,
) async {
  if (_isGeneratingStatsReport) return;
  setState(() => _isGeneratingStatsReport = true);

  try {
    final bytes = await _buildStatisticsReport(bundle);
    final reportDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FileSaver.instance.saveFile(
      name: 'GeoEvent statistics report $reportDate',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );

    if (!mounted) return;
    _showSnack(
      'Statistics report downloaded. Check your browser Downloads folder or your system Downloads directory.',
    );
  } catch (_) {
    if (!mounted) return;
    _showSnack('Failed to download statistics report.');
  } finally {
    if (mounted) {
      setState(() => _isGeneratingStatsReport = false);
    }
  }
}

Future<(pw.MemoryImage?, pw.Font, pw.Font, String)> _loadReportAssets() async {
  pw.MemoryImage? logo;
  try {
    final logoBytes = await rootBundle.load('assets/images/geovent.png');
    logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
  } catch (_) {
    logo = null;
  }

  final baseFont = await PdfGoogleFonts.interRegular();
  final boldFont = await PdfGoogleFonts.interBold();
  final generatedAt = DateFormat(
    'dd.MM.yyyy. HH:mm',
  ).format(DateTime.now());

  return (logo, baseFont, boldFont, generatedAt);
}

pw.Widget _reportHeader({
  required pw.MemoryImage? logo,
  required pw.Font baseFont,
  required pw.Font boldFont,
  required String title,
  required String subtitle,
  required String generatedAt,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 18),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 62,
            height: 62,
            margin: const pw.EdgeInsets.only(right: 16),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GeoEvent',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.blueGrey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 22,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  font: baseFont,
                  fontSize: 10.5,
                  color: PdfColors.blueGrey600,
                  lineSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Report date',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColors.blueGrey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                generatedAt,
                style: pw.TextStyle(
                  font: baseFont,
                  fontSize: 10,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _reportSummaryBox({
  required pw.Font baseFont,
  required pw.Font boldFont,
  required String title,
  required String text,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: PdfColors.blueGrey50,
      borderRadius: pw.BorderRadius.circular(10),
      border: pw.Border.all(color: PdfColors.blueGrey100),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          text,
          style: pw.TextStyle(
            font: baseFont,
            fontSize: 10.5,
            color: PdfColors.blueGrey700,
            lineSpacing: 2,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String text, pw.Font boldFont) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 14,
        color: PdfColors.blueGrey900,
      ),
    ),
  );
}

Future<Uint8List> _buildMoneyAndSalesReport(
  AdminDashboardStatsBundle bundle,
) async {
  final pdf = pw.Document();
  final tickets = bundle.tickets;
  final formatter = NumberFormat.currency(
    locale: 'bs_BA',
    symbol: 'BAM ',
    decimalDigits: 2,
  );

  final (logo, baseFont, boldFont, generatedAt) = await _loadReportAssets();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      ),
      build: (context) => [
        _reportHeader(
          logo: logo,
          baseFont: baseFont,
          boldFont: boldFont,
          title: 'Money and Sales Report',
          subtitle:
              'This report provides a structured financial overview of revenue, refunds, payments, reservations, and issued tickets for the current dashboard snapshot.',
          generatedAt: generatedAt,
        ),
        pw.SizedBox(height: 16),
        _reportSummaryBox(
          baseFont: baseFont,
          boldFont: boldFont,
          title: 'Report scope',
          text:
              'All monetary values are displayed in BAM. This document is intended for administrative review, export, and printing.',
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Financial overview', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Gross revenue', formatter.format(tickets.grossRevenue)],
            ['Net revenue', formatter.format(tickets.netRevenue)],
            ['Refunded amount', formatter.format(tickets.refundedAmount)],
            ['PayPal revenue', formatter.format(tickets.payPalRevenue)],
            ['Cash revenue', formatter.format(tickets.cashRevenue)],
            ['Pending cash revenue', formatter.format(tickets.pendingCashRevenue)],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Payments', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Total payments', '${tickets.totalPayments}'],
            ['Completed payments', '${tickets.completedPayments}'],
            ['Pending payments', '${tickets.pendingPayments}'],
            ['Refunded payments', '${tickets.refundedPayments}'],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Reservations and tickets', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Total reservations', '${tickets.totalReservations}'],
            ['Confirmed reservations', '${tickets.confirmedReservations}'],
            ['Pending reservations', '${tickets.pendingReservations}'],
            ['Cancelled reservations', '${tickets.cancelledReservations}'],
            ['Expired reservations', '${tickets.expiredReservations}'],
            ['Total tickets', '${tickets.totalTickets}'],
            ['Active tickets', '${tickets.activeTickets}'],
            ['Used tickets', '${tickets.usedTickets}'],
            ['Cancelled tickets', '${tickets.cancelledTickets}'],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
      ],
    ),
  );

  return pdf.save();
}

Future<Uint8List> _buildStatisticsReport(
  AdminDashboardStatsBundle bundle,
) async {
  final pdf = pw.Document();
  final users = bundle.users;
  final events = bundle.events;
  final tickets = bundle.tickets;

  final (logo, baseFont, boldFont, generatedAt) = await _loadReportAssets();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      ),
      build: (context) => [
        _reportHeader(
          logo: logo,
          baseFont: baseFont,
          boldFont: boldFont,
          title: 'Platform Statistics Report',
          subtitle:
              'This report summarizes platform activity across users, events, reservations, and tickets using the latest data visible on the admin dashboard.',
          generatedAt: generatedAt,
        ),
        pw.SizedBox(height: 16),
        _reportSummaryBox(
          baseFont: baseFont,
          boldFont: boldFont,
          title: 'Administrative note',
          text:
              'Use this document for internal monitoring, operational review, and export-ready reporting during meetings or audits.',
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Users', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Active users', '${users.activeUsersCount}'],
            ['Total reports', '${users.totalReportsCount}'],
            ['Bookmarks', '${users.bookmarksCount}'],
            ['Comments', '${users.commentsCount}'],
            ['Liked events', '${users.likedEventsCount}'],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Events', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Total events', '${events.totalEventsCount}'],
            ['Confirmed events', '${events.confirmedEventsCount}'],
            ['Pending events', '${events.pendingEventsCount}'],
            ['Cancelled events', '${events.cancelledEventsCount}'],
            ['Completed events', '${events.completedEventsCount}'],
            ['Total likes', '${events.totalLikesCount}'],
            ['Total bookmarks', '${events.totalBookmarksCount}'],
            ['Total comments', '${events.totalCommentsCount}'],
            ['Total views', '${events.totalViewsCount}'],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
        pw.SizedBox(height: 18),
        _sectionTitle('Reservations and tickets', boldFont),
        pw.TableHelper.fromTextArray(
          headers: const ['Metric', 'Value'],
          data: [
            ['Total reservations', '${tickets.totalReservations}'],
            ['Pending reservations', '${tickets.pendingReservations}'],
            ['Confirmed reservations', '${tickets.confirmedReservations}'],
            ['Cancelled reservations', '${tickets.cancelledReservations}'],
            ['Expired reservations', '${tickets.expiredReservations}'],
            ['Total tickets', '${tickets.totalTickets}'],
            ['Active tickets', '${tickets.activeTickets}'],
            ['Used tickets', '${tickets.usedTickets}'],
            ['Cancelled tickets', '${tickets.cancelledTickets}'],
          ],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          border: pw.TableBorder.all(color: PdfColors.blueGrey100),
        ),
      ],
    ),
  );

  return pdf.save();
}

  Future<void> _printMoneyAndSalesReport(
    AdminDashboardStatsBundle bundle,
  ) async {
    try {
      final bytes = await _buildMoneyAndSalesReport(bundle);
      final reportDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'GeoEvent sales report $reportDate.pdf',
      );

      if (!mounted) return;
      _showSnack('Printer dialog opened for money and sales report.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to open printer for money and sales report.');
    }
  }

  Future<void> _printStatisticsReport(
    AdminDashboardStatsBundle bundle,
  ) async {
    try {
      final bytes = await _buildStatisticsReport(bundle);
      final reportDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'GeoEvent statistics report $reportDate.pdf',
      );

      if (!mounted) return;
      _showSnack('Printer dialog opened for statistics report.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to open printer for statistics report.');
    }
  }


void _showSnack(String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatWholeNumber(num value) {
  return NumberFormat.decimalPattern('bs_BA').format(value);
}

String _formatCurrency(num value) {
  return NumberFormat.currency(
    locale: 'bs_BA',
    symbol: 'BAM ',
    decimalDigits: 2,
  ).format(value);
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.appColors;
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;

  final dashboardAsync = ref.watch(adminDashboardStatsProvider);

  return dashboardAsync.when(
    loading: () => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? const Color(0x16000000)
                : const Color(0x12000000),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
    ),
    error: (_, __) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed to load dashboard statistics.',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.refresh(adminDashboardStatsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
    data: (bundle) {
      final users = bundle.users;
      final events = bundle.events;
      final tickets = bundle.tickets;

      final chartData = switch (_selectedTabIndex) {
        0 => _ChartSeriesData(
            title: 'Users overview',
            subtitle: 'Platform engagement and moderation indicators.',
            values: [
              users.activeUsersCount.toDouble(),
              users.totalReportsCount.toDouble(),
              users.bookmarksCount.toDouble(),
              users.commentsCount.toDouble(),
              users.likedEventsCount.toDouble(),
            ],
            labels: const ['Active', 'Reports', 'Bookmarks', 'Comments', 'Likes'],
          ),
        1 => _ChartSeriesData(
              title: 'Events overview',
              subtitle: 'Current event lifecycle and engagement distribution.',
              values: [
                events.totalEventsCount.toDouble(),
                events.confirmedEventsCount.toDouble(),
                events.pendingEventsCount.toDouble(),
                events.cancelledEventsCount.toDouble(),
                events.completedEventsCount.toDouble(),
              ],
              labels: const ['Total', 'Confirmed', 'Pending', 'Cancelled', 'Completed'],
            ),
        2 => _ChartSeriesData(
            title: 'Revenue overview',
            subtitle: 'BAM-based financial overview for payments and sales.',
            values: [
              tickets.grossRevenue,
              tickets.netRevenue,
              tickets.refundedAmount,
              tickets.payPalRevenue,
              tickets.cashRevenue,
            ],
            labels: const ['Gross', 'Net', 'Refunded', 'PayPal', 'Cash'],
            currency: true,
          ),
        _ => _ChartSeriesData(
            title: 'Reservations overview',
            subtitle: 'Reservation and ticket status distribution.',
            values: [
              tickets.totalReservations.toDouble(),
              tickets.pendingReservations.toDouble(),
              tickets.confirmedReservations.toDouble(),
              tickets.cancelledReservations.toDouble(),
              tickets.expiredReservations.toDouble(),
            ],
            labels: const ['Total', 'Pending', 'Confirmed', 'Cancelled', 'Expired'],
          ),
      };

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 760;
          final isTablet = width >= 760 && width < 1180;
          final isWide = width >= 1180;

          final statCardWidth = isMobile
              ? double.infinity
              : isTablet
                  ? (width - 64) / 2
                  : 220.0;

          final horizontalPadding = isMobile ? 16.0 : 24.0;
          final outerRadius = isMobile ? 22.0 : 28.0;
          final sectionSpacing = isMobile ? 16.0 : 22.0;

          Widget analyticsPanel = Container(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 22,
              isMobile ? 16 : 20,
              isMobile ? 16 : 22,
              isMobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: colors.borderSoft.withValues(alpha: 0.92),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch between sections to review the most important platform metrics.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    _tabs.length,
                    (index) => _ChartTabButton(
                      label: _tabs[index],
                      isSelected: index == _selectedTabIndex,
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: isMobile ? 320 : 380,
                  child: _DashboardChartCard(
                    data: chartData,
                    currencyFormatter: _formatCurrency,
                    numberFormatter: _formatWholeNumber,
                  ),
                ),
              ],
            ),
          );

          Widget reportsPanel = Column(
            children: [
              _DashboardReportCard(
                title: 'Money and sales report',
                subtitle:
                    'Gross revenue, net revenue, refunds, payments, reservations, and ticket sales in BAM.',
                icon: Icons.receipt_long_outlined,
                buttonLabel:
                    _isGeneratingMoneyReport ? 'Preparing...' : 'Download PDF',
                accentColor: colorScheme.primary,
                onPressed: _isGeneratingMoneyReport
                    ? null
                    : () => _downloadMoneyAndSalesReport(bundle),
                secondaryActionLabel: 'Print',
                onSecondaryPressed: () => _printMoneyAndSalesReport(bundle),
              ),
              const SizedBox(height: 18),
              _DashboardReportCard(
                title: 'Platform statistics report',
                subtitle:
                    'Users, events, reservations, tickets, and operational platform statistics in PDF format.',
                icon: Icons.analytics_outlined,
                buttonLabel:
                    _isGeneratingStatsReport ? 'Preparing...' : 'Download PDF',
                accentColor: const Color(0xFF5B8FB4),
                onPressed: _isGeneratingStatsReport
                    ? null
                    : () => _downloadStatisticsReport(bundle),
                secondaryActionLabel: 'Print',
                onSecondaryPressed: () => _printStatisticsReport(bundle),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.borderSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporting tools',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Reports are exported as PDF files and can also be sent directly to your system print dialog.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MiniInfoRow(
                      icon: Icons.folder_outlined,
                      label: 'Download location',
                      value: 'Browser / system Downloads',
                    ),
                    const SizedBox(height: 12),
                    _MiniInfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Currency',
                      value: 'BAM',
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _printStatisticsReport(bundle),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('Print statistics'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _printMoneyAndSalesReport(bundle),
                          icon: const Icon(Icons.receipt_long_outlined, size: 18),
                          label: const Text('Print sales report'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          return Container(
            padding: EdgeInsets.all(horizontalPadding),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(outerRadius),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0x16000000)
                      : const Color(0x12000000),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: statCardWidth,
                        child: _DashboardStatCard(
                          title: 'Active users',
                          value: _formatWholeNumber(users.activeUsersCount),
                          icon: Icons.group_outlined,
                          accent: const Color(0xFF4F8FA8),
                        ),
                      ),
                      SizedBox(
                        width: statCardWidth,
                        child: _DashboardStatCard(
                          title: 'Confirmed events',
                          value: _formatWholeNumber(events.confirmedEventsCount),
                          icon: Icons.event_available_outlined,
                          accent: const Color(0xFF6E8F6A),
                        ),
                      ),
                      SizedBox(
                        width: statCardWidth,
                        child: _DashboardStatCard(
                          title: 'Net revenue',
                          value: _formatCurrency(tickets.netRevenue),
                          icon: Icons.payments_outlined,
                          accent: const Color(0xFF98724A),
                        ),
                      ),
                      SizedBox(
                        width: statCardWidth,
                        child: _DashboardStatCard(
                          title: 'Reservations',
                          value: _formatWholeNumber(tickets.totalReservations),
                          icon: Icons.confirmation_number_outlined,
                          accent: const Color(0xFF8A667A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sectionSpacing),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: analyticsPanel),
                        const SizedBox(width: 22),
                        Expanded(flex: 4, child: reportsPanel),
                      ],
                    )
                  else
                    Column(
                      children: [
                        analyticsPanel,
                        const SizedBox(height: 18),
                        reportsPanel,
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartTabButton extends StatelessWidget {
  const _ChartTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.primary : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChartSeriesData {
  const _ChartSeriesData({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
    this.currency = false,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final List<String> labels;
  final bool currency;
}

class _DashboardChartCard extends StatelessWidget {
  const _DashboardChartCard({
    required this.data,
    required this.currencyFormatter,
    required this.numberFormatter,
  });

  final _ChartSeriesData data;
  final String Function(num value) currencyFormatter;
  final String Function(num value) numberFormatter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderSoft),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: CustomPaint(
              painter: _DashboardLineChartPainter(
                values: data.values,
                labels: data.labels,
                gridColor: colors.borderSoft,
                lineColor: const Color(0xFFB46878),
                pointColor: const Color(0xFF51657A),
                axisLabelColor: colors.textSecondary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: List.generate(data.labels.length, (index) {
              final label = data.labels[index];
              final value = data.values[index];
              final formatted = data.currency
                  ? currencyFormatter(value)
                  : numberFormatter(value);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderSoft),
                ),
                child: Text(
                  '$label: $formatted',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DashboardReportCard extends StatelessWidget {
  const _DashboardReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonLabel,
    required this.accentColor,
    required this.onPressed,
    required this.secondaryActionLabel,
    required this.onSecondaryPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback? onPressed;
  final String secondaryActionLabel;
  final VoidCallback onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 190,
                    child: FilledButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(buttonLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSecondaryPressed,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text(secondaryActionLabel),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSoft),
          ),
          child: Icon(
            icon,
            size: 18,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardLineChartPainter extends CustomPainter {
  const _DashboardLineChartPainter({
    required this.values,
    required this.labels,
    required this.gridColor,
    required this.lineColor,
    required this.pointColor,
    required this.axisLabelColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color gridColor;
  final Color lineColor;
  final Color pointColor;
  final Color axisLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty || values.length != labels.length) {
      return;
    }

    const leftPadding = 44.0;
    const bottomPadding = 30.0;
    const topPadding = 18.0;
    const rightPadding = 18.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final adjustedMax = maxValue <= minValue ? minValue + 1 : maxValue;
    final adjustedMin = minValue == adjustedMax ? 0 : minValue * 0.9;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    final axisTextStyle = TextStyle(
      color: axisLabelColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    const ySteps = 5;
    for (int i = 0; i <= ySteps; i++) {
      final ratio = i / ySteps;
      final dy = topPadding + chartHeight - (chartHeight * ratio);

      canvas.drawLine(
        Offset(leftPadding, dy),
        Offset(leftPadding + chartWidth, dy),
        gridPaint,
      );

      final value = adjustedMin + ((adjustedMax - adjustedMin) * ratio);
      final tp = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: axisTextStyle,
        ),
          textDirection: widgets.TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(0, dy - tp.height / 2));
    }

    final points = <Offset>[];
    for (int i = 0; i < labels.length; i++) {
      final dx = leftPadding + (chartWidth / (labels.length - 1) * i);
      final normalized = (values[i] - adjustedMin) / (adjustedMax - adjustedMin);
      final dy = topPadding + chartHeight - (chartHeight * normalized);
      points.add(Offset(dx, dy));

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: axisTextStyle),
        textDirection: widgets.TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(dx - tp.width / 2, topPadding + chartHeight + 10),
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(
        points[i],
        isLast ? 6.2 : 3.0,
        Paint()..color = isLast ? pointColor : lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.pointColor != pointColor ||
        oldDelegate.axisLabelColor != axisLabelColor;
  }
}