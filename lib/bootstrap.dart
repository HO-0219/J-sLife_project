Future<T> runStartupTask<T>(
  Future<T> operation, {
  Duration timeout = const Duration(seconds: 3),
}) => operation.timeout(timeout);
