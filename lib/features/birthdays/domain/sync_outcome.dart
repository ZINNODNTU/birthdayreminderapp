/// Lightweight summary of a sync run.
class SyncOutcome {
  const SyncOutcome({this.pushed = 0, this.failed = 0, this.noop = false});

  final int pushed;
  final int failed;
  final bool noop;
}
