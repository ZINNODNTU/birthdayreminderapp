import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Birthday Reminder'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @birthdayList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách sinh nhật'**
  String get birthdayList;

  /// No description provided for @todayBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật hôm nay'**
  String get todayBirthdays;

  /// No description provided for @upcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get upcoming;

  /// No description provided for @seeMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get seeMore;

  /// No description provided for @noBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có sinh nhật nào'**
  String get noBirthdays;

  /// No description provided for @birthdayCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sinh nhật'**
  String get birthdayCalendar;

  /// No description provided for @calendarMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get calendarMonth;

  /// No description provided for @calendarDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get calendarDay;

  /// No description provided for @birthdayReminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc sinh nhật'**
  String get birthdayReminder;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @backup.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get restore;

  /// No description provided for @userGuide.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn sử dụng'**
  String get userGuide;

  /// No description provided for @newVersion.
  ///
  /// In vi, this message translates to:
  /// **'Có phiên bản mới'**
  String get newVersion;

  /// No description provided for @updateNow.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngay'**
  String get updateNow;

  /// No description provided for @later.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get later;

  /// No description provided for @whatsNew.
  ///
  /// In vi, this message translates to:
  /// **'Có gì mới:'**
  String get whatsNew;

  /// No description provided for @addBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Thêm sinh nhật'**
  String get addBirthday;

  /// No description provided for @editBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Sửa sinh nhật'**
  String get editBirthday;

  /// No description provided for @manualAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thủ công'**
  String get manualAdd;

  /// No description provided for @contactAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm từ danh bạ'**
  String get contactAdd;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @selectLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ hiển thị'**
  String get selectLanguage;

  /// No description provided for @sessionStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái phiên'**
  String get sessionStatus;

  /// No description provided for @mode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ'**
  String get mode;

  /// No description provided for @aiTrial.
  ///
  /// In vi, this message translates to:
  /// **'Thử AI'**
  String get aiTrial;

  /// No description provided for @monthBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật tháng {month} • {count}'**
  String monthBirthdays(int month, int count);

  /// No description provided for @dayBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật ngày {date}'**
  String dayBirthdays(String date);

  /// No description provided for @showMonth.
  ///
  /// In vi, this message translates to:
  /// **'Xem cả tháng'**
  String get showMonth;

  /// No description provided for @noMonthBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Không có sinh nhật nào trong tháng này.'**
  String get noMonthBirthdays;

  /// No description provided for @noDayBirthdays.
  ///
  /// In vi, this message translates to:
  /// **'Không có sinh nhật nào trong ngày này.'**
  String get noDayBirthdays;

  /// No description provided for @improveExperience.
  ///
  /// In vi, this message translates to:
  /// **'Cải thiện trải nghiệm người dùng'**
  String get improveExperience;

  /// No description provided for @optimizeNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Tối ưu thông báo sinh nhật'**
  String get optimizeNotifications;

  /// No description provided for @fixPreviousBugs.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lỗi phiên bản trước'**
  String get fixPreviousBugs;

  /// No description provided for @increaseStability.
  ///
  /// In vi, this message translates to:
  /// **'Tăng độ ổn định'**
  String get increaseStability;

  /// No description provided for @name.
  ///
  /// In vi, this message translates to:
  /// **'Tên'**
  String get name;

  /// No description provided for @birthdayDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get birthdayDate;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @chooseImage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get chooseImage;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get confirmDelete;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa?'**
  String get deleteConfirmMessage;

  /// No description provided for @remindBefore.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước (ngày)'**
  String get remindBefore;

  /// No description provided for @remindTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ nhắc'**
  String get remindTime;

  /// No description provided for @syncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ...'**
  String get syncing;

  /// No description provided for @syncSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ thành công'**
  String get syncSuccess;

  /// No description provided for @syncError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi đồng bộ'**
  String get syncError;

  /// No description provided for @backupSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu thành công'**
  String get backupSuccess;

  /// No description provided for @restoreSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục thành công'**
  String get restoreSuccess;

  /// No description provided for @cloudUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để sử dụng tính năng đồng bộ đám mây.'**
  String get cloudUnavailable;

  /// No description provided for @signInGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google'**
  String get signInGoogle;

  /// No description provided for @signOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOut;

  /// No description provided for @exitLocalMode.
  ///
  /// In vi, this message translates to:
  /// **'Thoát chế độ thiết bị'**
  String get exitLocalMode;

  /// No description provided for @localMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ trên thiết bị'**
  String get localMode;

  /// No description provided for @localModeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt khi bạn muốn dùng tài khoản Google'**
  String get localModeSubtitle;

  /// No description provided for @deleteAllFirestore.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ trên Firestore'**
  String get deleteAllFirestore;

  /// No description provided for @deleteAllFirestoreConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa tất cả sinh nhật trên Firestore không?'**
  String get deleteAllFirestoreConfirm;

  /// No description provided for @deletedAllFirestore.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa toàn bộ dữ liệu trên Firestore'**
  String get deletedAllFirestore;

  /// No description provided for @noInternet.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng'**
  String get noInternet;

  /// No description provided for @googleConfigError.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Google chưa được cấu hình đúng trên thiết bị này.'**
  String get googleConfigError;

  /// No description provided for @googleUiUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Trình chọn tài khoản Google không khả dụng trên thiết bị này.'**
  String get googleUiUnavailable;

  /// No description provided for @loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại'**
  String get loginFailed;

  /// No description provided for @authError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi, vui lòng thử lại'**
  String get authError;

  /// No description provided for @testNotification.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo thử'**
  String get testNotification;

  /// No description provided for @testNotificationSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi thông báo thử'**
  String get testNotificationSuccess;

  /// No description provided for @testNotificationFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi thông báo thử'**
  String get testNotificationFailed;

  /// No description provided for @ageInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi phải nằm trong khoảng từ 0 đến 120.'**
  String get ageInvalid;

  /// No description provided for @nameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên'**
  String get nameRequired;

  /// No description provided for @gender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get male;

  /// No description provided for @female.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get female;

  /// No description provided for @other.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get other;

  /// No description provided for @nickname.
  ///
  /// In vi, this message translates to:
  /// **'Biệt danh'**
  String get nickname;

  /// No description provided for @relationship.
  ///
  /// In vi, this message translates to:
  /// **'Mối quan hệ'**
  String get relationship;

  /// No description provided for @note.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get note;

  /// No description provided for @calendarType.
  ///
  /// In vi, this message translates to:
  /// **'Loại lịch'**
  String get calendarType;

  /// No description provided for @solar.
  ///
  /// In vi, this message translates to:
  /// **'Dương lịch'**
  String get solar;

  /// No description provided for @lunar.
  ///
  /// In vi, this message translates to:
  /// **'Âm lịch'**
  String get lunar;

  /// No description provided for @solarDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh dương: {date}'**
  String solarDate(String date);

  /// No description provided for @lunarDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh âm: {date}'**
  String lunarDate(String date);

  /// No description provided for @repeatAnnually.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại hàng năm'**
  String get repeatAnnually;

  /// No description provided for @enableNotification.
  ///
  /// In vi, this message translates to:
  /// **'Bật thông báo'**
  String get enableNotification;

  /// No description provided for @imagePickError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể chọn hoặc cắt ảnh.'**
  String get imagePickError;

  /// No description provided for @imageProcessError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý ảnh đã chọn.'**
  String get imageProcessError;

  /// No description provided for @permissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền truy cập thư viện ảnh.'**
  String get permissionRequired;

  /// No description provided for @imageDecodeError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể giải mã ảnh.'**
  String get imageDecodeError;

  /// No description provided for @chooseLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get chooseLanguage;

  /// No description provided for @languageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageZh.
  ///
  /// In vi, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @authSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đừng để một sinh nhật nào trôi qua mà không được nhớ đến.'**
  String get authSubtitle;

  /// No description provided for @or.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get or;

  /// No description provided for @continueOnDevice.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục trên thiết bị'**
  String get continueOnDevice;

  /// No description provided for @localModeDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn vẫn có thể sử dụng sinh nhật, lịch và nhắc nhở trên thiết bị. Các tính năng đồng bộ đám mây yêu cầu đăng nhập.'**
  String get localModeDescription;

  /// No description provided for @authenticated.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng nhập'**
  String get authenticated;

  /// No description provided for @syncComplete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get syncComplete;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @syncProgress.
  ///
  /// In vi, this message translates to:
  /// **'{current} / {total} sinh nhật'**
  String syncProgress(int current, int total);

  /// No description provided for @selectOption.
  ///
  /// In vi, this message translates to:
  /// **'- Chọn -'**
  String get selectOption;

  /// No description provided for @cropTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cắt ảnh sinh nhật'**
  String get cropTitle;

  /// No description provided for @photoPermissionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập ảnh'**
  String get photoPermissionTitle;

  /// No description provided for @photoPermissionMessage.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh đại diện. Vui lòng cấp quyền trong Cài đặt.'**
  String get photoPermissionMessage;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã từ chối quyền truy cập ảnh. Bạn có thể thử lại hoặc cấp quyền trong Cài đặt.'**
  String get permissionDeniedMessage;

  /// No description provided for @permissionRestrictedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập ảnh bị hạn chế trên thiết bị này.'**
  String get permissionRestrictedMessage;

  /// No description provided for @openSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get openSettings;

  /// No description provided for @allow.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép'**
  String get allow;

  /// No description provided for @selectedCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn: {count}'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tất cả'**
  String get selectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đã chọn'**
  String get deleteSelected;

  /// No description provided for @clearSelection.
  ///
  /// In vi, this message translates to:
  /// **'Hủy chọn'**
  String get clearSelection;

  /// No description provided for @sort.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp'**
  String get sort;

  /// No description provided for @nearestBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật gần đến'**
  String get nearestBirthday;

  /// No description provided for @farthestBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật xa'**
  String get farthestBirthday;

  /// No description provided for @deleteBirthdayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa sinh nhật?'**
  String get deleteBirthdayTitle;

  /// No description provided for @deleteOneConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa sinh nhật này?'**
  String get deleteOneConfirm;

  /// No description provided for @deleteManyConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa {count} sinh nhật đã chọn?'**
  String deleteManyConfirm(int count);

  /// No description provided for @deletedOne.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa sinh nhật'**
  String get deletedOne;

  /// No description provided for @deletedMany.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa {count} sinh nhật'**
  String deletedMany(int count);

  /// No description provided for @deleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa {count} sinh nhật. Dữ liệu sẽ được thử đồng bộ lại.'**
  String deleteFailed(int count);

  /// No description provided for @ageAndDays.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi: {age} • Còn {days} ngày'**
  String ageAndDays(int age, int days);

  /// No description provided for @age.
  ///
  /// In vi, this message translates to:
  /// **'Tuổi'**
  String get age;

  /// No description provided for @days.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String days(int count);

  /// No description provided for @remainingDays.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} ngày'**
  String remainingDays(int count);

  /// No description provided for @yes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get no;

  /// No description provided for @enabled.
  ///
  /// In vi, this message translates to:
  /// **'Bật'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get disabled;

  /// No description provided for @notificationTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian nhắc'**
  String get notificationTime;

  /// No description provided for @calendarList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách'**
  String get calendarList;

  /// No description provided for @contactPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Không có quyền truy cập danh bạ'**
  String get contactPermissionDenied;

  /// No description provided for @unnamed.
  ///
  /// In vi, this message translates to:
  /// **'Không tên'**
  String get unnamed;

  /// No description provided for @selectFromContacts.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ danh bạ'**
  String get selectFromContacts;

  /// No description provided for @toggleSelectAll.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hoặc bỏ chọn tất cả'**
  String get toggleSelectAll;

  /// No description provided for @noContactsToAdd.
  ///
  /// In vi, this message translates to:
  /// **'Không còn danh bạ nào để thêm'**
  String get noContactsToAdd;

  /// No description provided for @settingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thông báo và quyền ứng dụng'**
  String get settingsSubtitle;

  /// No description provided for @guideSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem cách sử dụng Birthday Reminder'**
  String get guideSubtitle;

  /// No description provided for @usingOnDevice.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng trên thiết bị'**
  String get usingOnDevice;

  /// No description provided for @savedLocally.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lưu cục bộ trên thiết bị này'**
  String get savedLocally;

  /// No description provided for @options.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn'**
  String get options;

  /// No description provided for @chooseUsageMode.
  ///
  /// In vi, this message translates to:
  /// **'Chọn chế độ sử dụng'**
  String get chooseUsageMode;

  /// No description provided for @backToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại màn hình đăng nhập'**
  String get backToLogin;

  /// No description provided for @backupToFirestore.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu lên Firestore'**
  String get backupToFirestore;

  /// No description provided for @syncFromFirestore.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ từ Firestore'**
  String get syncFromFirestore;

  /// No description provided for @backupInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang sao lưu...'**
  String get backupInProgress;

  /// No description provided for @failed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get failed;

  /// No description provided for @errorWithDetails.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @notificationSection.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notificationSection;

  /// No description provided for @notificationPermission.
  ///
  /// In vi, this message translates to:
  /// **'Quyền thông báo'**
  String get notificationPermission;

  /// No description provided for @appNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo ứng dụng'**
  String get appNotifications;

  /// No description provided for @exactAlarm.
  ///
  /// In vi, this message translates to:
  /// **'Báo thức chính xác'**
  String get exactAlarm;

  /// No description provided for @deviceTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Múi giờ thiết bị'**
  String get deviceTimezone;

  /// No description provided for @notificationChannel.
  ///
  /// In vi, this message translates to:
  /// **'Kênh thông báo'**
  String get notificationChannel;

  /// No description provided for @checking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra'**
  String get checking;

  /// No description provided for @granted.
  ///
  /// In vi, this message translates to:
  /// **'Đã cấp'**
  String get granted;

  /// No description provided for @notGranted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấp'**
  String get notGranted;

  /// No description provided for @on.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get on;

  /// No description provided for @off.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get off;

  /// No description provided for @sendTestNotification.
  ///
  /// In vi, this message translates to:
  /// **'Gửi thông báo thử'**
  String get sendTestNotification;

  /// No description provided for @testAfterTenSeconds.
  ///
  /// In vi, this message translates to:
  /// **'Thử thông báo sau 10 giây'**
  String get testAfterTenSeconds;

  /// No description provided for @openNotificationSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt thông báo'**
  String get openNotificationSettings;

  /// No description provided for @allowExactAlarm.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép báo thức chính xác'**
  String get allowExactAlarm;

  /// No description provided for @testAfterOneMinute.
  ///
  /// In vi, this message translates to:
  /// **'Thử hệ thống nhắc sinh nhật sau 1 phút'**
  String get testAfterOneMinute;

  /// No description provided for @notificationPermissionOff.
  ///
  /// In vi, this message translates to:
  /// **'Quyền thông báo chưa được bật.'**
  String get notificationPermissionOff;

  /// No description provided for @exactAlarmPermissionMissing.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa cấp quyền báo thức chính xác.'**
  String get exactAlarmPermissionMissing;

  /// No description provided for @notificationsDisabledSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Quyền thông báo chưa được bật — không thể đặt lịch.'**
  String get notificationsDisabledSchedule;

  /// No description provided for @scheduleNotRetained.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không giữ lịch — kiểm tra lại quyền báo thức.'**
  String get scheduleNotRetained;

  /// No description provided for @unknownError.
  ///
  /// In vi, this message translates to:
  /// **'lỗi không xác định'**
  String get unknownError;

  /// No description provided for @scheduledTestAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt thông báo thử lúc {time}.'**
  String scheduledTestAt(String time);

  /// No description provided for @scheduledMinuteTestAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt lịch thử 1 phút lúc {time}.'**
  String scheduledMinuteTestAt(String time);

  /// No description provided for @scheduleTestFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đặt thông báo thử: {error}'**
  String scheduleTestFailed(String error);

  /// No description provided for @scheduleMinuteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đặt lịch 1 phút: {error}'**
  String scheduleMinuteFailed(String error);

  /// No description provided for @reminderPendingCount.
  ///
  /// In vi, this message translates to:
  /// **'Số lịch nhắc đang chờ: {count}'**
  String reminderPendingCount(int count);

  /// No description provided for @resyncReminders.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ lại lịch nhắc'**
  String get resyncReminders;

  /// No description provided for @noPendingReminders.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch nhắc nào đang chờ.'**
  String get noPendingReminders;

  /// No description provided for @collapse.
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn'**
  String get collapse;

  /// No description provided for @showMoreReminders.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm {count} lịch'**
  String showMoreReminders(int count);

  /// No description provided for @reminderSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch nhắc'**
  String get reminderSchedule;

  /// No description provided for @birthdayShortId.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật {id}…'**
  String birthdayShortId(String id);

  /// No description provided for @reminderResyncSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt {scheduled} lịch, huỷ {cancelled} lịch cũ.'**
  String reminderResyncSuccess(int scheduled, int cancelled);

  /// No description provided for @syncFailedDetails.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ thất bại: {error}'**
  String syncFailedDetails(String error);

  /// No description provided for @waiting.
  ///
  /// In vi, this message translates to:
  /// **'chờ'**
  String get waiting;

  /// No description provided for @appInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin ứng dụng'**
  String get appInformation;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get loading;

  /// No description provided for @appVersionInfo.
  ///
  /// In vi, this message translates to:
  /// **'{name} — phiên bản {version} (build {build})'**
  String appVersionInfo(String name, String version, String build);

  /// No description provided for @testChannel.
  ///
  /// In vi, this message translates to:
  /// **'Kênh test: {id}'**
  String testChannel(String id);

  /// No description provided for @mainChannel.
  ///
  /// In vi, this message translates to:
  /// **'Kênh chính: {id}'**
  String mainChannel(String id);

  /// No description provided for @testNotificationId.
  ///
  /// In vi, this message translates to:
  /// **'ID thông báo thử: {id}'**
  String testNotificationId(String id);

  /// No description provided for @scheduledTestNotificationId.
  ///
  /// In vi, this message translates to:
  /// **'ID thông báo thử đặt lịch: {id}'**
  String scheduledTestNotificationId(String id);

  /// No description provided for @updateApp.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ứng dụng'**
  String get updateApp;

  /// No description provided for @checkNewVersion.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra phiên bản mới'**
  String get checkNewVersion;

  /// No description provided for @artificialIntelligence.
  ///
  /// In vi, this message translates to:
  /// **'Trí tuệ nhân tạo'**
  String get artificialIntelligence;

  /// No description provided for @provider.
  ///
  /// In vi, this message translates to:
  /// **'Nhà cung cấp'**
  String get provider;

  /// No description provided for @openAiCompatible.
  ///
  /// In vi, this message translates to:
  /// **'OpenAI / tương thích'**
  String get openAiCompatible;

  /// No description provided for @apiKeyNotSaved.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lưu API key.'**
  String get apiKeyNotSaved;

  /// No description provided for @apiKeyCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại: {key}'**
  String apiKeyCurrent(String key);

  /// No description provided for @showApiKey.
  ///
  /// In vi, this message translates to:
  /// **'Hiện API key'**
  String get showApiKey;

  /// No description provided for @hideApiKey.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn API key'**
  String get hideApiKey;

  /// No description provided for @pasteClipboard.
  ///
  /// In vi, this message translates to:
  /// **'Dán từ clipboard'**
  String get pasteClipboard;

  /// No description provided for @testConnection.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra kết nối'**
  String get testConnection;

  /// No description provided for @fetchModels.
  ///
  /// In vi, this message translates to:
  /// **'Lấy danh sách model'**
  String get fetchModels;

  /// No description provided for @saveConfiguration.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cấu hình'**
  String get saveConfiguration;

  /// No description provided for @deleteApiKey.
  ///
  /// In vi, this message translates to:
  /// **'Xoá API key'**
  String get deleteApiKey;

  /// No description provided for @modelRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập model.'**
  String get modelRequired;

  /// No description provided for @apiKeyRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập API key.'**
  String get apiKeyRequired;

  /// No description provided for @baseUrlRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập Base URL.'**
  String get baseUrlRequired;

  /// No description provided for @apiKeySaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu cấu hình và API key an toàn.'**
  String get apiKeySaved;

  /// No description provided for @apiKeyDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá API key.'**
  String get apiKeyDeleted;

  /// No description provided for @clipboardNoApiKey.
  ///
  /// In vi, this message translates to:
  /// **'Clipboard không có API key.'**
  String get clipboardNoApiKey;

  /// No description provided for @apiKeyPasted.
  ///
  /// In vi, this message translates to:
  /// **'Đã dán API key ({count} ký tự).'**
  String apiKeyPasted(int count);

  /// No description provided for @connectionSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối thành công ({latency} ms) — Phản hồi: \"{reply}\"'**
  String connectionSuccess(int latency, String reply);

  /// No description provided for @modelsUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được danh sách model — nhập ID thủ công.'**
  String get modelsUnavailable;

  /// No description provided for @modelsLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải {count} model.'**
  String modelsLoaded(int count);

  /// No description provided for @aiUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'AI không khả dụng.'**
  String get aiUnavailable;

  /// No description provided for @aiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AI'**
  String get aiAssistant;

  /// No description provided for @personalizedFor.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân hóa cho {name}'**
  String personalizedFor(String name);

  /// No description provided for @aiReady.
  ///
  /// In vi, this message translates to:
  /// **'AI sẵn sàng'**
  String get aiReady;

  /// No description provided for @notConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấu hình'**
  String get notConfigured;

  /// No description provided for @openAiSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt AI'**
  String get openAiSettings;

  /// No description provided for @aiThinking.
  ///
  /// In vi, this message translates to:
  /// **'AI đang suy nghĩ...'**
  String get aiThinking;

  /// No description provided for @giftSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý quà tặng'**
  String get giftSuggestions;

  /// No description provided for @wishSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý câu chúc'**
  String get wishSuggestions;

  /// No description provided for @english.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Trung'**
  String get chinese;

  /// No description provided for @reminderStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái nhắc'**
  String get reminderStatus;

  /// No description provided for @scheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên lịch'**
  String get scheduled;

  /// No description provided for @notScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lên lịch'**
  String get notScheduled;

  /// No description provided for @scheduleLost.
  ///
  /// In vi, this message translates to:
  /// **'Mất lịch — cần đồng bộ'**
  String get scheduleLost;

  /// No description provided for @pastTime.
  ///
  /// In vi, this message translates to:
  /// **'Đã quá thời gian'**
  String get pastTime;

  /// No description provided for @nextReminder.
  ///
  /// In vi, this message translates to:
  /// **'Lần nhắc kế tiếp: {time}'**
  String nextReminder(String time);

  /// No description provided for @rescheduleReminder.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại lịch nhắc'**
  String get rescheduleReminder;

  /// No description provided for @notificationDisabledPerson.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đã tắt cho người này.'**
  String get notificationDisabledPerson;

  /// No description provided for @noReminderScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch nhắc nào.'**
  String get noReminderScheduled;

  /// No description provided for @reminderScheduledAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã lên lịch lúc {time}.'**
  String reminderScheduledAt(String time);

  /// No description provided for @reminderRescheduledAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt lại lịch{time}.'**
  String reminderRescheduledAt(String time);

  /// No description provided for @notificationDisplayFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hiển thị thông báo: {error}'**
  String notificationDisplayFailed(String error);

  /// No description provided for @notificationDisabledHelp.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đang bị tắt. Hãy bật quyền thông báo cho ứng dụng.'**
  String get notificationDisabledHelp;

  /// No description provided for @birthdayShare.
  ///
  /// In vi, this message translates to:
  /// **'Sinh nhật của {name} vào ngày {date}'**
  String birthdayShare(String name, String date);

  /// No description provided for @copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {label}.'**
  String copied(String label);

  /// No description provided for @copyAll.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép tất cả'**
  String get copyAll;

  /// No description provided for @regenerate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lại'**
  String get regenerate;

  /// No description provided for @noSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gợi ý nào.'**
  String get noSuggestions;

  /// No description provided for @reason.
  ///
  /// In vi, this message translates to:
  /// **'Lý do: {value}'**
  String reason(String value);

  /// No description provided for @budget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách: {value}'**
  String budget(String value);

  /// No description provided for @personalizing.
  ///
  /// In vi, this message translates to:
  /// **'Đang cá nhân hoá lại...'**
  String get personalizing;

  /// No description provided for @personalizedProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân hoá theo hồ sơ'**
  String get personalizedProfile;

  /// No description provided for @modelValidResults.
  ///
  /// In vi, this message translates to:
  /// **'Mô hình trả về {count}/{target} kết quả hợp lệ.'**
  String modelValidResults(int count, int target);

  /// No description provided for @suggestedByAi.
  ///
  /// In vi, this message translates to:
  /// **'Đề xuất bởi AI'**
  String get suggestedByAi;

  /// No description provided for @aiAndQuick.
  ///
  /// In vi, this message translates to:
  /// **'AI + gợi ý nhanh'**
  String get aiAndQuick;

  /// No description provided for @usingQuickSuggestions.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng gợi ý nhanh'**
  String get usingQuickSuggestions;

  /// No description provided for @giftsFor.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý riêng cho {name}'**
  String giftsFor(String name);

  /// No description provided for @wishesFor.
  ///
  /// In vi, this message translates to:
  /// **'10 câu chúc cho {name}'**
  String wishesFor(String name);

  /// No description provided for @giftUnit.
  ///
  /// In vi, this message translates to:
  /// **'món'**
  String get giftUnit;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @solarBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh dương'**
  String get solarBirthday;

  /// No description provided for @lunarBirthday.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh âm'**
  String get lunarBirthday;

  /// No description provided for @atTime.
  ///
  /// In vi, this message translates to:
  /// **'lúc {time}'**
  String atTime(String time);

  /// No description provided for @invalidApiKey.
  ///
  /// In vi, this message translates to:
  /// **'API key không hợp lệ hoặc không có quyền.'**
  String get invalidApiKey;

  /// No description provided for @modelNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy model.'**
  String get modelNotFound;

  /// No description provided for @quotaExceeded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết quota hoặc vượt giới hạn yêu cầu.'**
  String get quotaExceeded;

  /// No description provided for @aiTimeout.
  ///
  /// In vi, this message translates to:
  /// **'AI phản hồi quá lâu. Hãy thử lại.'**
  String get aiTimeout;

  /// No description provided for @serverConnectionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối máy chủ.'**
  String get serverConnectionFailed;

  /// No description provided for @testNotificationSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi thông báo thử'**
  String get testNotificationSent;

  /// No description provided for @updateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ứng dụng'**
  String get updateTitle;

  /// No description provided for @currentVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản hiện tại'**
  String get currentVersion;

  /// No description provided for @latestVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản mới nhất'**
  String get latestVersion;

  /// No description provided for @upToDate.
  ///
  /// In vi, this message translates to:
  /// **'Đã có phiên bản mới nhất'**
  String get upToDate;

  /// No description provided for @newVersionAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Có bản cập nhật mới!'**
  String get newVersionAvailable;

  /// No description provided for @downloadUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Tải bản cập nhật'**
  String get downloadUpdate;

  /// No description provided for @installUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get installUpdate;

  /// No description provided for @checkingUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra cập nhật…'**
  String get checkingUpdate;

  /// No description provided for @updateError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi cập nhật'**
  String get updateError;

  /// No description provided for @updateReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get updateReady;

  /// No description provided for @updateCheckHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn “Kiểm tra cập nhật” để tìm phiên bản mới.'**
  String get updateCheckHint;

  /// No description provided for @usingLatestVersion.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang sử dụng phiên bản mới nhất.'**
  String get usingLatestVersion;

  /// No description provided for @versionAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version} đã sẵn sàng.'**
  String versionAvailable(String version);

  /// No description provided for @reinstallRequired.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu cài đặt lại'**
  String get reinstallRequired;

  /// No description provided for @reinstallMessage.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản mới sử dụng chữ ký bảo mật mới. Hãy sao lưu dữ liệu trước khi cài đặt lại.'**
  String get reinstallMessage;

  /// No description provided for @downloadingUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bản cập nhật…'**
  String get downloadingUpdate;

  /// No description provided for @downloadedSize.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải {size}'**
  String downloadedSize(String size);

  /// No description provided for @verifyingUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác minh…'**
  String get verifyingUpdate;

  /// No description provided for @verifyingFile.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra tính toàn vẹn của tệp…'**
  String get verifyingFile;

  /// No description provided for @readyToInstall.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng cài đặt!'**
  String get readyToInstall;

  /// No description provided for @updateDownloaded.
  ///
  /// In vi, this message translates to:
  /// **'Bản cập nhật đã tải về và xác minh.'**
  String get updateDownloaded;

  /// No description provided for @installPermissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền cài đặt'**
  String get installPermissionRequired;

  /// No description provided for @installPermissionHint.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép cài đặt ứng dụng từ nguồn này rồi thử lại.'**
  String get installPermissionHint;

  /// No description provided for @installingUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Đang cài đặt…'**
  String get installingUpdate;

  /// No description provided for @pleaseWait.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chờ…'**
  String get pleaseWait;

  /// No description provided for @genericUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại.'**
  String get genericUpdateError;

  /// No description provided for @skipUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get skipUpdate;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @openDownloadPage.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang tải xuống'**
  String get openDownloadPage;

  /// No description provided for @reinstallSteps.
  ///
  /// In vi, this message translates to:
  /// **'1. Sao lưu dữ liệu\n2. Giữ file backup an toàn\n3. Cài đặt bản mới theo hướng dẫn\n4. Khôi phục backup'**
  String get reinstallSteps;

  /// No description provided for @releaseDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết phiên bản'**
  String get releaseDetails;

  /// No description provided for @versionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get versionLabel;

  /// No description provided for @buildLabel.
  ///
  /// In vi, this message translates to:
  /// **'Build'**
  String get buildLabel;

  /// No description provided for @releaseDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày phát hành'**
  String get releaseDate;

  /// No description provided for @fileSize.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng'**
  String get fileSize;

  /// No description provided for @noReleaseNotes.
  ///
  /// In vi, this message translates to:
  /// **'Không có ghi chú phát hành.'**
  String get noReleaseNotes;

  /// No description provided for @viewOnGitHub.
  ///
  /// In vi, this message translates to:
  /// **'Xem trên GitHub'**
  String get viewOnGitHub;

  /// No description provided for @fallbackChangeExperience.
  ///
  /// In vi, this message translates to:
  /// **'Cải thiện trải nghiệm người dùng'**
  String get fallbackChangeExperience;

  /// No description provided for @fallbackChangeNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Tối ưu thông báo sinh nhật'**
  String get fallbackChangeNotifications;

  /// No description provided for @fallbackChangeFixes.
  ///
  /// In vi, this message translates to:
  /// **'Sửa lỗi phiên bản trước'**
  String get fallbackChangeFixes;

  /// No description provided for @fallbackChangeStability.
  ///
  /// In vi, this message translates to:
  /// **'Tăng độ ổn định'**
  String get fallbackChangeStability;

  /// No description provided for @birthdaySyncProgress.
  ///
  /// In vi, this message translates to:
  /// **'{current} / {total} sinh nhật'**
  String birthdaySyncProgress(int current, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
