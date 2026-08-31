// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Birthday Reminder';

  @override
  String get home => 'Trang chủ';

  @override
  String get birthdayList => 'Danh sách sinh nhật';

  @override
  String get todayBirthdays => 'Sinh nhật hôm nay';

  @override
  String get upcoming => 'Sắp tới';

  @override
  String get seeMore => 'Xem thêm';

  @override
  String get noBirthdays => 'Chưa có sinh nhật nào';

  @override
  String get birthdayCalendar => 'Lịch sinh nhật';

  @override
  String get calendarMonth => 'Tháng';

  @override
  String get calendarDay => 'Ngày';

  @override
  String get birthdayReminder => 'Nhắc sinh nhật';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get backup => 'Sao lưu';

  @override
  String get restore => 'Khôi phục';

  @override
  String get userGuide => 'Hướng dẫn sử dụng';

  @override
  String get newVersion => 'Có phiên bản mới';

  @override
  String get updateNow => 'Cập nhật ngay';

  @override
  String get later => 'Để sau';

  @override
  String get whatsNew => 'Có gì mới:';

  @override
  String get addBirthday => 'Thêm sinh nhật';

  @override
  String get editBirthday => 'Sửa sinh nhật';

  @override
  String get manualAdd => 'Thêm thủ công';

  @override
  String get contactAdd => 'Thêm từ danh bạ';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ hiển thị';

  @override
  String get sessionStatus => 'Trạng thái phiên';

  @override
  String get mode => 'Chế độ';

  @override
  String get aiTrial => 'Thử AI';

  @override
  String monthBirthdays(int month, int count) {
    return 'Sinh nhật tháng $month • $count';
  }

  @override
  String dayBirthdays(String date) {
    return 'Sinh nhật ngày $date';
  }

  @override
  String get showMonth => 'Xem cả tháng';

  @override
  String get noMonthBirthdays => 'Không có sinh nhật nào trong tháng này.';

  @override
  String get noDayBirthdays => 'Không có sinh nhật nào trong ngày này.';

  @override
  String get improveExperience => 'Cải thiện trải nghiệm người dùng';

  @override
  String get optimizeNotifications => 'Tối ưu thông báo sinh nhật';

  @override
  String get fixPreviousBugs => 'Sửa lỗi phiên bản trước';

  @override
  String get increaseStability => 'Tăng độ ổn định';

  @override
  String get name => 'Tên';

  @override
  String get birthdayDate => 'Ngày sinh';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get chooseImage => 'Chọn ảnh';

  @override
  String get delete => 'Xóa';

  @override
  String get confirmDelete => 'Xác nhận xóa';

  @override
  String get deleteConfirmMessage => 'Bạn có chắc muốn xóa?';

  @override
  String get remindBefore => 'Nhắc trước (ngày)';

  @override
  String get remindTime => 'Giờ nhắc';

  @override
  String get syncing => 'Đang đồng bộ...';

  @override
  String get syncSuccess => 'Đồng bộ thành công';

  @override
  String get syncError => 'Lỗi đồng bộ';

  @override
  String get backupSuccess => 'Sao lưu thành công';

  @override
  String get restoreSuccess => 'Khôi phục thành công';

  @override
  String get cloudUnavailable =>
      'Đăng nhập để sử dụng tính năng đồng bộ đám mây.';

  @override
  String get signInGoogle => 'Đăng nhập bằng Google';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get exitLocalMode => 'Thoát chế độ thiết bị';

  @override
  String get localMode => 'Chế độ trên thiết bị';

  @override
  String get localModeSubtitle => 'Tắt khi bạn muốn dùng tài khoản Google';

  @override
  String get deleteAllFirestore => 'Xóa toàn bộ trên Firestore';

  @override
  String get deleteAllFirestoreConfirm =>
      'Bạn có chắc muốn xóa tất cả sinh nhật trên Firestore không?';

  @override
  String get deletedAllFirestore => 'Đã xóa toàn bộ dữ liệu trên Firestore';

  @override
  String get noInternet => 'Không có kết nối mạng';

  @override
  String get googleConfigError =>
      'Đăng nhập Google chưa được cấu hình đúng trên thiết bị này.';

  @override
  String get googleUiUnavailable =>
      'Trình chọn tài khoản Google không khả dụng trên thiết bị này.';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get authError => 'Đã xảy ra lỗi, vui lòng thử lại';

  @override
  String get testNotification => 'Thông báo thử';

  @override
  String get testNotificationSuccess => 'Đã gửi thông báo thử';

  @override
  String get testNotificationFailed => 'Không thể gửi thông báo thử';

  @override
  String get ageInvalid => 'Tuổi phải nằm trong khoảng từ 0 đến 120.';

  @override
  String get nameRequired => 'Vui lòng nhập tên';

  @override
  String get gender => 'Giới tính';

  @override
  String get male => 'Nam';

  @override
  String get female => 'Nữ';

  @override
  String get other => 'Khác';

  @override
  String get nickname => 'Biệt danh';

  @override
  String get relationship => 'Mối quan hệ';

  @override
  String get note => 'Ghi chú';

  @override
  String get calendarType => 'Loại lịch';

  @override
  String get solar => 'Dương lịch';

  @override
  String get lunar => 'Âm lịch';

  @override
  String solarDate(String date) {
    return 'Ngày sinh dương: $date';
  }

  @override
  String lunarDate(String date) {
    return 'Ngày sinh âm: $date';
  }

  @override
  String get repeatAnnually => 'Lặp lại hàng năm';

  @override
  String get enableNotification => 'Bật thông báo';

  @override
  String get imagePickError => 'Không thể chọn hoặc cắt ảnh.';

  @override
  String get imageProcessError => 'Không thể xử lý ảnh đã chọn.';

  @override
  String get permissionRequired => 'Cần quyền truy cập thư viện ảnh.';

  @override
  String get imageDecodeError => 'Không thể giải mã ảnh.';

  @override
  String get chooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文';

  @override
  String get authSubtitle =>
      'Đừng để một sinh nhật nào trôi qua mà không được nhớ đến.';

  @override
  String get or => 'hoặc';

  @override
  String get continueOnDevice => 'Tiếp tục trên thiết bị';

  @override
  String get localModeDescription =>
      'Bạn vẫn có thể sử dụng sinh nhật, lịch và nhắc nhở trên thiết bị. Các tính năng đồng bộ đám mây yêu cầu đăng nhập.';

  @override
  String get authenticated => 'Đã đăng nhập';

  @override
  String get syncComplete => 'Hoàn tất';

  @override
  String get close => 'Đóng';

  @override
  String syncProgress(int current, int total) {
    return '$current / $total sinh nhật';
  }

  @override
  String get selectOption => '- Chọn -';

  @override
  String get cropTitle => 'Cắt ảnh sinh nhật';

  @override
  String get photoPermissionTitle => 'Quyền truy cập ảnh';

  @override
  String get photoPermissionMessage =>
      'Ứng dụng cần quyền truy cập thư viện ảnh để chọn ảnh đại diện. Vui lòng cấp quyền trong Cài đặt.';

  @override
  String get permissionDeniedMessage =>
      'Bạn đã từ chối quyền truy cập ảnh. Bạn có thể thử lại hoặc cấp quyền trong Cài đặt.';

  @override
  String get permissionRestrictedMessage =>
      'Quyền truy cập ảnh bị hạn chế trên thiết bị này.';

  @override
  String get openSettings => 'Mở Cài đặt';

  @override
  String get allow => 'Cho phép';

  @override
  String selectedCount(int count) {
    return 'Đã chọn: $count';
  }

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get deleteSelected => 'Xóa đã chọn';

  @override
  String get clearSelection => 'Hủy chọn';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get nearestBirthday => 'Sinh nhật gần đến';

  @override
  String get farthestBirthday => 'Sinh nhật xa';

  @override
  String get deleteBirthdayTitle => 'Xóa sinh nhật?';

  @override
  String get deleteOneConfirm => 'Bạn có chắc muốn xóa sinh nhật này?';

  @override
  String deleteManyConfirm(int count) {
    return 'Bạn có chắc muốn xóa $count sinh nhật đã chọn?';
  }

  @override
  String get deletedOne => 'Đã xóa sinh nhật';

  @override
  String deletedMany(int count) {
    return 'Đã xóa $count sinh nhật';
  }

  @override
  String deleteFailed(int count) {
    return 'Không thể xóa $count sinh nhật. Dữ liệu sẽ được thử đồng bộ lại.';
  }

  @override
  String ageAndDays(int age, int days) {
    return 'Tuổi: $age • Còn $days ngày';
  }

  @override
  String get age => 'Tuổi';

  @override
  String days(int count) {
    return '$count ngày';
  }

  @override
  String remainingDays(int count) {
    return 'Còn $count ngày';
  }

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get enabled => 'Bật';

  @override
  String get disabled => 'Tắt';

  @override
  String get notificationTime => 'Thời gian nhắc';

  @override
  String get calendarList => 'Danh sách';

  @override
  String get contactPermissionDenied => 'Không có quyền truy cập danh bạ';

  @override
  String get unnamed => 'Không tên';

  @override
  String get selectFromContacts => 'Chọn từ danh bạ';

  @override
  String get toggleSelectAll => 'Chọn hoặc bỏ chọn tất cả';

  @override
  String get noContactsToAdd => 'Không còn danh bạ nào để thêm';

  @override
  String get settingsSubtitle => 'Kiểm tra thông báo và quyền ứng dụng';

  @override
  String get guideSubtitle => 'Xem cách sử dụng Birthday Reminder';

  @override
  String get usingOnDevice => 'Đang dùng trên thiết bị';

  @override
  String get savedLocally => 'Chỉ lưu cục bộ trên thiết bị này';

  @override
  String get options => 'Tùy chọn';

  @override
  String get chooseUsageMode => 'Chọn chế độ sử dụng';

  @override
  String get backToLogin => 'Quay lại màn hình đăng nhập';

  @override
  String get backupToFirestore => 'Sao lưu lên Firestore';

  @override
  String get syncFromFirestore => 'Đồng bộ từ Firestore';

  @override
  String get backupInProgress => 'Đang sao lưu...';

  @override
  String get failed => 'Thất bại';

  @override
  String errorWithDetails(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get notificationSection => 'Thông báo';

  @override
  String get notificationPermission => 'Quyền thông báo';

  @override
  String get appNotifications => 'Thông báo ứng dụng';

  @override
  String get exactAlarm => 'Báo thức chính xác';

  @override
  String get deviceTimezone => 'Múi giờ thiết bị';

  @override
  String get notificationChannel => 'Kênh thông báo';

  @override
  String get checking => 'Đang kiểm tra';

  @override
  String get granted => 'Đã cấp';

  @override
  String get notGranted => 'Chưa cấp';

  @override
  String get on => 'Đang bật';

  @override
  String get off => 'Đang tắt';

  @override
  String get sendTestNotification => 'Gửi thông báo thử';

  @override
  String get testAfterTenSeconds => 'Thử thông báo sau 10 giây';

  @override
  String get openNotificationSettings => 'Mở cài đặt thông báo';

  @override
  String get allowExactAlarm => 'Cho phép báo thức chính xác';

  @override
  String get testAfterOneMinute => 'Thử hệ thống nhắc sinh nhật sau 1 phút';

  @override
  String get notificationPermissionOff => 'Quyền thông báo chưa được bật.';

  @override
  String get exactAlarmPermissionMissing =>
      'Thiết bị chưa cấp quyền báo thức chính xác.';

  @override
  String get notificationsDisabledSchedule =>
      'Quyền thông báo chưa được bật — không thể đặt lịch.';

  @override
  String get scheduleNotRetained =>
      'Thiết bị không giữ lịch — kiểm tra lại quyền báo thức.';

  @override
  String get unknownError => 'lỗi không xác định';

  @override
  String scheduledTestAt(String time) {
    return 'Đã đặt thông báo thử lúc $time.';
  }

  @override
  String scheduledMinuteTestAt(String time) {
    return 'Đã đặt lịch thử 1 phút lúc $time.';
  }

  @override
  String scheduleTestFailed(String error) {
    return 'Không thể đặt thông báo thử: $error';
  }

  @override
  String scheduleMinuteFailed(String error) {
    return 'Không thể đặt lịch 1 phút: $error';
  }

  @override
  String reminderPendingCount(int count) {
    return 'Số lịch nhắc đang chờ: $count';
  }

  @override
  String get resyncReminders => 'Đồng bộ lại lịch nhắc';

  @override
  String get noPendingReminders => 'Chưa có lịch nhắc nào đang chờ.';

  @override
  String get collapse => 'Thu gọn';

  @override
  String showMoreReminders(int count) {
    return 'Xem thêm $count lịch';
  }

  @override
  String get reminderSchedule => 'Lịch nhắc';

  @override
  String birthdayShortId(String id) {
    return 'Sinh nhật $id…';
  }

  @override
  String reminderResyncSuccess(int scheduled, int cancelled) {
    return 'Đã đặt $scheduled lịch, huỷ $cancelled lịch cũ.';
  }

  @override
  String syncFailedDetails(String error) {
    return 'Đồng bộ thất bại: $error';
  }

  @override
  String get waiting => 'chờ';

  @override
  String get appInformation => 'Thông tin ứng dụng';

  @override
  String get loading => 'Đang tải…';

  @override
  String appVersionInfo(String name, String version, String build) {
    return '$name — phiên bản $version (build $build)';
  }

  @override
  String testChannel(String id) {
    return 'Kênh test: $id';
  }

  @override
  String mainChannel(String id) {
    return 'Kênh chính: $id';
  }

  @override
  String testNotificationId(String id) {
    return 'ID thông báo thử: $id';
  }

  @override
  String scheduledTestNotificationId(String id) {
    return 'ID thông báo thử đặt lịch: $id';
  }

  @override
  String get updateApp => 'Cập nhật ứng dụng';

  @override
  String get checkNewVersion => 'Kiểm tra phiên bản mới';

  @override
  String get artificialIntelligence => 'Trí tuệ nhân tạo';

  @override
  String get provider => 'Nhà cung cấp';

  @override
  String get openAiCompatible => 'OpenAI / tương thích';

  @override
  String get apiKeyNotSaved => 'Chưa lưu API key.';

  @override
  String apiKeyCurrent(String key) {
    return 'Hiện tại: $key';
  }

  @override
  String get showApiKey => 'Hiện API key';

  @override
  String get hideApiKey => 'Ẩn API key';

  @override
  String get pasteClipboard => 'Dán từ clipboard';

  @override
  String get testConnection => 'Kiểm tra kết nối';

  @override
  String get fetchModels => 'Lấy danh sách model';

  @override
  String get saveConfiguration => 'Lưu cấu hình';

  @override
  String get deleteApiKey => 'Xoá API key';

  @override
  String get modelRequired => 'Vui lòng nhập model.';

  @override
  String get apiKeyRequired => 'Vui lòng nhập API key.';

  @override
  String get baseUrlRequired => 'Vui lòng nhập Base URL.';

  @override
  String get apiKeySaved => 'Đã lưu cấu hình và API key an toàn.';

  @override
  String get apiKeyDeleted => 'Đã xoá API key.';

  @override
  String get clipboardNoApiKey => 'Clipboard không có API key.';

  @override
  String apiKeyPasted(int count) {
    return 'Đã dán API key ($count ký tự).';
  }

  @override
  String connectionSuccess(int latency, String reply) {
    return 'Kết nối thành công ($latency ms) — Phản hồi: \"$reply\"';
  }

  @override
  String get modelsUnavailable =>
      'Không lấy được danh sách model — nhập ID thủ công.';

  @override
  String modelsLoaded(int count) {
    return 'Đã tải $count model.';
  }

  @override
  String get aiUnavailable => 'AI không khả dụng.';

  @override
  String get aiAssistant => 'Trợ lý AI';

  @override
  String personalizedFor(String name) {
    return 'Cá nhân hóa cho $name';
  }

  @override
  String get aiReady => 'AI sẵn sàng';

  @override
  String get notConfigured => 'Chưa cấu hình';

  @override
  String get openAiSettings => 'Mở cài đặt AI';

  @override
  String get aiThinking => 'AI đang suy nghĩ...';

  @override
  String get giftSuggestions => 'Gợi ý quà tặng';

  @override
  String get wishSuggestions => 'Gợi ý câu chúc';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get chinese => 'Tiếng Trung';

  @override
  String get reminderStatus => 'Trạng thái nhắc';

  @override
  String get scheduled => 'Đã lên lịch';

  @override
  String get notScheduled => 'Chưa lên lịch';

  @override
  String get scheduleLost => 'Mất lịch — cần đồng bộ';

  @override
  String get pastTime => 'Đã quá thời gian';

  @override
  String nextReminder(String time) {
    return 'Lần nhắc kế tiếp: $time';
  }

  @override
  String get rescheduleReminder => 'Đặt lại lịch nhắc';

  @override
  String get notificationDisabledPerson => 'Thông báo đã tắt cho người này.';

  @override
  String get noReminderScheduled => 'Chưa có lịch nhắc nào.';

  @override
  String reminderScheduledAt(String time) {
    return 'Đã lên lịch lúc $time.';
  }

  @override
  String reminderRescheduledAt(String time) {
    return 'Đã đặt lại lịch$time.';
  }

  @override
  String notificationDisplayFailed(String error) {
    return 'Không thể hiển thị thông báo: $error';
  }

  @override
  String get notificationDisabledHelp =>
      'Thông báo đang bị tắt. Hãy bật quyền thông báo cho ứng dụng.';

  @override
  String birthdayShare(String name, String date) {
    return 'Sinh nhật của $name vào ngày $date';
  }

  @override
  String copied(String label) {
    return 'Đã sao chép $label.';
  }

  @override
  String get copyAll => 'Sao chép tất cả';

  @override
  String get regenerate => 'Tạo lại';

  @override
  String get noSuggestions => 'Chưa có gợi ý nào.';

  @override
  String reason(String value) {
    return 'Lý do: $value';
  }

  @override
  String budget(String value) {
    return 'Ngân sách: $value';
  }

  @override
  String get personalizing => 'Đang cá nhân hoá lại...';

  @override
  String get personalizedProfile => 'Cá nhân hoá theo hồ sơ';

  @override
  String modelValidResults(int count, int target) {
    return 'Mô hình trả về $count/$target kết quả hợp lệ.';
  }

  @override
  String get suggestedByAi => 'Đề xuất bởi AI';

  @override
  String get aiAndQuick => 'AI + gợi ý nhanh';

  @override
  String get usingQuickSuggestions => 'Đang dùng gợi ý nhanh';

  @override
  String giftsFor(String name) {
    return 'Gợi ý riêng cho $name';
  }

  @override
  String wishesFor(String name) {
    return '10 câu chúc cho $name';
  }

  @override
  String get giftUnit => 'món';

  @override
  String get share => 'Chia sẻ';

  @override
  String get solarBirthday => 'Ngày sinh dương';

  @override
  String get lunarBirthday => 'Ngày sinh âm';

  @override
  String atTime(String time) {
    return 'lúc $time';
  }

  @override
  String get invalidApiKey => 'API key không hợp lệ hoặc không có quyền.';

  @override
  String get modelNotFound => 'Không tìm thấy model.';

  @override
  String get quotaExceeded => 'Đã hết quota hoặc vượt giới hạn yêu cầu.';

  @override
  String get aiTimeout => 'AI phản hồi quá lâu. Hãy thử lại.';

  @override
  String get serverConnectionFailed => 'Không thể kết nối máy chủ.';

  @override
  String get testNotificationSent => 'Đã gửi thông báo thử';

  @override
  String get updateTitle => 'Cập nhật ứng dụng';

  @override
  String get currentVersion => 'Phiên bản hiện tại';

  @override
  String get latestVersion => 'Phiên bản mới nhất';

  @override
  String get upToDate => 'Đã có phiên bản mới nhất';

  @override
  String get newVersionAvailable => 'Có bản cập nhật mới!';

  @override
  String get downloadUpdate => 'Tải bản cập nhật';

  @override
  String get installUpdate => 'Cài đặt';

  @override
  String get checkingUpdate => 'Đang kiểm tra cập nhật…';

  @override
  String get updateError => 'Lỗi cập nhật';

  @override
  String get updateReady => 'Sẵn sàng';

  @override
  String get updateCheckHint =>
      'Nhấn “Kiểm tra cập nhật” để tìm phiên bản mới.';

  @override
  String get usingLatestVersion => 'Bạn đang sử dụng phiên bản mới nhất.';

  @override
  String versionAvailable(String version) {
    return 'Phiên bản $version đã sẵn sàng.';
  }

  @override
  String get reinstallRequired => 'Yêu cầu cài đặt lại';

  @override
  String get reinstallMessage =>
      'Phiên bản mới sử dụng chữ ký bảo mật mới. Hãy sao lưu dữ liệu trước khi cài đặt lại.';

  @override
  String get downloadingUpdate => 'Đang tải bản cập nhật…';

  @override
  String downloadedSize(String size) {
    return 'Đã tải $size';
  }

  @override
  String get verifyingUpdate => 'Đang xác minh…';

  @override
  String get verifyingFile => 'Đang kiểm tra tính toàn vẹn của tệp…';

  @override
  String get readyToInstall => 'Sẵn sàng cài đặt!';

  @override
  String get updateDownloaded => 'Bản cập nhật đã tải về và xác minh.';

  @override
  String get installPermissionRequired => 'Cần quyền cài đặt';

  @override
  String get installPermissionHint =>
      'Cho phép cài đặt ứng dụng từ nguồn này rồi thử lại.';

  @override
  String get installingUpdate => 'Đang cài đặt…';

  @override
  String get pleaseWait => 'Vui lòng chờ…';

  @override
  String get genericUpdateError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get skipUpdate => 'Bỏ qua';

  @override
  String get retry => 'Thử lại';

  @override
  String get openDownloadPage => 'Mở trang tải xuống';

  @override
  String get reinstallSteps =>
      '1. Sao lưu dữ liệu\n2. Giữ file backup an toàn\n3. Cài đặt bản mới theo hướng dẫn\n4. Khôi phục backup';

  @override
  String get releaseDetails => 'Chi tiết phiên bản';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get buildLabel => 'Build';

  @override
  String get releaseDate => 'Ngày phát hành';

  @override
  String get fileSize => 'Dung lượng';

  @override
  String get noReleaseNotes => 'Không có ghi chú phát hành.';

  @override
  String get viewOnGitHub => 'Xem trên GitHub';

  @override
  String get fallbackChangeExperience => 'Cải thiện trải nghiệm người dùng';

  @override
  String get fallbackChangeNotifications => 'Tối ưu thông báo sinh nhật';

  @override
  String get fallbackChangeFixes => 'Sửa lỗi phiên bản trước';

  @override
  String get fallbackChangeStability => 'Tăng độ ổn định';

  @override
  String birthdaySyncProgress(int current, int total) {
    return '$current / $total sinh nhật';
  }
}
