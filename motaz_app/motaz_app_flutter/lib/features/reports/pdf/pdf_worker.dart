import 'dart:async';
import 'dart:isolate';

typedef PdfTask<T, R> = FutureOr<R> Function(T input);

class PdfWorker {
  static Future<R> run<T, R>(
    PdfTask<T, R> task,
    T input, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final port = ReceivePort();
    Isolate? worker;
    var finished = false;
    final spawned = Isolate.spawn<(SendPort, PdfTask<T, R>, T)>(
      _run<T, R>,
      (port.sendPort, task, input),
      onError: port.sendPort,
      onExit: port.sendPort,
      errorsAreFatal: true,
    );
    try {
      return await (() async {
        worker = await spawned;
        if (finished) {
          throw TimeoutException('PDF worker start timed out');
        }
        final message = await port.first;
        if (message is List && message.length == 2 && message.first == true) {
          return message[1] as R;
        }
        if (message is List && message.length >= 2) {
          throw RemoteError(
            message[message.length - 2].toString(),
            message.last.toString(),
          );
        }
        throw StateError('PDF worker exited without a result');
      })().timeout(timeout);
    } finally {
      finished = true;
      worker?.kill(priority: Isolate.immediate);
      // A late spawn must not leave an orphaned CPU task after a timeout.
      unawaited(
        spawned.then((isolate) {
          isolate.kill(priority: Isolate.immediate);
        }, onError: (Object _, StackTrace _) {}),
      );
      port.close();
    }
  }

  static void _run<T, R>((SendPort, PdfTask<T, R>, T) message) async {
    try {
      final result = await message.$2(message.$3);
      Isolate.exit(message.$1, [true, result]);
    } catch (error, stack) {
      Isolate.exit(message.$1, [false, error.toString(), stack.toString()]);
    }
  }
}
