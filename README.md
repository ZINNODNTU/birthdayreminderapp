# Birthday Reminder 🎂

Ứng dụng Flutter quản lý sinh nhật cá nhân, lịch sinh nhật, ngày âm/dương, nhắc nhở và đồng bộ dữ liệu với Firebase.

> **Project:** `birthdayreminderapp`
> **Version hiện tại:** `2.1.0+9`

## ✨ Tính năng

- 🎂 Thêm, sửa, xóa và xem chi tiết sinh nhật.
- 📅 Lịch sinh nhật theo tháng với `TableCalendar`.
- 🌙 Hỗ trợ ngày sinh nhật âm lịch và dương lịch.
- 🔔 Nhắc sinh nhật bằng local notification.
- 👤 Avatar, biệt danh, mối quan hệ và ghi chú.
- 📱 Import dữ liệu từ danh bạ.
- 📤 Chia sẻ thông tin sinh nhật.
- 💾 Lưu dữ liệu cục bộ bằng SQLite.
- ☁️ Xác thực Google và đồng bộ dữ liệu với Firebase/Cloud Firestore.
- 🤖 AI hỗ trợ gợi ý quà tặng và lời chúc.
- 💾 Sao lưu và khôi phục dữ liệu.
- 🌐 Đa ngôn ngữ: **Tiếng Việt / English / 中文**.
- 🔄 Cập nhật APK thông qua GitHub Release.

## 🏗️ Kiến trúc

```text
lib/
├── app/                         # Bootstrap, app và dependency setup
├── controllers/                 # State/controller chính
├── core/                        # Auth, DB, session, config, errors, logging
├── features/
│   ├── ai/                      # AI providers, clients và services
│   ├── auth/                    # Authentication UI
│   ├── backup/                  # Backup/restore
│   ├── birthdays/               # Birthday repositories/domain
│   ├── onboarding/              # Onboarding
│   ├── reminders/               # Notification/reminder engine
│   ├── settings/                # Settings UI
│   ├── sync/                    # Firebase synchronization
│   └── update/                  # APK update flow
├── l10n/                        # Localization ARB + generated classes
├── models/                      # Data models
├── services/                    # Shared services
├── theme/                       # Theme
├── utils/                       # Utilities
├── views/                       # Main views
└── widgets/                     # Reusable widgets
```

Ứng dụng sử dụng `Provider`/`ChangeNotifier`. SQLite là lớp lưu trữ cục bộ; Firebase Authentication dùng Google Sign-In và dữ liệu birthday cloud được tổ chức theo user.

## 🌐 Localization

Localization sử dụng Flutter `gen-l10n` với:

```text
l10n.yaml
lib/l10n/app_vi.arb
lib/l10n/app_en.arb
lib/l10n/app_zh.arb
```

Sau khi thay đổi `.arb`:

```powershell
flutter gen-l10n
```

Trong widget có thể lấy bản dịch bằng:

```dart
final l10n = context.l10n;
```

Không nên thêm text UI mới bằng string hard-code nếu nội dung cần được dịch.

## 🔄 Đồng bộ dữ liệu

```text
Local SQLite
    │
    ├── Pending changes
    ▼
SyncManager
    ├── Push local changes
    ├── Pull remote changes
    ├── Merge
    └── Update local state
    ▼
Local SQLite + UI
```

Khi thay đổi sync, cần kiểm tra số lượng local, remote, số bản ghi merge thực tế và progress dialog để tránh hiển thị tổng số không nhất quán.

## 🔐 Authentication & Firebase

Các thành phần chính:

```text
lib/core/auth/
lib/features/birthdays/data/birthday_firestore_mapper.dart
lib/features/birthdays/data/birthday_remote_repository.dart
firestore.rules
firebase.json
```

### Bảo mật

- Không commit API key, token, private key hoặc keystore.
- Không hard-code secret vào source code.
- Production signing secrets phải được quản lý bằng GitHub Actions Secrets.
- Kiểm tra `firestore.rules` trước khi thay đổi quyền đọc/ghi.

## 🤖 AI

AI được tổ chức trong `lib/features/ai/`, gồm provider, client và service cho các chức năng như gợi ý quà tặng và lời chúc.

Secret/API credential phải được quản lý an toàn và không đưa trực tiếp vào source code hoặc APK.

## 🧰 Công nghệ

| Thành phần | Công nghệ |
|---|---|
| Framework | Flutter |
| Language | Dart `^3.7.2` |
| State | Provider / ChangeNotifier |
| Local DB | SQLite / `sqflite` |
| Cloud DB | Firebase Cloud Firestore |
| Auth | Firebase Auth + Google Sign-In |
| Calendar | `table_calendar` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Localization | Flutter `gen-l10n` / ARB |
| Preferences | `shared_preferences` |
| AI | OpenAI-compatible / Anthropic / Gemini clients |
| Tests | `flutter_test`, `mocktail` |

## 🚀 Cài đặt

Yêu cầu Flutter SDK tương thích với Dart `^3.7.2`. Android Studio/Android SDK cần thiết cho Android; Xcode cần thiết cho iOS/macOS.

```powershell
git clone <repository-url>
cd birthdayreminderapp
flutter pub get
flutter gen-l10n
```

## ▶️ Chạy ứng dụng

```powershell
flutter run
```

Xem thiết bị:

```powershell
flutter devices
```

Build debug APK:

```powershell
flutter build apk --debug
```

APK mặc định:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## 🧪 Kiểm thử

```powershell
flutter analyze
flutter test
```

Format:

```powershell
dart format lib test
```

Sau thay đổi localization/auth/sync/provider nên chạy:

```powershell
flutter gen-l10n
flutter analyze
flutter test
```

## 📦 Release

Release chính thức dùng script:

```powershell
pwsh -File scripts/release/release.ps1 -Version x.x.x
```

Dry run:

```powershell
pwsh -File scripts/release/release.ps1 -Version x.x.x -DryRun
```

Chi tiết xem `RELEASE_GUIDE.md`, `docs/RELEASE_PROCESS.md` và `docs/RELEASES.md`.

## 📁 Tài liệu

| File | Nội dung |
|---|---|
| `docs/CURRENT_ARCHITECTURE.md` | Kiến trúc và technical debt |
| `docs/DATA_SYNC_DESIGN.md` | Thiết kế đồng bộ dữ liệu |
| `docs/FIRESTORE_SCHEMA.md` | Firestore schema |
| `docs/AUTHENTICATION.md` | Authentication |
| `docs/BACKUP_RESTORE.md` | Backup/restore |
| `docs/NOTIFICATION_ENGINE.md` | Notification engine |
| `docs/RELEASE_PROCESS.md` | Quy trình release |
| `docs/SECURITY_ACTION_REQUIRED.md` | Vấn đề bảo mật cần xử lý |

## 🛠️ Quy tắc phát triển

1. Không commit secret/credential.
2. Không hard-code text UI mới nếu text cần localization.
3. Thay đổi logic quan trọng phải có test tương ứng.
4. Sau khi sửa code chạy format, analyze và test liên quan.
5. Thay đổi sync phải kiểm tra local, remote và UI progress.
6. Không sửa/xóa release tag đã phát hành; dùng version PATCH mới để hotfix.
7. Không bỏ qua quality gate chỉ để tạo APK.

## 📌 Trạng thái

Dự án đang tiếp tục được hoàn thiện. Các khu vực ưu tiên gồm localization toàn ứng dụng, ổn định Firebase synchronization/progress reporting, cập nhật test, notification/lunar scheduling và tăng độ an toàn của credential/production configuration.

## 📄 License

Repository hiện chưa khai báo license công khai. Nếu phát hành công khai, hãy bổ sung file `LICENSE`.
