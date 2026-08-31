class SyncProgress {
  final int current;
  final int total;
  final String status;
  final bool completed;
  final String? error;

  const SyncProgress({
    this.current = 0,
    this.total = 0,
    this.status = '',
    this.completed = false,
    this.error,
  });

  SyncProgress copyWith({
    int? current,
    int? total,
    String? status,
    bool? completed,
    String? error,
  }) {
    return SyncProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      status: status ?? this.status,
      completed: completed ?? this.completed,
      error: error ?? this.error,
    );
  }
}
