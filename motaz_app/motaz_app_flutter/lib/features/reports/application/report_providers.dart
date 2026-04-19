import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/date_range.dart';
import '../data/client_statement_queries.dart';
import '../data/report_models.dart';
import '../data/report_queries.dart';

final reportQueriesProvider = Provider<ReportQueries>((ref) {
  return ReportQueries(ref.watch(appDatabaseProvider));
});

final salesReportProvider =
    FutureProvider.family<SalesReportSummary, DateRange>((ref, range) {
  return ref.watch(reportQueriesProvider).getSalesReport(range);
});

final profitReportProvider =
    FutureProvider.family<ProfitReportData, DateRange>((ref, range) {
  return ref.watch(reportQueriesProvider).getProfitReport(range);
});

final clientStatementQueriesProvider = Provider<ClientStatementQueries>((ref) {
  return ClientStatementQueries(ref.watch(appDatabaseProvider));
});

final clientStatementProvider = FutureProvider.family<
    ClientStatementData,
    ({String clientId, DateRange range})>((ref, arg) {
  return ref
      .watch(clientStatementQueriesProvider)
      .getClientStatement(arg.clientId, arg.range);
});