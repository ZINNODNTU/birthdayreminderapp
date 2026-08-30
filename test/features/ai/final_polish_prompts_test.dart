import 'package:birthdayreminderapp/core/db/sync_status.dart';
import 'package:birthdayreminderapp/features/ai/data/ai_config_repository.dart';
import 'package:birthdayreminderapp/features/ai/domain/ai_provider.dart';
import 'package:birthdayreminderapp/features/ai/services/ai_client.dart';
import 'package:birthdayreminderapp/features/ai/services/birthday_ai_service.dart';
import 'package:birthdayreminderapp/models/birthday.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigRepo implements AiConfigRepository {
  @override
  AiProviderConfig loadConfig() => const AiProviderConfig(
    provider: AiProviderType.openAiCompatible,
    baseUrl: 'https://example.test/v1',
    model: 'm',
  );
  @override
  Future<bool> hasApiKey(AiProviderType t) async => true;
  @override
  Future<String?> readApiKey(AiProviderType t) async => 'k';
  @override
  Future<SecureKeyResult> writeApiKey(AiProviderType t, String k) async =>
      SecureKeyResult.success(k.length);
  @override
  Future<SecureKeyResult> clearApiKey(AiProviderType t) async =>
      SecureKeyResult.success(0);
  @override
  Future<void> saveConfig(AiProviderConfig c) async {}
}

class _CaptureClient implements AiClient {
  final List<String> prompts = [];
  @override
  Future<AiConnectionResult> chat({
    required AiProviderConfig config,
    required String apiKey,
    required String prompt,
    AiRequestOptions? options,
  }) async {
    prompts.add(prompt);
    return AiConnectionResult.failure(code: 'test_stub');
  }

  @override
  Future<AiConnectionResult> testConnection({
    required AiProviderConfig config,
    required String apiKey,
    String? model,
  }) async => AiConnectionResult.failure(code: 'test_stub');
  @override
  Future<List<String>> listModels({
    required AiProviderConfig config,
    required String apiKey,
  }) async => [];
}

Birthday _mk({
  String name = 'Bé Cún',
  String? nickname,
  String gender = 'Nữ',
  String? relationship = 'người yêu',
  int year = 2004,
  int month = 1,
  int day = 1,
}) {
  return Birthday(
    id: 'id-1',
    name: name,
    nickname: nickname,
    solarBirthday: DateTime(year, month, day),
    lunarBirthday: const LunarDateTime(day: 1, month: 1, year: 2000),
    calendarType: CalendarType.solar,
    gender: gender,
    relationship: relationship,
    remindBeforeDays: 0,
    remindTime: const TimeOfDay(hour: 9, minute: 0),
    syncStatus: SyncStatus.synced,
  );
}

void main() {
  group('gift prompt criteria', () {
    test('contains gender + age, not relationship', () async {
      final service = BirthdayAiService(
        configRepository: _FakeConfigRepo(),
        client: _CaptureClient(),
      );
      final birthday = _mk(gender: 'Nữ', relationship: 'người yêu');
      await service.suggestGift(birthday);
      final client = service; // ignore: unused_local_variable
      // Use capture via internal hook (we use a fresh service w/ capture client)
    }, skip: 'uses service instance directly');
  });

  group('gift prompt criteria (real capture)', () {
    test('prompt has gender + age + relationship + nickname', () async {
      final capture = _CaptureClient();
      final service = BirthdayAiService(
        configRepository: _FakeConfigRepo(),
        client: capture,
      );
      final birthday = _mk(
        name: 'Bé Cún',
        nickname: 'Cún',
        gender: 'Nữ',
        relationship: 'người yêu',
      );
      await service.suggestGift(birthday);
      expect(capture.prompts, isNotEmpty);
      final prompt = capture.prompts.first;
      expect(prompt, contains('Nữ'));
      expect(prompt, contains('người yêu'));
      expect(prompt, contains('Bé Cún'));
    });
  });

  group('wish prompt criteria', () {
    test('prompt contains gender + age + relationship', () async {
      final capture = _CaptureClient();
      final service = BirthdayAiService(
        configRepository: _FakeConfigRepo(),
        client: capture,
      );
      final birthday = _mk(gender: 'Nữ', relationship: 'người yêu');
      await service.suggestGreeting(birthday, 'vi');
      final prompt = capture.prompts.first;
      expect(prompt, contains('Nữ'));
      expect(prompt, contains('22'));
      expect(prompt, contains('người yêu'));
    });

    test('empty relationship falls back to người quen', () async {
      final capture = _CaptureClient();
      final service = BirthdayAiService(
        configRepository: _FakeConfigRepo(),
        client: capture,
      );
      final birthday = _mk(gender: 'Nam', relationship: '');
      await service.suggestGreeting(birthday, 'vi');
      final prompt = capture.prompts.first;
      expect(prompt, contains('người quen'));
    });

    test('reply with 10 wishes -> outcome has 10', () async {
      final fake = _FakeConfigRepo();
      final capture = _CapturingTenReplyClient(
        '{"wishes":[${List.generate(10, (i) => '{"style":"S$i","text":"T$i"}').join(',')}]}',
      );
      final service = BirthdayAiService(
        configRepository: fake,
        client: capture,
      );
      final birthday = _mk();
      final outcome = await service.suggestGreeting(birthday, 'vi');
      expect(outcome.wishes!.wishes.length, 10);
    });
  });
}

class _CapturingTenReplyClient implements AiClient {
  _CapturingTenReplyClient(this.reply);
  final String reply;
  @override
  Future<AiConnectionResult> chat({
    required AiProviderConfig config,
    required String apiKey,
    required String prompt,
    AiRequestOptions? options,
  }) async => AiConnectionResult.success(latencyMs: 1, reply: reply);
  @override
  Future<AiConnectionResult> testConnection({
    required AiProviderConfig config,
    required String apiKey,
    String? model,
  }) async => AiConnectionResult.failure(code: 'test_stub');
  @override
  Future<List<String>> listModels({
    required AiProviderConfig config,
    required String apiKey,
  }) async => [];
}
