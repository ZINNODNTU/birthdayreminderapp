import 'package:birthdayreminderapp/features/ai/services/ai_response_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GiftSuggestionsParser();
  const wishParser = BirthdayWishParser();

  test('compact schema gifts: g array with n/r/b/c keys parses 10', () {
    final raw =
        '{"g":[{"n":"Tai nghe","r":"âm thanh tốt","b":"500.000đ","c":"Công nghệ"}'
        ',{"n":"Đồng hồ","r":"thời trang","b":"1.200.000đ","c":"Phụ kiện"}'
        ',{"n":"Balo","r":"tiện dụng","b":"600.000đ","c":"Thời trang"}'
        ',{"n":"Sách","r":"tri thức","b":"250.000đ","c":"Sách"}'
        ',{"n":"Bình giữ nhiệt","r":"bền","b":"300.000đ","c":"Đồ dùng"}'
        ',{"n":"Voucher spa","r":"thư giãn","b":"900.000đ","c":"Trải nghiệm"}'
        ',{"n":"Kem dưỡng","r":"an toàn","b":"450.000đ","c":"Chăm sóc"}'
        ',{"n":"Giày","r":"thoải mái","b":"1.100.000đ","c":"Thời trang"}'
        ',{"n":"Hoa","r":"tươi","b":"350.000đ","c":"Kỷ niệm"}'
        ',{"n":"Bánh","r":"ngon","b":"500.000đ","c":"Trải nghiệm"}]}';
    final r = parser.parse(raw);
    expect(r.items, hasLength(10));
    expect(r.items.first.name, 'Tai nghe');
    expect(r.items.first.category, 'Công nghệ');
  });

  test('compact schema wishes: w array with s/t keys parses 10', () {
    final raw =
        '{"w":['
        '{"s":"Ngắn gọn","t":"Chúc mừng sinh nhật!"},'
        '{"s":"Tình cảm","t":"Mong bạn luôn hạnh phúc."},'
        '{"s":"Vui vẻ","t":"Tuổi mới thật nhiều niềm vui."},'
        '{"s":"Ấm áp","t":"Một năm mới đong đầy yêu thương."},'
        '{"s":"Chân thành","t":"Chúc bạn sức khỏe dồi dào."},'
        '{"s":"Dễ thương","t":"Sinh nhật vui vẻ nhé!"},'
        '{"s":"Truyền cảm hứng","t":"Bạn xứng đáng được yêu thương."},'
        '{"s":"Tự nhiên","t":"Chúc bạn luôn bình an."},'
        '{"s":"Đặc biệt","t":"Hôm nay là ngày của bạn."},'
        '{"s":"Sâu sắc","t":"Cầu chúc cho một năm rực rỡ."}]}';
    final r = wishParser.parse(raw);
    expect(r.wishes, hasLength(10));
    expect(r.wishes.first.style, 'Ngắn gọn');
    expect(r.wishes.first.text, 'Chúc mừng sinh nhật!');
  });

  test('mixed compact + long schema still parses', () {
    final raw = '{"gifts":[{"n":"Tai nghe","r":"âm","b":"500k","c":"Tech"}]}';
    final r = parser.parse(raw);
    expect(r.items, hasLength(1));
    expect(r.items.first.name, 'Tai nghe');
  });
}
