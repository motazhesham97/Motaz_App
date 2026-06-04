import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/utils/date_range.dart';
import '../data/client_reports_queries.dart';
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

final profitReportProvider = FutureProvider.family<ProfitReportData, DateRange>(
  (ref, range) {
    return ref.watch(reportQueriesProvider).getProfitReport(range);
  },
);

final finalMonthlyReportProvider =
    FutureProvider.family<FinalMonthlyReportData, ({int year, int month})>(
      (ref, arg) {
        return ref
            .watch(reportQueriesProvider)
            .getFinalMonthlyReport(year: arg.year, month: arg.month);
      },
    );

final clientStatementQueriesProvider = Provider<ClientStatementQueries>((ref) {
  return ClientStatementQueries(ref.watch(appDatabaseProvider));
});

final clientReportsQueriesProvider = Provider<ClientReportsQueries>((ref) {
  return ClientReportsQueries(ref.watch(appDatabaseProvider));
});

final clientStatementProvider =
    FutureProvider.family<
      ClientStatementData,
      ({String clientId, DateRange range})
    >((ref, arg) {
      return ref
          .watch(clientStatementQueriesProvider)
          .getClientStatement(arg.clientId, arg.range);
    });

final clientReceivablesReportProvider =
    FutureProvider.family<
      ClientReceivablesReportData,
      ({DateRange range, String? clientId, String? clientName})
    >((ref, arg) {
      return ref
          .watch(clientReportsQueriesProvider)
          .getReceivablesReport(
            range: arg.range,
            clientId: arg.clientId,
            clientName: arg.clientName,
          );
    });

final clientProductSalesReportProvider =
    FutureProvider.family<
      ClientProductSalesReportData,
      ({
        String clientId,
        String clientName,
        DateRange range,
        String productQuery,
      })
    >((ref, arg) {
      return ref
          .watch(clientReportsQueriesProvider)
          .getClientProductSalesReport(
            clientId: arg.clientId,
            clientName: arg.clientName,
            range: arg.range,
            productQuery: arg.productQuery,
          );
    });
