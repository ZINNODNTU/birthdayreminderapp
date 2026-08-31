// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '生日提醒';

  @override
  String get home => '首页';

  @override
  String get birthdayList => '生日列表';

  @override
  String get todayBirthdays => '今天的生日';

  @override
  String get upcoming => '即将到来';

  @override
  String get seeMore => '查看更多';

  @override
  String get noBirthdays => '暂无生日';

  @override
  String get birthdayCalendar => '生日日历';

  @override
  String get calendarMonth => '月';

  @override
  String get calendarDay => '日';

  @override
  String get birthdayReminder => '生日提醒';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get userGuide => '使用指南';

  @override
  String get newVersion => '发现新版本';

  @override
  String get updateNow => '立即更新';

  @override
  String get later => '稍后';

  @override
  String get whatsNew => '更新内容：';

  @override
  String get addBirthday => '添加生日';

  @override
  String get editBirthday => '编辑生日';

  @override
  String get manualAdd => '手动添加';

  @override
  String get contactAdd => '从联系人添加';

  @override
  String get search => '搜索';

  @override
  String get selectLanguage => '选择显示语言';

  @override
  String get sessionStatus => '会话状态';

  @override
  String get mode => '模式';

  @override
  String get aiTrial => '试用 AI';

  @override
  String monthBirthdays(int month, int count) {
    return '$month 月生日 • $count';
  }

  @override
  String dayBirthdays(String date) {
    return '$date 的生日';
  }

  @override
  String get showMonth => '查看整月';

  @override
  String get noMonthBirthdays => '本月没有生日。';

  @override
  String get noDayBirthdays => '当天没有生日。';

  @override
  String get improveExperience => '改善用户体验';

  @override
  String get optimizeNotifications => '优化生日通知';

  @override
  String get fixPreviousBugs => '修复上一版本问题';

  @override
  String get increaseStability => '提高稳定性';

  @override
  String get name => '姓名';

  @override
  String get birthdayDate => '出生日期';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get chooseImage => '选择图片';

  @override
  String get delete => '删除';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get deleteConfirmMessage => '您确定要删除吗？';

  @override
  String get remindBefore => '提前提醒（天）';

  @override
  String get remindTime => '提醒时间';

  @override
  String get syncing => '正在同步...';

  @override
  String get syncSuccess => '同步成功';

  @override
  String get syncError => '同步错误';

  @override
  String get backupSuccess => '备份成功';

  @override
  String get restoreSuccess => '恢复成功';

  @override
  String get cloudUnavailable => '登录以使用云同步。';

  @override
  String get signInGoogle => '使用 Google 登录';

  @override
  String get signOut => '退出登录';

  @override
  String get exitLocalMode => '退出本地模式';

  @override
  String get localMode => '本地模式';

  @override
  String get localModeSubtitle => '关闭以使用 Google 账户';

  @override
  String get deleteAllFirestore => '从 Firestore 删除全部';

  @override
  String get deleteAllFirestoreConfirm => '您确定要从 Firestore 删除所有生日吗？';

  @override
  String get deletedAllFirestore => '已从 Firestore 删除所有数据';

  @override
  String get noInternet => '无网络连接';

  @override
  String get googleConfigError => '此设备上的 Google 登录配置不正确。';

  @override
  String get googleUiUnavailable => '此设备不提供 Google 帐户选择器。';

  @override
  String get loginFailed => '登录失败';

  @override
  String get authError => '发生错误，请重试';

  @override
  String get testNotification => '测试通知';

  @override
  String get testNotificationSuccess => '测试通知已发送';

  @override
  String get testNotificationFailed => '发送测试通知失败';

  @override
  String get ageInvalid => '年龄必须在 0 到 120 之间。';

  @override
  String get nameRequired => '请输入姓名';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get other => '其他';

  @override
  String get nickname => '昵称';

  @override
  String get relationship => '关系';

  @override
  String get note => '备注';

  @override
  String get calendarType => '日历类型';

  @override
  String get solar => '阳历';

  @override
  String get lunar => '农历';

  @override
  String solarDate(String date) {
    return '阳历日期：$date';
  }

  @override
  String lunarDate(String date) {
    return '农历日期：$date';
  }

  @override
  String get repeatAnnually => '每年重复';

  @override
  String get enableNotification => '启用通知';

  @override
  String get imagePickError => '无法选择或裁剪图片。';

  @override
  String get imageProcessError => '无法处理所选图片。';

  @override
  String get permissionRequired => '需要存储权限。';

  @override
  String get imageDecodeError => '无法解码图片。';

  @override
  String get chooseLanguage => '选择语言';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文';

  @override
  String get authSubtitle => '不要让任何一个生日在没有被记住的情况下悄然过去。';

  @override
  String get or => '或';

  @override
  String get continueOnDevice => '在设备上继续';

  @override
  String get localModeDescription => '您仍然可以在此设备上使用生日、日历和提醒功能。云同步功能需要登录。';

  @override
  String get authenticated => '已登录';

  @override
  String get syncComplete => '完成';

  @override
  String get close => '关闭';

  @override
  String syncProgress(int current, int total) {
    return '$current / $total 个生日';
  }

  @override
  String get selectOption => '- 选择 -';

  @override
  String get cropTitle => '裁剪生日照片';

  @override
  String get photoPermissionTitle => '照片权限';

  @override
  String get photoPermissionMessage => '应用需要访问您的照片库以选择头像。请在设置中启用。';

  @override
  String get permissionDeniedMessage => '您拒绝了照片访问权限。您可以重试或在设置中授予权限。';

  @override
  String get permissionRestrictedMessage => '此设备上的照片访问受限。';

  @override
  String get openSettings => '打开设置';

  @override
  String get allow => '允许';

  @override
  String selectedCount(int count) {
    return '已选择：$count';
  }

  @override
  String get selectAll => '全选';

  @override
  String get deleteSelected => '删除所选';

  @override
  String get clearSelection => '取消选择';

  @override
  String get sort => '排序';

  @override
  String get nearestBirthday => '最近的生日';

  @override
  String get farthestBirthday => '最远的生日';

  @override
  String get deleteBirthdayTitle => 'Delete birthday?';

  @override
  String get deleteOneConfirm =>
      'Are you sure you want to delete this birthday?';

  @override
  String deleteManyConfirm(int count) {
    return 'Are you sure you want to delete $count selected birthdays?';
  }

  @override
  String get deletedOne => 'Birthday deleted';

  @override
  String deletedMany(int count) {
    return 'Deleted $count birthdays';
  }

  @override
  String deleteFailed(int count) {
    return 'Could not delete $count birthdays. Data will be synced again.';
  }

  @override
  String ageAndDays(int age, int days) {
    return '年龄：$age • 还有 $days 天';
  }

  @override
  String get age => '年龄';

  @override
  String days(int count) {
    return '$count 天';
  }

  @override
  String remainingDays(int count) {
    return '还有 $count 天';
  }

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get enabled => '开启';

  @override
  String get disabled => '关闭';

  @override
  String get notificationTime => '提醒时间';

  @override
  String get calendarList => '列表';

  @override
  String get contactPermissionDenied => 'Contacts permission denied';

  @override
  String get unnamed => 'Unnamed';

  @override
  String get selectFromContacts => 'Select from contacts';

  @override
  String get toggleSelectAll => 'Select or clear all';

  @override
  String get noContactsToAdd => 'No contacts left to add';

  @override
  String get settingsSubtitle => '检查通知和应用权限';

  @override
  String get guideSubtitle => '查看 Birthday Reminder 使用方法';

  @override
  String get usingOnDevice => '正在此设备上使用';

  @override
  String get savedLocally => '仅保存在此设备';

  @override
  String get options => '选项';

  @override
  String get chooseUsageMode => '选择使用模式';

  @override
  String get backToLogin => '返回登录页面';

  @override
  String get backupToFirestore => '备份到 Firestore';

  @override
  String get syncFromFirestore => '从 Firestore 同步';

  @override
  String get backupInProgress => 'Backing up...';

  @override
  String get failed => 'Failed';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get notificationSection => '通知';

  @override
  String get notificationPermission => '通知权限';

  @override
  String get appNotifications => '应用通知';

  @override
  String get exactAlarm => '精确闹钟';

  @override
  String get deviceTimezone => '设备时区';

  @override
  String get notificationChannel => '通知频道';

  @override
  String get checking => '检查中';

  @override
  String get granted => '已授权';

  @override
  String get notGranted => '未授权';

  @override
  String get on => '已开启';

  @override
  String get off => '已关闭';

  @override
  String get sendTestNotification => '发送测试通知';

  @override
  String get testAfterTenSeconds => 'Test notification after 10 seconds';

  @override
  String get openNotificationSettings => '打开通知设置';

  @override
  String get allowExactAlarm => '允许精确闹钟';

  @override
  String get testAfterOneMinute => 'Test birthday reminder after 1 minute';

  @override
  String get notificationPermissionOff =>
      'Notification permission is disabled.';

  @override
  String get exactAlarmPermissionMissing =>
      'Exact alarm permission is not granted.';

  @override
  String get notificationsDisabledSchedule =>
      'Notification permission is disabled — cannot schedule.';

  @override
  String get scheduleNotRetained =>
      'The device did not retain the schedule — check alarm permission.';

  @override
  String get unknownError => 'unknown error';

  @override
  String scheduledTestAt(String time) {
    return 'Test notification scheduled at $time.';
  }

  @override
  String scheduledMinuteTestAt(String time) {
    return 'One-minute test scheduled at $time.';
  }

  @override
  String scheduleTestFailed(String error) {
    return 'Could not schedule test notification: $error';
  }

  @override
  String scheduleMinuteFailed(String error) {
    return 'Could not schedule one-minute test: $error';
  }

  @override
  String reminderPendingCount(int count) {
    return '待处理提醒：$count';
  }

  @override
  String get resyncReminders => '重新同步提醒';

  @override
  String get noPendingReminders => '没有待处理提醒。';

  @override
  String get collapse => '收起';

  @override
  String showMoreReminders(int count) {
    return '再查看 $count 个提醒';
  }

  @override
  String get reminderSchedule => 'Reminder';

  @override
  String birthdayShortId(String id) {
    return 'Birthday $id…';
  }

  @override
  String reminderResyncSuccess(int scheduled, int cancelled) {
    return 'Scheduled $scheduled, cancelled $cancelled old reminders.';
  }

  @override
  String syncFailedDetails(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get waiting => 'waiting';

  @override
  String get appInformation => '应用信息';

  @override
  String get loading => '加载中…';

  @override
  String appVersionInfo(String name, String version, String build) {
    return '$name — version $version (build $build)';
  }

  @override
  String testChannel(String id) {
    return 'Test channel: $id';
  }

  @override
  String mainChannel(String id) {
    return 'Main channel: $id';
  }

  @override
  String testNotificationId(String id) {
    return 'Test notification ID: $id';
  }

  @override
  String scheduledTestNotificationId(String id) {
    return 'Scheduled test notification ID: $id';
  }

  @override
  String get updateApp => '更新应用';

  @override
  String get checkNewVersion => '检查新版本';

  @override
  String get artificialIntelligence => '人工智能';

  @override
  String get provider => '服务商';

  @override
  String get openAiCompatible => 'OpenAI / compatible';

  @override
  String get apiKeyNotSaved => 'No API key saved.';

  @override
  String apiKeyCurrent(String key) {
    return 'Current: $key';
  }

  @override
  String get showApiKey => 'Show API key';

  @override
  String get hideApiKey => 'Hide API key';

  @override
  String get pasteClipboard => 'Paste from clipboard';

  @override
  String get testConnection => '测试连接';

  @override
  String get fetchModels => '获取模型列表';

  @override
  String get saveConfiguration => '保存配置';

  @override
  String get deleteApiKey => '删除 API 密钥';

  @override
  String get modelRequired => 'Please enter a model.';

  @override
  String get apiKeyRequired => 'Please enter an API key.';

  @override
  String get baseUrlRequired => 'Please enter a Base URL.';

  @override
  String get apiKeySaved => 'Configuration and API key saved securely.';

  @override
  String get apiKeyDeleted => 'API key deleted.';

  @override
  String get clipboardNoApiKey => 'Clipboard has no API key.';

  @override
  String apiKeyPasted(int count) {
    return 'API key pasted ($count characters).';
  }

  @override
  String connectionSuccess(int latency, String reply) {
    return 'Connected ($latency ms) — Reply: \"$reply\"';
  }

  @override
  String get modelsUnavailable =>
      'Could not load models — enter an ID manually.';

  @override
  String modelsLoaded(int count) {
    return 'Loaded $count models.';
  }

  @override
  String get aiUnavailable => 'AI is unavailable.';

  @override
  String get aiAssistant => 'AI 助手';

  @override
  String personalizedFor(String name) {
    return '为 $name 个性化';
  }

  @override
  String get aiReady => 'AI 已就绪';

  @override
  String get notConfigured => '未配置';

  @override
  String get openAiSettings => '打开 AI 设置';

  @override
  String get aiThinking => 'AI 正在思考...';

  @override
  String get giftSuggestions => '礼物建议';

  @override
  String get wishSuggestions => '祝福语建议';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get reminderStatus => '提醒状态';

  @override
  String get scheduled => '已计划';

  @override
  String get notScheduled => '未计划';

  @override
  String get scheduleLost => '计划丢失 — 需要同步';

  @override
  String get pastTime => '已过期';

  @override
  String nextReminder(String time) {
    return '下次提醒：$time';
  }

  @override
  String get rescheduleReminder => '重新安排提醒';

  @override
  String get notificationDisabledPerson =>
      'Notifications are disabled for this person.';

  @override
  String get noReminderScheduled => 'No reminder scheduled.';

  @override
  String reminderScheduledAt(String time) {
    return 'Scheduled at $time.';
  }

  @override
  String reminderRescheduledAt(String time) {
    return 'Reminder rescheduled$time.';
  }

  @override
  String notificationDisplayFailed(String error) {
    return 'Could not show notification: $error';
  }

  @override
  String get notificationDisabledHelp =>
      'Notifications are disabled. Enable notification permission for the app.';

  @override
  String birthdayShare(String name, String date) {
    return '$name 的生日是 $date';
  }

  @override
  String copied(String label) {
    return '已复制 $label。';
  }

  @override
  String get copyAll => '全部复制';

  @override
  String get regenerate => '重新生成';

  @override
  String get noSuggestions => '暂无建议。';

  @override
  String reason(String value) {
    return 'Reason: $value';
  }

  @override
  String budget(String value) {
    return 'Budget: $value';
  }

  @override
  String get personalizing => '正在重新个性化...';

  @override
  String get personalizedProfile => '根据资料个性化';

  @override
  String modelValidResults(int count, int target) {
    return 'Model returned $count/$target valid results.';
  }

  @override
  String get suggestedByAi => 'AI 推荐';

  @override
  String get aiAndQuick => 'AI + 快速建议';

  @override
  String get usingQuickSuggestions => '正在使用快速建议';

  @override
  String giftsFor(String name) {
    return '为 $name 提供的建议';
  }

  @override
  String wishesFor(String name) {
    return '给 $name 的 10 条祝福';
  }

  @override
  String get giftUnit => '项';

  @override
  String get share => '分享';

  @override
  String get solarBirthday => '公历生日';

  @override
  String get lunarBirthday => '农历生日';

  @override
  String atTime(String time) {
    return '于 $time';
  }

  @override
  String get invalidApiKey => 'API 密钥无效或无权限。';

  @override
  String get modelNotFound => '找不到模型。';

  @override
  String get quotaExceeded => '已超出配额或请求限制。';

  @override
  String get aiTimeout => 'AI 响应超时，请重试。';

  @override
  String get serverConnectionFailed => '无法连接服务器。';

  @override
  String get testNotificationSent => '测试通知已发送';

  @override
  String get updateTitle => '更新应用';

  @override
  String get currentVersion => '当前版本';

  @override
  String get latestVersion => '最新版本';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get newVersionAvailable => '有新版本可用！';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get installUpdate => '安装更新';

  @override
  String get checkingUpdate => '正在检查更新…';

  @override
  String get updateError => '更新错误';

  @override
  String get updateReady => '准备就绪';

  @override
  String get updateCheckHint => '点击“检查更新”以查找新版本。';

  @override
  String get usingLatestVersion => '您正在使用最新版本。';

  @override
  String versionAvailable(String version) {
    return '版本 $version 已可用。';
  }

  @override
  String get reinstallRequired => '需要重新安装';

  @override
  String get reinstallMessage => '新版本使用新的安全签名。重新安装前请备份数据。';

  @override
  String get downloadingUpdate => '正在下载更新…';

  @override
  String downloadedSize(String size) {
    return '已下载 $size';
  }

  @override
  String get verifyingUpdate => '正在验证…';

  @override
  String get verifyingFile => '正在检查文件完整性…';

  @override
  String get readyToInstall => '可以安装！';

  @override
  String get updateDownloaded => '更新已下载并通过验证。';

  @override
  String get installPermissionRequired => '需要安装权限';

  @override
  String get installPermissionHint => '请允许从此来源安装应用，然后重试。';

  @override
  String get installingUpdate => '正在安装…';

  @override
  String get pleaseWait => '请稍候…';

  @override
  String get genericUpdateError => '出现错误，请重试。';

  @override
  String get skipUpdate => '跳过';

  @override
  String get retry => '重试';

  @override
  String get openDownloadPage => '打开下载页面';

  @override
  String get reinstallSteps => '1. 备份数据\n2. 妥善保管备份文件\n3. 按照说明安装新版本\n4. 恢复备份';

  @override
  String get releaseDetails => '版本详情';

  @override
  String get versionLabel => '版本';

  @override
  String get buildLabel => '构建号';

  @override
  String get releaseDate => '发布日期';

  @override
  String get fileSize => '大小';

  @override
  String get noReleaseNotes => '暂无发行说明。';

  @override
  String get viewOnGitHub => '在 GitHub 上查看';

  @override
  String get fallbackChangeExperience => '改善用户体验';

  @override
  String get fallbackChangeNotifications => '优化生日通知';

  @override
  String get fallbackChangeFixes => '修复上一版本的问题';

  @override
  String get fallbackChangeStability => '提高稳定性';

  @override
  String birthdaySyncProgress(int current, int total) {
    return '$current / $total 个生日';
  }
}
