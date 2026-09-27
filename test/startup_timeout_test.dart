import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/bootstrap.dart';

void main() {
  test('startup task returns when the operation completes', () async {
    final result = await runStartupTask(
      Future.value('ready'),
      timeout: const Duration(milliseconds: 50),
    );

    expect(result, 'ready');
  });

  test('startup task times out instead of blocking the first frame', () async {
    final neverCompletes = Completer<String>();

    expect(
      () => runStartupTask(
        neverCompletes.future,
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}
