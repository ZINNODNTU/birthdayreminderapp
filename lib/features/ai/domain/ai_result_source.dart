/// Where the items shown in a sheet actually came from. Surfaced in the
/// UI as a tiny source label so users can tell whether the model
/// responded or whether the app fell back to its local templates.
enum AiResultSource {
  /// All `>= kGiftTargetCount` items came from the model.
  ai,

  /// AI supplied some items; the rest are local fallback. We never
  /// present partial AI as fully AI — the source label makes it
  /// obvious.
  mixed,

  /// No usable AI reply (timeout / network / empty / invalid). The sheet
  /// was filled entirely by the deterministic local engine.
  localFallback,
}
