import 'dart:async';

import '../../../core/logging/app_logger.dart';
import '../../../models/birthday.dart';
import '../data/ai_cache_storage.dart';
import '../data/ai_config_repository.dart';
import '../domain/ai_provider.dart';
import '../domain/ai_result_source.dart';
import '../domain/birthday_ai_person_context.dart';
import 'ai_client.dart';
import 'ai_response_parsers.dart';
import 'birthday_wish_fallback_engine.dart';
import 'gift_fallback_engine.dart';

/// Centralised AI surface used by Birthday Detail screens. Always reads
/// the saved [AiConfigRepository] config + secure-storage API key — the
/// same key the AiTrialView uses — so the user has exactly one source
/// of truth.
///
/// AI V3 contract:
///   * Every tap builds a fresh [BirthdayAiPersonContext] from the
///     CURRENT displayed Birthday. No global context, no reuse across
///     different birthdays.
///   * Cache key includes `contextHash` (name + nickname + gender +
///     age + relationship) so two birthdays with identical age/gender
///     never share cache.
///   * Gift prompt + fallback now use name + nickname + gender + age +
///     relationship (relationship is a first-class gift criterion).
///   * Wish prompt + fallback use the same context plus language;
///     templates call the person by name/nickname naturally.
///   * Hybrid AI + local fallback. 24h cache. "Tạo lại" bypasses.
class BirthdayAiService {
  BirthdayAiService({
    required AiConfigRepository configRepository,
    required AiClient client,
    GiftSuggestionsParser? giftParser,
    BirthdayWishParser? wishParser,
    GiftFallbackEngine? giftFallback,
    BirthdayWishFallbackEngine? wishFallback,
    AiCacheStorage? cacheStorage,
    DateTime Function()? now,
  }) : _repo = configRepository,
       _client = client,
       _giftParser = giftParser ?? const GiftSuggestionsParser(),
       _wishParser = wishParser ?? const BirthdayWishParser(),
       _giftFallback = giftFallback ?? const GiftFallbackEngine(),
       _wishFallback = wishFallback ?? const BirthdayWishFallbackEngine(),
       _cacheStorage = cacheStorage;

  static const int kGreetingTokenBudget = 900;

  final AiConfigRepository _repo;
  final AiClient _client;
  final GiftSuggestionsParser _giftParser;
  final BirthdayWishParser _wishParser;
  final GiftFallbackEngine _giftFallback;
  final BirthdayWishFallbackEngine _wishFallback;
  final AiCacheStorage? _cacheStorage;

  /// True when a config + key exist and the saved config is usable.
  Future<bool> isAvailable() async {
    final config = _repo.loadConfig();
    if (config.model.isEmpty) return false;
    return _repo.hasApiKey(config.provider);
  }

  AiProviderConfig currentConfig() => _repo.loadConfig();

  /// Build a fresh V3 person context for [birthday]. Call this on every
  /// tap — never reuse a cached context across birthdays.
  BirthdayAiPersonContext contextFor(Birthday birthday) =>
      BirthdayAiPersonContext.fromBirthday(birthday);

  /// Generate ~10 gift suggestions. Returns a [GiftAiOutcome] that
  /// always carries at least `kGiftTargetCount` items — falling back
  /// to the local engine if the model fails or returns too few.
  Future<GiftAiOutcome> suggestGift(
    Birthday birthday, {
    bool bypassCache = false,
  }) async {
    final config = _repo.loadConfig();
    final ctx = contextFor(birthday);
    final keyRaw = await _repo.readApiKey(config.provider);
    final canUseAi = (keyRaw != null && keyRaw.isNotEmpty);
    final key = keyRaw ?? '';

    final stopwatch = Stopwatch()..start();

    if (canUseAi && _cacheStorage != null && !bypassCache) {
      final cached = _cacheStorage.readGifts(
        birthdayId: ctx.birthdayId,
        contextHash: ctx.contextHash,
        provider: config.provider.name,
        model: config.model,
      );
      if (cached != null && cached.length >= kGiftTargetCount) {
        final items =
            cached.map(_giftFromMap).whereType<GiftSuggestion>().toList();
        if (items.length >= kGiftTargetCount) {
          _logMetric(
            feature: 'gift',
            provider: config.provider.name,
            model: config.model,
            elapsedMs: 0,
            source: AiResultSource.ai,
            aiCount: items.length,
            finalCount: items.length,
            timedOut: false,
            cache: 'hit',
          );
          return GiftAiOutcome(
            connection: AiConnectionResult.success(latencyMs: 0, reply: ''),
            suggestions: GiftSuggestionResult(
              items: items.take(kGiftTargetCount).toList(),
            ),
            raw: null,
            source: AiResultSource.ai,
            fromCache: true,
            context: ctx,
          );
        }
      }
    }

    if (!canUseAi) {
      return _localOnlyGifts(
        ctx,
        reason: 'no_api_key',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }

    final prompt = _buildGiftPrompt(ctx);
    final options = const AiRequestOptions(
      timeout: AiTimeouts.gift,
      maxTokens: kGreetingTokenBudget,
    );

    AppLogger.info(
      '[AiFeature]',
      'start feature=gift provider=${config.provider.name} model=${config.model} '
          'timeoutMs=${options.timeout!.inMilliseconds} promptChars=${prompt.length}',
    );

    AiConnectionResult first;
    try {
      first = await _client
          .chat(config: config, apiKey: key, prompt: prompt, options: options)
          .timeout(
            const Duration(seconds: 27),
            onTimeout:
                () => AiConnectionResult.failure(
                  code: 'timeout',
                  message: 'Quá thời gian phản hồi',
                ),
          );
    } on TimeoutException {
      first = AiConnectionResult.failure(
        code: 'timeout',
        message: 'Quá thời gian phản hồi',
      );
    } catch (e) {
      first = AiConnectionResult.failure(code: 'network', message: '$e');
    }

    if (!first.ok) {
      _logMetric(
        feature: 'gift',
        provider: config.provider.name,
        model: config.model,
        elapsedMs: stopwatch.elapsedMilliseconds,
        source: AiResultSource.localFallback,
        aiCount: 0,
        finalCount: kGiftTargetCount,
        timedOut: first.errorCode == 'timeout',
        cache: bypassCache ? 'bypass' : 'miss',
      );
      final local = _giftFallback.suggestions(
        gender: ctx.gender,
        age: ctx.age,
        relationship: ctx.relationship,
        name: ctx.name,
        nickname: ctx.nickname,
      );
      return GiftAiOutcome(
        connection: first,
        suggestions: GiftSuggestionResult(items: local),
        raw: null,
        source: AiResultSource.localFallback,
        context: ctx,
      );
    }

    final parsed = _giftParser.parse(first.reply);
    final aiItems = parsed.items;

    // Repair only when >=6 items returned and a quick retry is likely
    // to close the gap; otherwise fall back to merging local items.
    if (aiItems.length < kGiftTargetCount) {
      if (aiItems.length >= 6) {
        final repair = await _tryRepairGifts(
          config: config,
          key: key,
          ctx: ctx,
          existing: parsed,
          options: options,
        );
        if (repair != null && repair.items.length >= kGiftTargetCount) {
          _logMetric(
            feature: 'gift',
            provider: config.provider.name,
            model: config.model,
            elapsedMs: stopwatch.elapsedMilliseconds,
            source: AiResultSource.ai,
            aiCount: repair.items.length,
            finalCount: repair.items.length,
            timedOut: false,
            cache: bypassCache ? 'bypass' : 'miss',
          );
          await _maybeWriteGiftsCache(
            ctx: ctx,
            items: repair.items,
            bypass: bypassCache,
          );
          return GiftAiOutcome(
            connection: first,
            suggestions: GiftSuggestionResult(
              items: repair.items.take(kGiftTargetCount).toList(),
            ),
            raw: null,
            source: AiResultSource.ai,
            context: ctx,
          );
        }
      }
      final local = _giftFallback.suggestions(
        gender: ctx.gender,
        age: ctx.age,
        relationship: ctx.relationship,
        name: ctx.name,
        nickname: ctx.nickname,
      );
      final merged = _mergeToTarget(aiItems, local);
      _logMetric(
        feature: 'gift',
        provider: config.provider.name,
        model: config.model,
        elapsedMs: stopwatch.elapsedMilliseconds,
        source: AiResultSource.mixed,
        aiCount: aiItems.length,
        finalCount: merged.length,
        timedOut: false,
        cache: bypassCache ? 'bypass' : 'miss',
      );
      await _maybeWriteGiftsCache(ctx: ctx, items: merged, bypass: bypassCache);
      return GiftAiOutcome(
        connection: first,
        suggestions: GiftSuggestionResult(items: merged),
        raw: null,
        source: AiResultSource.mixed,
        context: ctx,
      );
    }

    _logMetric(
      feature: 'gift',
      provider: config.provider.name,
      model: config.model,
      elapsedMs: stopwatch.elapsedMilliseconds,
      source: AiResultSource.ai,
      aiCount: aiItems.length,
      finalCount: aiItems.length,
      timedOut: false,
      cache: bypassCache ? 'bypass' : 'miss',
    );
    await _maybeWriteGiftsCache(
      ctx: ctx,
      items: aiItems.take(kGiftTargetCount).toList(),
      bypass: bypassCache,
    );
    return GiftAiOutcome(
      connection: first,
      suggestions: GiftSuggestionResult(
        items: aiItems.take(kGiftTargetCount).toList(),
      ),
      raw: null,
      source: AiResultSource.ai,
      context: ctx,
    );
  }

  /// Generate ~10 wishes. Same hybrid contract as gifts.
  Future<WishAiOutcome> suggestGreeting(
    Birthday birthday,
    String language, {
    bool bypassCache = false,
  }) async {
    final config = _repo.loadConfig();
    final ctx = contextFor(birthday);
    final keyRaw = await _repo.readApiKey(config.provider);
    final canUseAi = (keyRaw != null && keyRaw.isNotEmpty);
    final key = keyRaw ?? '';

    final stopwatch = Stopwatch()..start();

    if (canUseAi && _cacheStorage != null && !bypassCache) {
      final cached = _cacheStorage.readWishes(
        birthdayId: ctx.birthdayId,
        contextHash: ctx.contextHash,
        language: language,
        provider: config.provider.name,
        model: config.model,
      );
      if (cached != null && cached.length >= kWishTargetCount) {
        final items =
            cached.map(_wishFromMap).whereType<BirthdayWish>().toList();
        if (items.length >= kWishTargetCount) {
          _logMetric(
            feature: 'wish',
            provider: config.provider.name,
            model: config.model,
            elapsedMs: 0,
            source: AiResultSource.ai,
            aiCount: items.length,
            finalCount: items.length,
            timedOut: false,
            cache: 'hit',
          );
          return WishAiOutcome(
            connection: AiConnectionResult.success(latencyMs: 0, reply: ''),
            wishes: BirthdayWishResult(
              wishes: items.take(kWishTargetCount).toList(),
            ),
            raw: null,
            source: AiResultSource.ai,
            fromCache: true,
            context: ctx,
          );
        }
      }
    }

    if (!canUseAi) {
      final local = _wishFallback.wishes(
        name: ctx.name,
        nickname: ctx.nickname,
        gender: ctx.gender,
        age: ctx.age,
        relationship: ctx.relationship,
        language: language,
      );
      _logMetric(
        feature: 'wish',
        provider: config.provider.name,
        model: config.model,
        elapsedMs: stopwatch.elapsedMilliseconds,
        source: AiResultSource.localFallback,
        aiCount: 0,
        finalCount: local.length,
        timedOut: false,
        cache: bypassCache ? 'bypass' : 'miss',
        reason: 'no_api_key',
      );
      return WishAiOutcome(
        connection: AiConnectionResult.failure(
          code: 'no_api_key',
          message: 'Chưa cấu hình API key.',
        ),
        wishes: BirthdayWishResult(wishes: local),
        raw: null,
        source: AiResultSource.localFallback,
        context: ctx,
      );
    }

    final prompt = _buildWishPrompt(ctx: ctx, language: language);
    final options = const AiRequestOptions(
      timeout: AiTimeouts.wish,
      maxTokens: kGreetingTokenBudget,
    );
    AppLogger.info(
      '[AiFeature]',
      'start feature=wish provider=${config.provider.name} model=${config.model} '
          'lang=$language timeoutMs=${options.timeout!.inMilliseconds}',
    );

    AiConnectionResult first;
    try {
      first = await _client
          .chat(config: config, apiKey: key, prompt: prompt, options: options)
          .timeout(
            const Duration(seconds: 27),
            onTimeout:
                () => AiConnectionResult.failure(
                  code: 'timeout',
                  message: 'Quá thời gian phản hồi',
                ),
          );
    } on TimeoutException {
      first = AiConnectionResult.failure(
        code: 'timeout',
        message: 'Quá thời gian phản hồi',
      );
    } catch (e) {
      first = AiConnectionResult.failure(code: 'network', message: '$e');
    }

    if (!first.ok) {
      final local = _wishFallback.wishes(
        name: ctx.name,
        nickname: ctx.nickname,
        gender: ctx.gender,
        age: ctx.age,
        relationship: ctx.relationship,
        language: language,
      );
      _logMetric(
        feature: 'wish',
        provider: config.provider.name,
        model: config.model,
        elapsedMs: stopwatch.elapsedMilliseconds,
        source: AiResultSource.localFallback,
        aiCount: 0,
        finalCount: local.length,
        timedOut: first.errorCode == 'timeout',
        cache: bypassCache ? 'bypass' : 'miss',
      );
      return WishAiOutcome(
        connection: first,
        wishes: BirthdayWishResult(wishes: local),
        raw: null,
        source: AiResultSource.localFallback,
        context: ctx,
      );
    }

    final parsed = _wishParser.parse(first.reply);
    final aiItems = parsed.wishes;
    if (aiItems.length < kWishTargetCount) {
      if (aiItems.length >= 6) {
        final repair = await _tryRepairWishes(
          config: config,
          key: key,
          ctx: ctx,
          language: language,
          existing: parsed,
          options: options,
        );
        if (repair != null && repair.wishes.length >= kWishTargetCount) {
          _logMetric(
            feature: 'wish',
            provider: config.provider.name,
            model: config.model,
            elapsedMs: stopwatch.elapsedMilliseconds,
            source: AiResultSource.ai,
            aiCount: repair.wishes.length,
            finalCount: repair.wishes.length,
            timedOut: false,
            cache: bypassCache ? 'bypass' : 'miss',
          );
          await _maybeWriteWishesCache(
            ctx: ctx,
            language: language,
            items: repair.wishes,
            bypass: bypassCache,
          );
          return WishAiOutcome(
            connection: first,
            wishes: BirthdayWishResult(
              wishes: repair.wishes.take(kWishTargetCount).toList(),
            ),
            raw: null,
            source: AiResultSource.ai,
            context: ctx,
          );
        }
      }
      final local = _wishFallback.wishes(
        name: ctx.name,
        nickname: ctx.nickname,
        gender: ctx.gender,
        age: ctx.age,
        relationship: ctx.relationship,
        language: language,
      );
      final merged = _mergeWishesToTarget(aiItems, local);
      _logMetric(
        feature: 'wish',
        provider: config.provider.name,
        model: config.model,
        elapsedMs: stopwatch.elapsedMilliseconds,
        source: AiResultSource.mixed,
        aiCount: aiItems.length,
        finalCount: merged.length,
        timedOut: false,
        cache: bypassCache ? 'bypass' : 'miss',
      );
      await _maybeWriteWishesCache(
        ctx: ctx,
        language: language,
        items: merged,
        bypass: bypassCache,
      );
      return WishAiOutcome(
        connection: first,
        wishes: BirthdayWishResult(wishes: merged),
        raw: null,
        source: AiResultSource.mixed,
        context: ctx,
      );
    }

    _logMetric(
      feature: 'wish',
      provider: config.provider.name,
      model: config.model,
      elapsedMs: stopwatch.elapsedMilliseconds,
      source: AiResultSource.ai,
      aiCount: aiItems.length,
      finalCount: aiItems.length,
      timedOut: false,
      cache: bypassCache ? 'bypass' : 'miss',
    );
    await _maybeWriteWishesCache(
      ctx: ctx,
      language: language,
      items: aiItems.take(kWishTargetCount).toList(),
      bypass: bypassCache,
    );
    return WishAiOutcome(
      connection: first,
      wishes: BirthdayWishResult(
        wishes: aiItems.take(kWishTargetCount).toList(),
      ),
      raw: null,
      source: AiResultSource.ai,
      context: ctx,
    );
  }

  // ---------------------------------------------------------------------------
  // Prompts (V3 compact schema, name/nickname/relationship aware)
  // ---------------------------------------------------------------------------

  String _buildGiftPrompt(BirthdayAiPersonContext ctx) {
    final displayName = ctx.name.isEmpty ? 'bạn' : ctx.name;
    final nicknamePart =
        ctx.nickname.isEmpty ? '' : 'Biệt danh: ${ctx.nickname}\n';
    final genderText = ctx.gender.isEmpty ? 'chưa xác định' : ctx.gender;
    final relText = ctx.relationship.isEmpty ? 'người quen' : ctx.relationship;
    return [
      'Bạn đang chọn quà sinh nhật RIÊNG cho:',
      'Tên: $displayName',
      nicknamePart.trim(),
      'Giới tính: $genderText',
      'Tuổi: ${ctx.age}',
      'Mối quan hệ với người dùng: $relText',
      '',
      'Hãy đề xuất đúng $kGiftTargetCount món quà phù hợp riêng với người này.',
      'Yêu cầu:',
      '- cân nhắc tuổi',
      '- cân nhắc giới tính nhưng tránh định kiến',
      '- cân nhắc mối quan hệ (quà cho $relText phải khác sắc thái quà cho các vai trò khác)',
      '- phù hợp độ tuổi',
      '- $kGiftTargetCount loại khác nhau',
      '- không lặp ý',
      '- tiếng Việt',
      '- ngân sách VNĐ',
      '- lý do <= 15 từ',
      '- JSON compact only',
      '',
      'Schema (compact):',
      '{"g":[{"n":"...","r":"...","b":"...","c":"..."}]}',
    ].where((s) => s.isNotEmpty).join('\n');
  }

  String _buildWishPrompt({
    required BirthdayAiPersonContext ctx,
    required String language,
  }) {
    final langText = switch (language) {
      'en' => 'English',
      'zh' => '中文',
      _ => 'Tiếng Việt',
    };
    final displayName = ctx.name.isEmpty ? 'bạn' : ctx.name;
    final nicknamePart =
        ctx.nickname.isEmpty ? '' : 'Biệt danh: ${ctx.nickname}\n';
    final genderText = ctx.gender.isEmpty ? 'chưa xác định' : ctx.gender;
    final relText = ctx.relationship.isEmpty ? 'người quen' : ctx.relationship;
    return [
      'Trả JSON đúng $kWishTargetCount câu chúc sinh nhật.',
      'Tên: $displayName',
      nicknamePart.trim(),
      'Giới tính: $genderText',
      'Tuổi: ${ctx.age}',
      'Mối quan hệ: $relText',
      'Ngôn ngữ: $langText',
      '',
      'Yêu cầu:',
      '- Mỗi câu phải dành riêng cho người này (gọi tên hoặc biệt danh khi tự nhiên, không máy móc)',
      '- Tông giọng theo vai trò: $relText (trang trọng / thân mật / lãng mạn / hài hước tuỳ quan hệ)',
      '- Ít nhất 7/10 câu nên dùng tên hoặc biệt danh khi phù hợp',
      '- Mỗi câu: s=phong cách ngắn, t=câu chúc hay',
      '- Không markdown. Không giải thích ngoài JSON.',
      '',
      'Schema (compact):',
      '{"w":[{"s":"...","t":"..."}]}',
    ].where((s) => s.isNotEmpty).join('\n');
  }

  // ---------------------------------------------------------------------------
  // Repair (only fires when >= 6 items returned)
  // ---------------------------------------------------------------------------

  Future<_RepairResult?> _tryRepairGifts({
    required AiProviderConfig config,
    required String key,
    required BirthdayAiPersonContext ctx,
    required GiftSuggestionResult existing,
    required AiRequestOptions options,
  }) async {
    final missing = kGiftTargetCount - existing.items.length;
    if (missing <= 0) return null;
    final existingNames = existing.items.map((g) => g.name).join('; ');
    final prompt =
        StringBuffer()
          ..writeln(
            'Bổ sung $missing món quà mới hoàn toàn khác với: $existingNames.',
          )
          ..writeln(
            'Cho người: tên=${ctx.name}, biệt danh=${ctx.nickname}, '
            'giới tính=${ctx.gender}, tuổi=${ctx.age}, '
            'quan hệ=${ctx.relationship}.',
          )
          ..writeln(
            'Schema: {"g":[{"n":"...","r":"...","b":"...","c":"..."}]}.',
          );
    AppLogger.info('[AiFeature]', 'feature=gift repair missing=$missing');
    final stopwatch = Stopwatch()..start();
    final r = await _client
        .chat(
          config: config,
          apiKey: key,
          prompt: prompt.toString(),
          options: options,
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => _connectionFailure('repair_timeout'),
        );
    stopwatch.stop();
    if (!r.ok) return null;
    final merged = _giftParser.parse(r.reply);
    final deduped = <GiftSuggestion>[];
    final seen = <String>{};
    for (final g in existing.items) {
      final k = _norm(g.name);
      if (seen.add(k)) deduped.add(g);
    }
    for (final g in merged.items) {
      final k = _norm(g.name);
      if (seen.add(k)) deduped.add(g);
      if (deduped.length >= kGiftTargetCount) break;
    }
    return _RepairResult(
      items: deduped,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }

  Future<_RepairWishResult?> _tryRepairWishes({
    required AiProviderConfig config,
    required String key,
    required BirthdayAiPersonContext ctx,
    required String language,
    required BirthdayWishResult existing,
    required AiRequestOptions options,
  }) async {
    final missing = kWishTargetCount - existing.wishes.length;
    if (missing <= 0) return null;
    final existingTexts = existing.wishes.map((w) => w.text).join('; ');
    final prompt =
        StringBuffer()
          ..writeln(
            'Bổ sung $missing câu chúc mới khác hoàn toàn: $existingTexts.',
          )
          ..writeln(
            'Cho: tên=${ctx.name}, biệt danh=${ctx.nickname}, '
            'giới tính=${ctx.gender}, tuổi=${ctx.age}, '
            'quan hệ=${ctx.relationship}.',
          )
          ..writeln(
            'Ngôn ngữ: ${language == "en" ? "English" : (language == "zh" ? "中文" : "Tiếng Việt")}.',
          )
          ..writeln('Schema: {"w":[{"s":"...","t":"..."}]}.');
    AppLogger.info('[AiFeature]', 'feature=wish repair missing=$missing');
    final stopwatch = Stopwatch()..start();
    final r = await _client
        .chat(
          config: config,
          apiKey: key,
          prompt: prompt.toString(),
          options: options,
        )
        .timeout(
          const Duration(seconds: 12),
          onTimeout: () => _connectionFailure('repair_timeout'),
        );
    stopwatch.stop();
    if (!r.ok) return null;
    final merged = _wishParser.parse(r.reply);
    final deduped = <BirthdayWish>[];
    final seen = <String>{};
    for (final w in existing.wishes) {
      final k = _norm(w.text);
      if (seen.add(k)) deduped.add(w);
    }
    for (final w in merged.wishes) {
      final k = _norm(w.text);
      if (seen.add(k)) deduped.add(w);
      if (deduped.length >= kWishTargetCount) break;
    }
    return _RepairWishResult(
      wishes: deduped,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }

  // ---------------------------------------------------------------------------
  // Local fallback helpers
  // ---------------------------------------------------------------------------

  GiftAiOutcome _localOnlyGifts(
    BirthdayAiPersonContext ctx, {
    required String reason,
    required int elapsedMs,
  }) {
    final local = _giftFallback.suggestions(
      gender: ctx.gender,
      age: ctx.age,
      relationship: ctx.relationship,
      name: ctx.name,
      nickname: ctx.nickname,
    );
    _logMetric(
      feature: 'gift',
      provider: 'none',
      model: 'none',
      elapsedMs: elapsedMs,
      source: AiResultSource.localFallback,
      aiCount: 0,
      finalCount: local.length,
      timedOut: false,
      cache: 'bypass',
      reason: reason,
    );
    return GiftAiOutcome(
      connection: AiConnectionResult.failure(
        code: reason,
        message: 'Sử dụng gợi ý nhanh.',
      ),
      suggestions: GiftSuggestionResult(items: local),
      raw: null,
      source: AiResultSource.localFallback,
      context: ctx,
    );
  }

  List<GiftSuggestion> _mergeToTarget(
    List<GiftSuggestion> primary,
    List<GiftSuggestion> filler,
  ) {
    final out = <GiftSuggestion>[];
    final seen = <String>{};
    for (final e in [...primary, ...filler]) {
      final k = _norm(e.name);
      if (k.isEmpty) continue;
      if (seen.add(k)) out.add(e);
      if (out.length >= kGiftTargetCount) break;
    }
    return out;
  }

  List<BirthdayWish> _mergeWishesToTarget(
    List<BirthdayWish> primary,
    List<BirthdayWish> filler,
  ) {
    final out = <BirthdayWish>[];
    final seen = <String>{};
    for (final e in [...primary, ...filler]) {
      final k = _norm(e.text);
      if (k.isEmpty) continue;
      if (seen.add(k)) out.add(e);
      if (out.length >= kWishTargetCount) break;
    }
    return out;
  }

  Future<void> _maybeWriteGiftsCache({
    required BirthdayAiPersonContext ctx,
    required List<GiftSuggestion> items,
    required bool bypass,
  }) async {
    if (_cacheStorage == null || bypass) return;
    final config = _repo.loadConfig();
    final mapped =
        items
            .take(kGiftTargetCount)
            .map(
              (e) => <String, dynamic>{
                'name': e.name,
                'reason': e.reason,
                'budget': e.budget,
                'category': e.category,
              },
            )
            .toList();
    await _cacheStorage.writeGifts(
      birthdayId: ctx.birthdayId,
      contextHash: ctx.contextHash,
      provider: config.provider.name,
      model: config.model,
      items: mapped,
    );
  }

  Future<void> _maybeWriteWishesCache({
    required BirthdayAiPersonContext ctx,
    required String language,
    required List<BirthdayWish> items,
    required bool bypass,
  }) async {
    if (_cacheStorage == null || bypass) return;
    final config = _repo.loadConfig();
    final mapped =
        items
            .take(kWishTargetCount)
            .map((e) => <String, dynamic>{'style': e.style, 'text': e.text})
            .toList();
    await _cacheStorage.writeWishes(
      birthdayId: ctx.birthdayId,
      contextHash: ctx.contextHash,
      language: language,
      provider: config.provider.name,
      model: config.model,
      items: mapped,
    );
  }

  GiftSuggestion? _giftFromMap(Map<String, dynamic> m) {
    final name = (m['name'] ?? m['n'])?.toString();
    if (name == null || name.trim().isEmpty) return null;
    return GiftSuggestion(
      name: name.trim(),
      reason: (m['reason'] ?? m['r'])?.toString(),
      budget: (m['budget'] ?? m['b'])?.toString(),
      category: (m['category'] ?? m['c'])?.toString(),
    );
  }

  BirthdayWish? _wishFromMap(Map<String, dynamic> m) {
    final text = (m['text'] ?? m['t'])?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return BirthdayWish(
      style: ((m['style'] ?? m['s'])?.toString() ?? 'Câu chúc').trim(),
      text: text.trim(),
    );
  }

  AiConnectionResult _connectionFailure(String code) =>
      AiConnectionResult.failure(code: code, message: 'Quá thời gian phản hồi');

  String _norm(String s) => s.toLowerCase().trim();

  void _logMetric({
    required String feature,
    required String provider,
    required String model,
    required int elapsedMs,
    required AiResultSource source,
    required int aiCount,
    required int finalCount,
    required bool timedOut,
    required String cache,
    String? reason,
  }) {
    AppLogger.info(
      '[AiFeature]',
      'feature=$feature '
          'provider=${provider.isEmpty ? "none" : provider} '
          'model=${model.isEmpty ? "none" : model} '
          'elapsedMs=$elapsedMs '
          'status=${source.name} '
          'aiItemCount=$aiCount '
          'finalItemCount=$finalCount '
          'cache=$cache '
          'timeout=$timedOut '
          '${reason == null ? "" : "reason=$reason"}',
    );
  }
}

class _RepairResult {
  _RepairResult({required this.items, required this.elapsedMs});
  final List<GiftSuggestion> items;
  final int elapsedMs;
}

class _RepairWishResult {
  _RepairWishResult({required this.wishes, required this.elapsedMs});
  final List<BirthdayWish> wishes;
  final int elapsedMs;
}

class GiftAiOutcome {
  const GiftAiOutcome({
    required this.connection,
    this.suggestions,
    this.raw,
    this.source = AiResultSource.ai,
    this.fromCache = false,
    this.context,
  });

  final AiConnectionResult connection;
  final GiftSuggestionResult? suggestions;
  final String? raw;
  final AiResultSource source;
  final bool fromCache;
  final BirthdayAiPersonContext? context;
}

class WishAiOutcome {
  const WishAiOutcome({
    required this.connection,
    this.wishes,
    this.raw,
    this.source = AiResultSource.ai,
    this.fromCache = false,
    this.context,
  });

  final AiConnectionResult connection;
  final BirthdayWishResult? wishes;
  final String? raw;
  final AiResultSource source;
  final bool fromCache;
  final BirthdayAiPersonContext? context;
}
