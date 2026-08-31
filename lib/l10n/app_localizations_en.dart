// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Birthday Reminder';

  @override
  String get home => 'Home';

  @override
  String get birthdayList => 'Birthday list';

  @override
  String get todayBirthdays => 'Birthdays today';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get seeMore => 'See more';

  @override
  String get noBirthdays => 'No birthdays yet';

  @override
  String get birthdayCalendar => 'Birthday calendar';

  @override
  String get calendarMonth => 'Month';

  @override
  String get calendarDay => 'Day';

  @override
  String get birthdayReminder => 'Birthday reminder';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get userGuide => 'User guide';

  @override
  String get newVersion => 'A new version is available';

  @override
  String get updateNow => 'Update now';

  @override
  String get later => 'Later';

  @override
  String get whatsNew => 'What\'s new:';

  @override
  String get addBirthday => 'Add birthday';

  @override
  String get editBirthday => 'Edit birthday';

  @override
  String get manualAdd => 'Add manually';

  @override
  String get contactAdd => 'Add from contacts';

  @override
  String get search => 'Search';

  @override
  String get selectLanguage => 'Choose display language';

  @override
  String get sessionStatus => 'Session status';

  @override
  String get mode => 'Mode';

  @override
  String get aiTrial => 'Try AI';

  @override
  String monthBirthdays(int month, int count) {
    return 'Birthdays in month $month • $count';
  }

  @override
  String dayBirthdays(String date) {
    return 'Birthdays on $date';
  }

  @override
  String get showMonth => 'Show whole month';

  @override
  String get noMonthBirthdays => 'No birthdays this month.';

  @override
  String get noDayBirthdays => 'No birthdays on this day.';

  @override
  String get improveExperience => 'Improved user experience';

  @override
  String get optimizeNotifications => 'Optimized birthday notifications';

  @override
  String get fixPreviousBugs => 'Fixed issues from the previous version';

  @override
  String get increaseStability => 'Improved stability';

  @override
  String get name => 'Name';

  @override
  String get birthdayDate => 'Birthday date';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String get deleteConfirmMessage => 'Are you sure you want to delete?';

  @override
  String get remindBefore => 'Remind before (days)';

  @override
  String get remindTime => 'Remind time';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncSuccess => 'Sync successful';

  @override
  String get syncError => 'Sync error';

  @override
  String get backupSuccess => 'Backup successful';

  @override
  String get restoreSuccess => 'Restore successful';

  @override
  String get cloudUnavailable => 'Sign in to use cloud sync.';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signOut => 'Sign out';

  @override
  String get exitLocalMode => 'Exit local mode';

  @override
  String get localMode => 'Local mode';

  @override
  String get localModeSubtitle => 'Turn off to use Google account';

  @override
  String get deleteAllFirestore => 'Delete all from Firestore';

  @override
  String get deleteAllFirestoreConfirm =>
      'Are you sure you want to delete all birthdays from Firestore?';

  @override
  String get deletedAllFirestore => 'Deleted all data from Firestore';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get googleConfigError =>
      'Google sign-in not configured correctly on this device.';

  @override
  String get googleUiUnavailable =>
      'Google account picker not available on this device.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get authError => 'An error occurred, please try again';

  @override
  String get testNotification => 'Test notification';

  @override
  String get testNotificationSuccess => 'Test notification sent';

  @override
  String get testNotificationFailed => 'Failed to send test notification';

  @override
  String get ageInvalid => 'Age must be between 0 and 120.';

  @override
  String get nameRequired => 'Please enter a name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get nickname => 'Nickname';

  @override
  String get relationship => 'Relationship';

  @override
  String get note => 'Note';

  @override
  String get calendarType => 'Calendar type';

  @override
  String get solar => 'Solar';

  @override
  String get lunar => 'Lunar';

  @override
  String solarDate(String date) {
    return 'Solar date: $date';
  }

  @override
  String lunarDate(String date) {
    return 'Lunar date: $date';
  }

  @override
  String get repeatAnnually => 'Repeat annually';

  @override
  String get enableNotification => 'Enable notification';

  @override
  String get imagePickError => 'Unable to pick or crop image.';

  @override
  String get imageProcessError => 'Unable to process selected image.';

  @override
  String get permissionRequired => 'Storage permission is required.';

  @override
  String get imageDecodeError => 'Unable to decode image.';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get languageZh => '中文';

  @override
  String get authSubtitle =>
      'Never let a birthday go by without being remembered.';

  @override
  String get or => 'or';

  @override
  String get continueOnDevice => 'Continue on device';

  @override
  String get localModeDescription =>
      'You can still use birthdays, calendar, and reminders on this device. Cloud sync features require sign-in.';

  @override
  String get authenticated => 'Authenticated';

  @override
  String get syncComplete => 'Complete';

  @override
  String get close => 'Close';

  @override
  String syncProgress(int current, int total) {
    return '$current / $total birthdays';
  }

  @override
  String get selectOption => '- Select -';

  @override
  String get cropTitle => 'Crop birthday photo';

  @override
  String get photoPermissionTitle => 'Photo Permission';

  @override
  String get photoPermissionMessage =>
      'The app needs access to your photo library to choose an avatar. Please enable it in Settings.';

  @override
  String get permissionDeniedMessage =>
      'You denied photo access. You can try again or grant permission in Settings.';

  @override
  String get permissionRestrictedMessage =>
      'Photo access is restricted on this device.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get allow => 'Allow';

  @override
  String selectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get sort => 'Sort';

  @override
  String get nearestBirthday => 'Nearest birthday';

  @override
  String get farthestBirthday => 'Farthest birthday';

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
    return 'Age: $age • $days days remaining';
  }

  @override
  String get age => 'Age';

  @override
  String days(int count) {
    return '$count days';
  }

  @override
  String remainingDays(int count) {
    return '$count days remaining';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get enabled => 'On';

  @override
  String get disabled => 'Off';

  @override
  String get notificationTime => 'Reminder time';

  @override
  String get calendarList => 'List';

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
  String get settingsSubtitle => 'Check notifications and app permissions';

  @override
  String get guideSubtitle => 'Learn how to use Birthday Reminder';

  @override
  String get usingOnDevice => 'Using on this device';

  @override
  String get savedLocally => 'Saved only on this device';

  @override
  String get options => 'Options';

  @override
  String get chooseUsageMode => 'Choose usage mode';

  @override
  String get backToLogin => 'Return to sign-in screen';

  @override
  String get backupToFirestore => 'Back up to Firestore';

  @override
  String get syncFromFirestore => 'Sync from Firestore';

  @override
  String get backupInProgress => 'Backing up...';

  @override
  String get failed => 'Failed';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get notificationSection => 'Notifications';

  @override
  String get notificationPermission => 'Notification permission';

  @override
  String get appNotifications => 'App notifications';

  @override
  String get exactAlarm => 'Exact alarms';

  @override
  String get deviceTimezone => 'Device time zone';

  @override
  String get notificationChannel => 'Notification channel';

  @override
  String get checking => 'Checking';

  @override
  String get granted => 'Granted';

  @override
  String get notGranted => 'Not granted';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get sendTestNotification => 'Send test notification';

  @override
  String get testAfterTenSeconds => 'Test notification after 10 seconds';

  @override
  String get openNotificationSettings => 'Open notification settings';

  @override
  String get allowExactAlarm => 'Allow exact alarms';

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
    return 'Pending reminders: $count';
  }

  @override
  String get resyncReminders => 'Resync reminders';

  @override
  String get noPendingReminders => 'No pending reminders.';

  @override
  String get collapse => 'Collapse';

  @override
  String showMoreReminders(int count) {
    return 'Show $count more reminders';
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
  String get appInformation => 'App information';

  @override
  String get loading => 'Loading…';

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
  String get updateApp => 'Update app';

  @override
  String get checkNewVersion => 'Check for a new version';

  @override
  String get artificialIntelligence => 'Artificial intelligence';

  @override
  String get provider => 'Provider';

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
  String get testConnection => 'Test connection';

  @override
  String get fetchModels => 'Fetch models';

  @override
  String get saveConfiguration => 'Save configuration';

  @override
  String get deleteApiKey => 'Delete API key';

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
  String get aiAssistant => 'AI Assistant';

  @override
  String personalizedFor(String name) {
    return 'Personalized for $name';
  }

  @override
  String get aiReady => 'AI ready';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get openAiSettings => 'Open AI settings';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get giftSuggestions => 'Gift suggestions';

  @override
  String get wishSuggestions => 'Wish suggestions';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get reminderStatus => 'Reminder status';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get notScheduled => 'Not scheduled';

  @override
  String get scheduleLost => 'Schedule missing — resync needed';

  @override
  String get pastTime => 'Past due';

  @override
  String nextReminder(String time) {
    return 'Next reminder: $time';
  }

  @override
  String get rescheduleReminder => 'Reschedule reminder';

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
    return '$name\'s birthday is on $date';
  }

  @override
  String copied(String label) {
    return 'Copied $label.';
  }

  @override
  String get copyAll => 'Copy all';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get noSuggestions => 'No suggestions yet.';

  @override
  String reason(String value) {
    return 'Reason: $value';
  }

  @override
  String budget(String value) {
    return 'Budget: $value';
  }

  @override
  String get personalizing => 'Personalizing again...';

  @override
  String get personalizedProfile => 'Personalized from profile';

  @override
  String modelValidResults(int count, int target) {
    return 'Model returned $count/$target valid results.';
  }

  @override
  String get suggestedByAi => 'Suggested by AI';

  @override
  String get aiAndQuick => 'AI + quick suggestions';

  @override
  String get usingQuickSuggestions => 'Using quick suggestions';

  @override
  String giftsFor(String name) {
    return 'Suggestions for $name';
  }

  @override
  String wishesFor(String name) {
    return '10 wishes for $name';
  }

  @override
  String get giftUnit => 'items';

  @override
  String get share => 'Share';

  @override
  String get solarBirthday => 'Solar birthday';

  @override
  String get lunarBirthday => 'Lunar birthday';

  @override
  String atTime(String time) {
    return 'at $time';
  }

  @override
  String get invalidApiKey => 'The API key is invalid or unauthorized.';

  @override
  String get modelNotFound => 'Model not found.';

  @override
  String get quotaExceeded => 'Quota or request limit exceeded.';

  @override
  String get aiTimeout => 'AI response timed out. Try again.';

  @override
  String get serverConnectionFailed => 'Could not connect to the server.';

  @override
  String get testNotificationSent => 'Test notification sent';

  @override
  String get updateTitle => 'Update App';

  @override
  String get currentVersion => 'Current version';

  @override
  String get latestVersion => 'Latest version';

  @override
  String get upToDate => 'Up to date';

  @override
  String get newVersionAvailable => 'New version available!';

  @override
  String get downloadUpdate => 'Download update';

  @override
  String get installUpdate => 'Install update';

  @override
  String get checkingUpdate => 'Checking for updates…';

  @override
  String get updateError => 'Update error';

  @override
  String get updateReady => 'Ready';

  @override
  String get updateCheckHint =>
      'Tap “Check for updates” to look for a new version.';

  @override
  String get usingLatestVersion => 'You are using the latest version.';

  @override
  String versionAvailable(String version) {
    return 'Version $version is available.';
  }

  @override
  String get reinstallRequired => 'Reinstallation required';

  @override
  String get reinstallMessage =>
      'The new version uses a new security signature. Back up your data before reinstalling.';

  @override
  String get downloadingUpdate => 'Downloading update…';

  @override
  String downloadedSize(String size) {
    return 'Downloaded $size';
  }

  @override
  String get verifyingUpdate => 'Verifying…';

  @override
  String get verifyingFile => 'Checking file integrity…';

  @override
  String get readyToInstall => 'Ready to install!';

  @override
  String get updateDownloaded => 'The update has been downloaded and verified.';

  @override
  String get installPermissionRequired => 'Installation permission required';

  @override
  String get installPermissionHint =>
      'Allow app installation from this source, then try again.';

  @override
  String get installingUpdate => 'Installing…';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get genericUpdateError => 'Something went wrong. Please try again.';

  @override
  String get skipUpdate => 'Skip';

  @override
  String get retry => 'Retry';

  @override
  String get openDownloadPage => 'Open download page';

  @override
  String get reinstallSteps =>
      '1. Back up your data\n2. Keep the backup file safe\n3. Install the new version as instructed\n4. Restore the backup';

  @override
  String get releaseDetails => 'Release details';

  @override
  String get versionLabel => 'Version';

  @override
  String get buildLabel => 'Build';

  @override
  String get releaseDate => 'Release date';

  @override
  String get fileSize => 'Size';

  @override
  String get noReleaseNotes => 'No release notes.';

  @override
  String get viewOnGitHub => 'View on GitHub';

  @override
  String get fallbackChangeExperience => 'Improved user experience';

  @override
  String get fallbackChangeNotifications => 'Optimized birthday notifications';

  @override
  String get fallbackChangeFixes => 'Fixed issues from the previous version';

  @override
  String get fallbackChangeStability => 'Improved stability';

  @override
  String birthdaySyncProgress(int current, int total) {
    return '$current / $total birthdays';
  }
}
