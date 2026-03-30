import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

enum ConnectivityStatus { online, offline }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final connectivity = Connectivity();
  final controller = StreamController<ConnectivityStatus>();
  StreamSubscription<List<ConnectivityResult>>? subscription;
  Timer? debounce;

  Future<void> emit(List<ConnectivityResult> results) async {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      final status = results.any((result) => result != ConnectivityResult.none)
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
      AppLogger.connectivity.info('Connectivity changed to $status');
      controller.add(status);
    });
  }

  Future<void> initialize() async {
    await emit(await connectivity.checkConnectivity());
    subscription = connectivity.onConnectivityChanged.listen(emit);
  }

  initialize();

  ref.onDispose(() async {
    debounce?.cancel();
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});
