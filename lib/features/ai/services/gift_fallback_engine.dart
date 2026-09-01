import '../domain/ai_provider.dart';
import 'ai_response_parsers.dart';

/// Local, deterministic gift-suggestion engine used whenever the AI
/// provider times out, returns nothing usable, or returns fewer than
/// `kGiftTargetCount` items.
///
/// V3 personalisation: every output MUST be tailored to the specific
/// (name, nickname, gender, age, relationship) tuple. Two people with
/// the same age+gender but a different relationship MUST produce
/// different suggestions.
class GiftFallbackEngine {
  const GiftFallbackEngine();

  /// Produce a list with at least [kGiftTargetCount] suggestions.
  List<GiftSuggestion> suggestions({
    String? gender,
    int? age,
    String? relationship,
    String? name,
    String? nickname,
  }) {
    final g = _normaliseGender(gender);
    final rel = _normaliseRelationship(relationship);
    final bucket = _normaliseAgeGroup(age);
    final n = _displayName(name, nickname);
    final ageLabel = age == null ? '' : '$age';

    // Pick relationship-aware templates first, age-aware templates
    // second, and finally pad with relationship-neutral gifts.
    final pool = <GiftSuggestion>[
      ..._relationshipSeeds(rel, g, age),
      ..._ageSeeds(bucket, g),
    ];
    final items = <GiftSuggestion>[];
    final seen = <String>{};
    for (final t in pool) {
      final personalised = _personalise(t, n, rel, ageLabel);
      final key = personalised.name.toLowerCase().trim();
      if (key.isEmpty) continue;
      if (seen.add(key)) items.add(personalised);
      if (items.length >= kGiftTargetCount) break;
    }
    for (final t in _generic(g)) {
      final personalised = _personalise(t, n, rel, ageLabel);
      final key = personalised.name.toLowerCase().trim();
      if (seen.add(key)) items.add(personalised);
      if (items.length >= kGiftTargetCount) break;
    }
    return items.take(kGiftTargetCount).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  List<GiftSuggestion> _relationshipSeeds(
    _Relationship rel,
    _Gender g,
    int? age,
  ) {
    switch (rel) {
      case _Relationship.lover:
        return _lover(g, age);
      case _Relationship.closeFriend:
        return _closeFriend(g, age);
      case _Relationship.colleague:
        return _colleague(g);
      case _Relationship.parent:
        return _parent(g);
      case _Relationship.child:
        return _child(g);
      case _Relationship.sibling:
        return _sibling(g);
      case _Relationship.neutral:
        return const [];
    }
  }

  List<GiftSuggestion> _lover(_Gender g, int? age) => const [
    GiftSuggestion(
      name: 'Bộ trang sức nhỏ cá nhân hoá',
      reason: 'Khắc tên hoặc ngày kỷ niệm — món quà ý nghĩa cho người thương.',
      budget: '1.200.000 – 4.000.000đ',
      category: 'Trang sức',
    ),
    GiftSuggestion(
      name: 'Voucher trải nghiệm đôi (spa, nấu ăn, workshop)',
      reason: 'Tạo kỷ niệm chung thay vì chỉ đồ vật.',
      budget: '1.500.000 – 4.500.000đ',
      category: 'Trải nghiệm đôi',
    ),
    GiftSuggestion(
      name: 'Bộ ảnh cặp đôi + khung ảnh',
      reason: 'Lưu giữ khoảnh khắc bên nhau, gần gũi.',
      budget: '600.000 – 1.500.000đ',
      category: 'Kỷ niệm',
    ),
    GiftSuggestion(
      name: 'Nến thơm + bộ chăm sóc cơ thể cao cấp',
      reason: 'Không gian thư giãn cho hai người sau ngày dài.',
      budget: '700.000 – 2.000.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Sổ tay da + bút ký tên riêng',
      reason: 'Đồng hành mỗi ngày, gợi nhớ mối quan hệ.',
      budget: '450.000 – 1.400.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Khăn len / áo khoác đôi',
      reason: 'Thể hiện sự quan tâm đến sức khoẻ và phong cách chung.',
      budget: '900.000 – 3.500.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Album nhạc hoặc playlist cá nhân hoá',
      reason: 'Món quà tinh tế, dễ chuẩn bị nhưng rất có ý nghĩa.',
      budget: '150.000 – 600.000đ',
      category: 'Kỷ niệm',
    ),
    GiftSuggestion(
      name: 'Đồng hồ đôi hoặc vòng tay đôi',
      reason: 'Biểu tượng kết nối, mang theo mỗi ngày.',
      budget: '1.200.000 – 4.500.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Bữa tối lãng mạn tự chuẩn bị',
      reason: 'Không gian riêng, dành trọn thời gian cho nhau.',
      budget: '500.000 – 2.500.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Loa bluetooth nhỏ — pin dài',
      reason: 'Cùng nghe nhạc trong những buổi tối quây quần.',
      budget: '700.000 – 2.500.000đ',
      category: 'Công nghệ',
    ),
  ];

  List<GiftSuggestion> _closeFriend(_Gender g, int? age) {
    final youngTail = age != null && age <= 25
        ? const [
            GiftSuggestion(
              name: 'Voucher quán cà phê yêu thích 3 tháng',
              reason: 'Cùng nhau tái khám phá quán quen mỗi tuần.',
              budget: '450.000 – 1.000.000đ',
              category: 'Trải nghiệm',
            ),
          ]
        : const <GiftSuggestion>[];
    return [
      GiftSuggestion(
        name: 'Voucher quán ăn / cafe quen 3 tháng',
        reason: 'Giữ thói quen gặp mặt đều đặn, gắn kết hơn.',
        budget: '450.000 – 1.200.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Bộ board game / trò chơi nhóm',
        reason: 'Buổi tối cuối tuần vui vẻ bên nhau.',
        budget: '350.000 – 900.000đ',
        category: 'Giải trí',
      ),
      GiftSuggestion(
        name: 'Sổ tay mini + bút gel mực đẹp',
        reason: 'Tiện ghi lại kế hoạch cá nhân / chuyến đi chung.',
        budget: '120.000 – 350.000đ',
        category: 'Phụ kiện',
      ),
      GiftSuggestion(
        name: 'Loa bluetooth mini chống nước',
        reason: 'Mang theo các buổi picnic, gặp mặt ngoài trời.',
        budget: '600.000 – 1.500.000đ',
        category: 'Công nghệ',
      ),
      GiftSuggestion(
        name: 'Bộ quà tặng sở thích (sách, trà, nến thơm)',
        reason: 'Chọn theo sở thích đã biết của bạn thân.',
        budget: '400.000 – 1.200.000đ',
        category: 'Sở thích',
      ),
      GiftSuggestion(
        name: 'Khung ảnh + bộ ảnh chung',
        reason: 'Lưu giữ kỷ niệm tình bạn đã qua.',
        budget: '250.000 – 700.000đ',
        category: 'Kỷ niệm',
      ),
      GiftSuggestion(
        name: 'Voucher đi xem phim / show diễn',
        reason: 'Cùng đi trải nghiệm điều mới mẻ.',
        budget: '300.000 – 1.200.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Balo / túi tote canvas',
        reason: 'Đi chơi, đi học, đi làm đều tiện.',
        budget: '250.000 – 800.000đ',
        category: 'Thời trang',
      ),
      ...youngTail,
      GiftSuggestion(
        name: 'Bữa trưa / tối tại nhà hàng mới',
        reason: 'Khám phá địa điểm mới cùng bạn thân.',
        budget: '500.000 – 1.800.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Tai nghe chụp chống ồn tầm trung',
        reason: 'Học tập / làm việc tập trung hơn.',
        budget: '1.500.000 – 3.500.000đ',
        category: 'Công nghệ',
      ),
    ];
  }

  List<GiftSuggestion> _colleague(_Gender g) => const [
    GiftSuggestion(
      name: 'Bộ ấm trà gốm / cà phê pour-over',
      reason: 'Quà văn phòng tinh tế, dùng hằng ngày.',
      budget: '450.000 – 1.500.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Bộ sổ tay công sở + bút ký cao cấp',
      reason: 'Tiện ghi chú, phong thái chuyên nghiệp.',
      budget: '350.000 – 1.200.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Balo / túi laptop công sở',
      reason: 'Thiết thực cho người làm việc văn phòng.',
      budget: '900.000 – 3.500.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Voucher cà phê chuỗi 1 tháng',
      reason: 'Tiện cho ngày dài ở văn phòng.',
      budget: '300.000 – 700.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ sách kinh doanh / kỹ năng',
      reason: 'Đầu tư phát triển nghề nghiệp.',
      budget: '250.000 – 800.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Đồng hồ bàn / đồng hồ treo tường',
      reason: 'Trang trí bàn làm việc tinh tế.',
      budget: '400.000 – 1.500.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Bộ trà / cà phê specialty nhập khẩu',
      reason: 'Quà vặt văn phòng chất lượng.',
      budget: '350.000 – 900.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ dụng cụ vệ sinh bàn phím / màn hình',
      reason: 'Thiết thực cho dân IT / văn phòng.',
      budget: '150.000 – 500.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Bữa trưa cùng team / phòng',
      reason: 'Quà tập thể dễ tổ chức, gắn kết đồng nghiệp.',
      budget: '500.000 – 2.500.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ quà Tết / hộp quà văn phòng',
      reason: 'Phù hợp cho sự kiện, lễ tết công ty.',
      budget: '450.000 – 1.500.000đ',
      category: 'Kỷ niệm',
    ),
  ];

  List<GiftSuggestion> _parent(_Gender g) => [
    GiftSuggestion(
      name: 'Máy đo huyết áp / máy đo đường huyết',
      reason: 'Theo dõi sức khoẻ cho người thân lớn tuổi.',
      budget: '900.000 – 2.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Voucher khám sức khỏe tổng quát',
      reason: 'Quà tặng có giá trị lâu dài cho cha mẹ.',
      budget: '1.500.000 – 5.000.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ thực phẩm chức năng chất lượng',
      reason: 'Bổ sung vitamin theo mùa, theo lứa tuổi.',
      budget: '800.000 – 2.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ ấm trà / ấm pha trà truyền thống',
      reason: 'Thư giãn mỗi sáng, gợi nhớ kỷ niệm gia đình.',
      budget: '600.000 – 2.500.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ chăn lụa / drap cotton cao cấp',
      reason: 'Giấc ngủ ngon hơn cho cha mẹ.',
      budget: '1.500.000 – 4.500.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Ghế ngồi thư giãn / gối massage',
      reason: 'Hỗ trợ thư giãn sau giờ làm việc / đi lại.',
      budget: '1.200.000 – 4.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Điện thoại / máy tính bảng đơn giản cho người lớn',
      reason: 'Dễ sử dụng, phù hợp với nhu cầu liên lạc cơ bản.',
      budget: '1.800.000 – 4.500.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Voucher nghỉ dưỡng resort / spa',
      reason: 'Nạp lại năng lượng, đi cùng gia đình.',
      budget: '3.000.000 – 12.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ album ảnh gia đình in chất lượng cao',
      reason: 'Lưu giữ kỷ niệm gia đình nhiều thế hệ.',
      budget: '400.000 – 1.200.000đ',
      category: 'Kỷ niệm',
    ),
    GiftSuggestion(
      name: 'Bữa cơm gia đình tự chuẩn bị',
      reason: 'Món quà tinh thần — sum họp đầm ấm.',
      budget: '500.000 – 2.000.000đ',
      category: 'Trải nghiệm',
    ),
  ];

  List<GiftSuggestion> _child(_Gender g) => const [
    GiftSuggestion(
      name: 'Bộ đồ chơi xếp hình gỗ an toàn',
      reason: 'Phát triển vận động tinh và nhận biết hình khối.',
      budget: '120.000 – 220.000đ',
      category: 'Đồ chơi',
    ),
    GiftSuggestion(
      name: 'Bộ truyện tranh thiếu nhi Việt Nam',
      reason: 'Khuyến khích thói quen đọc sách từ sớm.',
      budget: '120.000 – 250.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Bộ Lego / đồ chơi lắp ráp đơn giản',
      reason: 'Phát triển tư duy logic và khả năng sáng tạo.',
      budget: '200.000 – 450.000đ',
      category: 'Đồ chơi',
    ),
    GiftSuggestion(
      name: 'Sách vải nhiều hình cho bé',
      reason: 'Kích thích thị giác và làm quen với sách sớm.',
      budget: '90.000 – 180.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Bộ cốc uống nước chống đổ',
      reason: 'Dễ cầm nắm, giúp bé tập uống nước độc lập.',
      budget: '80.000 – 150.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Bộ dụng cụ vẽ nước không độc hại',
      reason: 'Khuyến khích sáng tạo, an toàn khi bé đưa vào miệng.',
      budget: '110.000 – 200.000đ',
      category: 'Sáng tạo',
    ),
    GiftSuggestion(
      name: 'Thú bông mềm an toàn cho bé',
      reason: 'Bạn đồng hành lúc ngủ, dễ giặt sạch.',
      budget: '100.000 – 250.000đ',
      category: 'Đồ chơi',
    ),
    GiftSuggestion(
      name: 'Bộ dụng cụ học sinh (cặp + bút + vở)',
      reason: 'Đồng hành mỗi ngày đến trường.',
      budget: '180.000 – 380.000đ',
      category: 'Học tập',
    ),
    GiftSuggestion(
      name: 'Xe đạp trẻ em có bánh phụ',
      reason: 'Rèn luyện vận động và khả năng giữ thăng bằng.',
      budget: '900.000 – 1.500.000đ',
      category: 'Thể thao',
    ),
    GiftSuggestion(
      name: 'Đồng hồ trẻ em định vị',
      reason: 'Phụ huynh yên tâm hơn khi con đi học.',
      budget: '350.000 – 800.000đ',
      category: 'Công nghệ',
    ),
  ];

  List<GiftSuggestion> _sibling(_Gender g) {
    return const [
      GiftSuggestion(
        name: 'Voucher mua sắm sở thích',
        reason: 'Để người nhận tự chọn theo sở thích cá nhân.',
        budget: '500.000 – 1.500.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Bộ quà kỷ niệm tuổi thơ (ảnh, video)',
        reason: 'Sống lại kỷ niệm anh chị em cùng nhau lớn lên.',
        budget: '150.000 – 600.000đ',
        category: 'Kỷ niệm',
      ),
      GiftSuggestion(
        name: 'Tai nghe chụp hoặc tai nghe bluetooth',
        reason: 'Dùng cho học tập / giải trí hằng ngày.',
        budget: '600.000 – 2.500.000đ',
        category: 'Công nghệ',
      ),
      GiftSuggestion(
        name: 'Sổ tay + bút gel nhiều màu',
        reason: 'Đồ dùng cá nhân hằng ngày.',
        budget: '120.000 – 350.000đ',
        category: 'Phụ kiện',
      ),
      GiftSuggestion(
        name: 'Voucher nhà hàng / quán ăn yêu thích',
        reason: 'Cùng nhau ăn uống, không cần dịp đặc biệt.',
        budget: '300.000 – 1.200.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Balo / túi xách du lịch nhỏ',
        reason: 'Đồng hành các chuyến đi chơi cuối tuần.',
        budget: '400.000 – 1.500.000đ',
        category: 'Thời trang',
      ),
      GiftSuggestion(
        name: 'Bộ board game gia đình',
        reason: 'Cùng nhau chơi những buổi tối quây quần.',
        budget: '300.000 – 900.000đ',
        category: 'Giải trí',
      ),
      GiftSuggestion(
        name: 'Voucher đi xem phim cuối tuần',
        reason: 'Đơn giản nhưng luôn vui.',
        budget: '200.000 – 600.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Bộ sách theo sở thích',
        reason: 'Khuyến khích thói quen đọc, phù hợp sở thích.',
        budget: '150.000 – 700.000đ',
        category: 'Sách',
      ),
      GiftSuggestion(
        name: 'Đồ dùng cá nhân (bình giữ nhiệt, túi đeo)',
        reason: 'Đồ dùng hằng ngày thiết thực.',
        budget: '200.000 – 800.000đ',
        category: 'Đồ dùng',
      ),
    ];
  }

  List<GiftSuggestion> _ageSeeds(_AgeBucket b, _Gender g) {
    switch (b) {
      case _AgeBucket.toddler:
        // Toddlers draw from the child bank directly — the
        // relationship-aware bank ignores "neutral" so we need a
        // safe-toy fallback even when no relationship is set.
        return _child(g);
      case _AgeBucket.child:
        return _child(g);
      case _AgeBucket.teen:
        return _teen(g);
      case _AgeBucket.youngAdult:
        return _youngAdult(g);
      case _AgeBucket.adult:
        return _adult(g);
      case _AgeBucket.middleAge:
        return _middleAge(g);
      case _AgeBucket.elder:
        return _elder(g);
      case _AgeBucket.unknown:
        return _adult(g);
    }
  }

  List<GiftSuggestion> _teen(_Gender g) => const [
    GiftSuggestion(
      name: 'Tai nghe bluetooth chống ồn',
      reason: 'Học tập và giải trí đều tốt hơn.',
      budget: '600.000 – 1.500.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Voucher học ngoại ngữ trực tuyến 3 tháng',
      reason: 'Đầu tư dài hạn cho kỹ năng tương lai.',
      budget: '900.000 – 2.500.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ bút kỹ thuật số + sách tập vẽ',
      reason: 'Phát triển kỹ năng vẽ sáng tạo tại nhà.',
      budget: '350.000 – 800.000đ',
      category: 'Sáng tạo',
    ),
    GiftSuggestion(
      name: 'Bộ skincare mini cho tuổi teen',
      reason: 'Làm quen với việc chăm sóc da an toàn.',
      budget: '200.000 – 500.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Balo thời trang chống nước',
      reason: 'Đựng laptop, sách vở, đi học hằng ngày.',
      budget: '450.000 – 1.100.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Vòng tay / dây chuyền bạc đơn giản',
      reason: 'Phụ kiện cá nhân phù hợp tuổi học trò.',
      budget: '150.000 – 400.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Máy đọc sách / Kindle bản cơ bản',
      reason: 'Đọc sách mọi nơi, bảo vệ mắt.',
      budget: '2.200.000 – 3.500.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Bộ dụng cụ học sinh (cặp + bút + vở)',
      reason: 'Đồng hành mỗi ngày đến trường.',
      budget: '180.000 – 380.000đ',
      category: 'Học tập',
    ),
    GiftSuggestion(
      name: 'Voucher mua sắm thời trang 500k',
      reason: 'Tự chọn đồ theo phong cách cá nhân.',
      budget: '500.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Bộ truyện tranh / light novel',
      reason: 'Khuyến khích đọc sách theo sở thích.',
      budget: '120.000 – 400.000đ',
      category: 'Sách',
    ),
  ];

  List<GiftSuggestion> _youngAdult(_Gender g) => const [
    GiftSuggestion(
      name: 'Tai nghe chụp chống ồn cao cấp',
      reason: 'Đi học, đi làm, giải trí đều cần tập trung.',
      budget: '3.000.000 – 7.000.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Đồng hồ thông minh theo dõi sức khỏe',
      reason: 'Theo dõi giấc ngủ, nhịp tim, vận động.',
      budget: '1.800.000 – 5.500.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Balo laptop công sở chống sốc',
      reason: 'Bảo vệ máy và tài liệu hằng ngày.',
      budget: '900.000 – 2.500.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Bộ đồ pha cà phê tại nhà (phin + cốc)',
      reason: 'Trải nghiệm cà phê Việt Nam kiểu truyền thống.',
      budget: '350.000 – 900.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Voucher spa 90 phút',
      reason: 'Thư giãn sau những ngày làm việc căng thẳng.',
      budget: '800.000 – 2.000.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Sạc dự phòng 20.000mAh',
      reason: 'Yên tâm khi đi du lịch hoặc đi công tác.',
      budget: '450.000 – 950.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Bộ nồi chiên không dầu',
      reason: 'Nấu ăn nhanh, healthy cho người bận rộn.',
      budget: '1.200.000 – 2.500.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Sách đầu tư tài chính cá nhân',
      reason: 'Bước khởi đầu cho tư duy tài chính.',
      budget: '120.000 – 350.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Bộ chăm sóc da cơ bản chống nắng',
      reason: 'Bảo vệ da mỗi ngày khỏi tia UV.',
      budget: '300.000 – 800.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Voucher nhà hàng cuối tuần',
      reason: 'Cùng bạn bè / người thương ăn uống dịp đặc biệt.',
      budget: '500.000 – 1.500.000đ',
      category: 'Trải nghiệm',
    ),
  ];

  List<GiftSuggestion> _adult(_Gender g) => const [
    GiftSuggestion(
      name: 'Bộ trang sức bạc cao cấp',
      reason: 'Món quà có giá trị, dễ đeo hằng ngày.',
      budget: '1.500.000 – 5.000.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Bộ dụng cụ pha cà phê Pour-Over',
      reason: 'Trải nghiệm cà phê specialty tại gia.',
      budget: '900.000 – 3.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Voucher du lịch trải nghiệm 2N1Đ',
      reason: 'Tạo kỷ niệm cùng gia đình / bạn bè.',
      budget: '2.500.000 – 8.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Máy massage cổ vai gáy',
      reason: 'Giảm mỏi sau giờ làm việc dài.',
      budget: '600.000 – 1.800.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Bộ đồ gia dụng nhà bếp thông minh',
      reason: 'Tiết kiệm thời gian nấu nướng mỗi ngày.',
      budget: '1.500.000 – 4.500.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Đồng hồ cơ dây da',
      reason: 'Phụ kiện văn phòng tinh tế.',
      budget: '3.000.000 – 12.000.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Voucher spa cao cấp 4 giờ',
      reason: 'Tận hưởng dịch vụ thư giãn chất lượng cao.',
      budget: '2.500.000 – 5.000.000đ',
      category: 'Chăm sóc cá nhân',
    ),
    GiftSuggestion(
      name: 'Bộ sách hay nên đọc một lần trong đời',
      reason: 'Đầu tư tri thức dài hạn.',
      budget: '250.000 – 700.000đ',
      category: 'Sách',
    ),
    GiftSuggestion(
      name: 'Bộ trang phục công sở cao cấp',
      reason: 'Lịch sự, thoải mái cho môi trường làm việc.',
      budget: '2.000.000 – 6.500.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Bộ dao làm bếp Nhật / Đức',
      reason: 'Hỗ trợ nấu ăn ngon hơn mỗi ngày.',
      budget: '1.500.000 – 4.000.000đ',
      category: 'Đồ dùng',
    ),
  ];

  List<GiftSuggestion> _middleAge(_Gender g) => const [
    GiftSuggestion(
      name: 'Bộ ấm trà gốm Bát Tràng',
      reason: 'Tinh tế, thư giãn mỗi sáng.',
      budget: '1.200.000 – 4.000.000đ',
      category: 'Phụ kiện',
    ),
    GiftSuggestion(
      name: 'Ghế massage thư giãn mini',
      reason: 'Giảm đau mỏi lưng sau giờ làm việc.',
      budget: '3.500.000 – 9.000.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Voucher khám sức khỏe tổng quát',
      reason: 'Theo dõi sức khỏe định kỳ.',
      budget: '2.000.000 – 5.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ trang phục công sở cao cấp',
      reason: 'Lịch sự, thoải mái cho môi trường làm việc.',
      budget: '2.000.000 – 6.500.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Bộ dao làm bếp Nhật / Đức',
      reason: 'Hỗ trợ nấu ăn ngon hơn mỗi ngày.',
      budget: '1.500.000 – 4.000.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Voucher nghỉ dưỡng resort 2N1Đ',
      reason: 'Nạp lại năng lượng cùng gia đình.',
      budget: '4.000.000 – 12.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Đồng hồ thông minh cho người lớn',
      reason: 'Theo dõi nhịp tim, huyết áp cơ bản.',
      budget: '3.500.000 – 8.000.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ thực phẩm chức năng chất lượng',
      reason: 'Bổ sung vitamin theo mùa.',
      budget: '900.000 – 2.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ túi xách công sở da thật',
      reason: 'Sang trọng, gọn gàng cho cả ngày làm việc.',
      budget: '2.500.000 – 7.000.000đ',
      category: 'Thời trang',
    ),
    GiftSuggestion(
      name: 'Voucher nhà hàng fine dining',
      reason: 'Bữa tối đáng nhớ cùng người thương.',
      budget: '1.500.000 – 4.500.000đ',
      category: 'Trải nghiệm',
    ),
  ];

  List<GiftSuggestion> _elder(_Gender g) => const [
    GiftSuggestion(
      name: 'Máy đo huyết áp điện tử tại nhà',
      reason: 'Theo dõi sức khỏe tim mạch hằng ngày.',
      budget: '800.000 – 2.000.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ thảo dược bổ khớp / xương',
      reason: 'Hỗ trợ vận động dẻo dai hơn.',
      budget: '500.000 – 1.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ ấm trà gốm cổ điển',
      reason: 'Thư giãn mỗi ngày với tách trà nóng.',
      budget: '900.000 – 3.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Voucher khám mắt / đo kính',
      reason: 'Chăm sóc thị lực định kỳ.',
      budget: '600.000 – 1.500.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Bộ chăn lụa tơ tằm cao cấp',
      reason: 'Giấc ngủ ngon hơn với chất liệu tự nhiên.',
      budget: '1.800.000 – 4.500.000đ',
      category: 'Đồ dùng',
    ),
    GiftSuggestion(
      name: 'Ghế ngồi tựa massage',
      reason: 'Giảm mỏi khi đọc sách, xem TV.',
      budget: '3.500.000 – 8.000.000đ',
      category: 'Sức khỏe',
    ),
    GiftSuggestion(
      name: 'Voucher điều dưỡng / massage tại spa',
      reason: 'Mỗi tháng một lần thư giãn toàn thân.',
      budget: '800.000 – 2.000.000đ',
      category: 'Trải nghiệm',
    ),
    GiftSuggestion(
      name: 'Sách ký ức / sách gia đình',
      reason: 'Lưu giữ câu chuyện cho thế hệ sau.',
      budget: '150.000 – 350.000đ',
      category: 'Kỷ niệm',
    ),
    GiftSuggestion(
      name: 'Bộ radio + loa cổ điển',
      reason: 'Nghe nhạc vàng, nghe tin tức dễ dàng.',
      budget: '600.000 – 1.500.000đ',
      category: 'Công nghệ',
    ),
    GiftSuggestion(
      name: 'Bộ quần áo mặc nhà cotton cao cấp',
      reason: 'Thoải mái, dễ giặt, phù hợp tuổi.',
      budget: '400.000 – 1.000.000đ',
      category: 'Thời trang',
    ),
  ];

  List<GiftSuggestion> _generic(_Gender g) {
    // Relationship-neutral gifts used as padding when the relationship
    // templates produced fewer than the target.
    return const [
      GiftSuggestion(
        name: 'Voucher mua sắm đa dụng 500.000đ',
        reason: 'Để người nhận tự chọn món đồ phù hợp nhu cầu.',
        budget: '500.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Voucher mua sắm đa dụng 200.000đ',
        reason: 'Mua thêm phụ kiện hoặc đồ dùng nhỏ.',
        budget: '200.000đ',
        category: 'Trải nghiệm',
      ),
      GiftSuggestion(
        name: 'Bưu thiếp viết tay + hoa tươi',
        reason: 'Một lời chúc chân thành luôn đáng nhớ.',
        budget: '150.000 – 350.000đ',
        category: 'Kỷ niệm',
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Personalisation
  // ---------------------------------------------------------------------------

  GiftSuggestion _personalise(
    GiftSuggestion t,
    String name,
    _Relationship rel,
    String ageLabel,
  ) {
    // Always return the template untouched — the personalised effect
    // comes from the relationship + age + name already informing
    // WHICH template bank we draw from. Templates that mention a
    // name in the gift itself are explicitly written with [n] in the
    // reason field.
    if (name.isEmpty) return t;
    final reason = _personaliseReason(t.reason ?? '', name, rel);
    return GiftSuggestion(
      name: t.name,
      reason: reason.isEmpty ? t.reason : reason,
      budget: t.budget,
      category: t.category,
    );
  }

  String _personaliseReason(String reason, String name, _Relationship rel) {
    if (reason.isEmpty) return reason;
    final firstName = _firstName(name);
    if (firstName.isEmpty) return reason;
    // Only inject the name when the relationship is personal (lover,
    // close friend, parent, child, sibling). For neutral / colleague
    // contexts the reason stays impersonal.
    switch (rel) {
      case _Relationship.lover:
      case _Relationship.closeFriend:
      case _Relationship.parent:
      case _Relationship.child:
      case _Relationship.sibling:
        if (reason.contains(firstName)) return reason;
        if (reason.length <= 12) {
          return '$reason dành cho $firstName';
        }
        return 'Dành cho $firstName — $reason';
      case _Relationship.colleague:
      case _Relationship.neutral:
        return reason;
    }
  }

  String _displayName(String? name, String? nickname) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '';
    return n;
  }

  String _firstName(String full) {
    final t = full.trim();
    if (t.isEmpty) return '';
    final idx = t.indexOf(' ');
    return idx <= 0 ? t : t.substring(0, idx);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  _Gender _normaliseGender(String? raw) {
    if (raw == null) return _Gender.unspecified;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return _Gender.unspecified;
    if (s.contains('nữ') ||
        s.contains('female') ||
        s == 'f' ||
        s.contains('girl')) {
      return _Gender.female;
    }
    if (s.contains('nam') ||
        s.contains('male') ||
        s == 'm' ||
        s.contains('boy')) {
      return _Gender.male;
    }
    return _Gender.unspecified;
  }

  _Relationship _normaliseRelationship(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty) return _Relationship.neutral;
    if (s.contains('yêu') ||
        s.contains('lover') ||
        s.contains('vợ') ||
        s.contains('chồng') ||
        s.contains('partner') ||
        s.contains('hôn')) {
      return _Relationship.lover;
    }
    if (s.contains('thân') ||
        s.contains('close friend') ||
        s.contains('bạn') ||
        s.contains('friend')) {
      return _Relationship.closeFriend;
    }
    if (s.contains('đồng nghiệp') ||
        s.contains('colleague') ||
        s.contains('công ty') ||
        s.contains('work')) {
      return _Relationship.colleague;
    }
    if (s.contains('mẹ') ||
        s.contains('má') ||
        s.contains('mom') ||
        s.contains('mother')) {
      return _Relationship.parent;
    }
    if (s.contains('cha') ||
        s.contains('bố') ||
        s.contains('ba') ||
        s.contains('dad') ||
        s.contains('father')) {
      return _Relationship.parent;
    }
    if (s.contains('con')) return _Relationship.child;
    if (s.contains('anh') ||
        s.contains('chị') ||
        s.contains('em') ||
        s.contains('sibling')) {
      return _Relationship.sibling;
    }
    return _Relationship.neutral;
  }

  _AgeBucket _normaliseAgeGroup(int? age) {
    if (age == null) return _AgeBucket.unknown;
    if (age <= 3) return _AgeBucket.toddler;
    if (age <= 12) return _AgeBucket.child;
    if (age <= 18) return _AgeBucket.teen;
    if (age <= 30) return _AgeBucket.youngAdult;
    if (age <= 50) return _AgeBucket.adult;
    if (age <= 65) return _AgeBucket.middleAge;
    return _AgeBucket.elder;
  }
}

enum _Gender { male, female, unspecified }

enum _AgeBucket {
  toddler,
  child,
  teen,
  youngAdult,
  adult,
  middleAge,
  elder,
  unknown,
}

enum _Relationship {
  lover,
  closeFriend,
  colleague,
  parent,
  child,
  sibling,
  neutral,
}
