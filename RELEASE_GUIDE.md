# Release Guide

## Lệnh release duy nhất

Từ branch `main`, working tree sạch:

```powershell
pwsh -File scripts/release/release.ps1 -Version x.x.x
```

Ví dụ từ `2.0.5+8` lên `2.1.0+9`:

```powershell
pwsh -File scripts/release/release.ps1 -Version 2.1.0
```

Script chạy lần lượt: `flutter clean`, `flutter pub get`, format check, analyze, test; tăng build; commit `pubspec.yaml`; tạo tag; atomic push `main` và tag. Tag kích hoạt GitHub Actions, build APK ký production, kiểm tra version/chữ ký/SHA-256, tạo metadata, release notes và GitHub Release.

Giả lập không sửa file/Git, không publish:

```powershell
pwsh -File scripts/release/release.ps1 -Version x.x.x -DryRun
```

## GitHub Secrets bắt buộc

Repository **Settings → Secrets and variables → Actions**:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_RELEASE_CERT_SHA256`

`GITHUB_TOKEN` do GitHub Actions cấp tự động. Không tạo hoặc hardcode personal access token. Không commit keystore hoặc `android/key.properties`. Luôn dùng cùng production signing key; đổi key làm Android không thể update tại chỗ.

## Release notes

Dùng Conventional Commits để phân loại tự động:

- `feat: ...` hoặc `feat(scope): ...` — Tính năng mới.
- `fix: ...` hoặc `fix(scope): ...` — Bug đã fix.
- `feat!: ...` hoặc nội dung `BREAKING CHANGE` — Breaking changes.

## Rollback

Không xóa, force-push hoặc thay nội dung tag/release đã phát hành.

1. Xác định commit gây lỗi.
2. `git revert <commit>` trên `main`.
3. Test.
4. Phát hành PATCH mới bằng script, ví dụ `2.1.1`.
5. Nếu cần, đánh dấu release lỗi là prerelease trên GitHub; không tái sử dụng version/build cũ.

Người đã cài APK chỉ nhận bản có version cao hơn. Vì vậy rollback kỹ thuật luôn là forward-fix.

## Lỗi build

- **Working tree is not clean**: commit hoặc stash thay đổi; chạy lại.
- **Format check failed**: chạy `dart format lib test`, review, commit.
- **Analyze/Test failed**: sửa lỗi được in ngay sau tên bước; chạy dry-run lại.
- **Missing signing secrets**: thêm đủ 5 secrets; không dùng debug key thay thế.
- **Signer mismatch**: kiểm tra base64 keystore và `ANDROID_RELEASE_CERT_SHA256`; không phát hành bằng key khác.
- **Tag exists**: chọn version mới. Không ghi đè tag.
- **Push failed**: kiểm tra quyền/branch protection. Script báo local commit/tag còn lại; kiểm tra `git status` và `git tag --list vX.Y.Z` trước khi retry.
- **Workflow lỗi sau push**: mở GitHub Actions, sửa workflow/code, phát hành version PATCH mới. Có thể chạy `workflow_dispatch` với tag cũ và `dry_run=true` để chẩn đoán; chỉ đặt false khi tag chưa có GitHub Release hợp lệ.

## Hotfix

```powershell
git switch main
git pull --ff-only
# sửa lỗi, thêm test, commit
pwsh -File scripts/release/release.ps1 -Version <PATCH_MỚI> -DryRun
pwsh -File scripts/release/release.ps1 -Version <PATCH_MỚI>
```

Hotfix vẫn phải qua toàn bộ quality gate, signing verification và SHA-256. Không bỏ test, không build APK thủ công để thay asset release.

## Cập nhật trong app

App kiểm tra GitHub Release API công khai sau khi khởi động, tối đa mỗi 12 giờ. Khi có SemVer mới, app hiển thị `Cập nhật ngay` hoặc `Để sau`. APK chỉ được cài sau khi SHA-256 khớp `release-metadata.json`; không cần GitHub token trong app.
