import 'package:lunar/lunar.dart';
import '../models/birthday.dart';

class LunarConverter {
  /// Chuyển đổi ngày dương sang âm lịch sử dụng thư viện [lunar].
  static LunarDateTime toLunar(DateTime solarDate) {
    final lunar = Lunar.fromDate(solarDate);
    return LunarDateTime(
      day: lunar.getDay(),
      month: lunar.getMonth(),
      year: lunar.getYear(),
    );
  }

  /// Chuyển đổi ngày âm lịch sang dương sử dụng thư viện [lunar].
  static DateTime toSolar(LunarDateTime lunarDate) {
    final lunarObj = Lunar.fromYmd(
      lunarDate.year,
      lunarDate.month,
      lunarDate.day,
    );
    final solar = lunarObj.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }
}
