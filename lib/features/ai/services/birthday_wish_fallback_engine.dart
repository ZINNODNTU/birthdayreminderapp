import '../domain/ai_provider.dart';
import 'ai_response_parsers.dart';

/// Local, deterministic birthday-wish engine. V3 personalises every
/// wish to the actual person via name / nickname / relationship / age.
/// The output is intentionally Vietnamese and never produces the same
/// "Chúc bạn sinh nhật vui vẻ" template ten times.
class BirthdayWishFallbackEngine {
  const BirthdayWishFallbackEngine();

  /// Produce at least [kWishTargetCount] wishes.
  List<BirthdayWish> wishes({
    String? name,
    String? nickname,
    String? gender,
    int? age,
    String? relationship,
    String? language,
  }) {
    final rel = _relationship(relationship);
    final bucket = _bucket(age);
    final firstName = _firstName(name);
    final callName =
        nickname?.trim().isNotEmpty == true ? nickname!.trim() : firstName;

    // Pull templates from the relationship bank first, then pad with
    // generic Vietnamese templates so we always reach the target.
    final pool = <BirthdayWish>[
      ..._relationshipTemplates(rel, bucket, callName),
      ..._literaryTemplates(callName, rel),
    ];
    final items = <BirthdayWish>[];
    final seen = <String>{};
    for (final w in pool) {
      final key = _normalise(w.text);
      if (seen.add(key)) items.add(w);
      if (items.length >= kWishTargetCount) break;
    }
    for (final w in _genericWishes) {
      final key = _normalise(w.text);
      if (seen.add(key)) {
        items.add(w);
        if (items.length >= kWishTargetCount) break;
      }
    }
    return items.take(kWishTargetCount).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Templates — relationship banks
  // ---------------------------------------------------------------------------

  List<BirthdayWish> _relationshipTemplates(
    _Relationship rel,
    _AgeBucket b,
    String callName,
  ) {
    switch (rel) {
      case _Relationship.lover:
        return _loverTemplates(callName);
      case _Relationship.closeFriend:
        return _closeFriendTemplates(callName);
      case _Relationship.colleague:
        return _colleagueTemplates();
      case _Relationship.parent:
        return _parentTemplates(callName, rel);
      case _Relationship.child:
        return _childTemplates(callName);
      case _Relationship.sibling:
        return _siblingTemplates(callName);
      case _Relationship.neutral:
        return _neutralTemplates(callName);
    }
  }

  List<BirthdayWish> _loverTemplates(String name) => [
    BirthdayWish(
      style: 'Lãng mạn',
      text:
          '$name hợp của mình, chúc em/anh tuổi mới luôn rực rỡ như nụ cười hôm nay.',
    ),
    BirthdayWish(
      style: 'Ngọt ngào',
      text:
          'Cảm ơn $name vì đã làm mỗi ngày của mình đáng yêu hơn. Sinh nhật vui vẻ nha.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Chúc $name một năm mới đầy ắp yêu thương — mình sẽ luôn ở đây, bên em/anh.',
    ),
    BirthdayWish(
      style: 'Lãng mạn',
      text:
          'Mong rằng tuổi mới của $name sẽ mang đến thật nhiều khoảnh khắc đáng nhớ bên nhau.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          '$name ơi, mỗi lần em/anh cười là cả thế giới của mình sáng lên. Chúc mừng sinh nhật.',
    ),
    BirthdayWish(style: 'Ngắn gọn', text: 'Happy birthday $name — mãi yêu.'),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Chúc $name thêm một năm thật rực rỡ và luôn được yêu chiều như em/anh xứng đáng.',
    ),
    BirthdayWish(
      style: 'Lãng mạn',
      text:
          'Cùng $name viết tiếp những trang đẹp nhất — sinh nhật vui vẻ, tình yêu của mình.',
    ),
    BirthdayWish(
      style: 'Ngọt ngào',
      text:
          '$name là món quà đẹp nhất mà cuộc đời này tặng cho mình. Chúc mừng sinh nhật em/anh.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Mong $name luôn hạnh phúc, khỏe mạnh và tràn đầy năng lượng tích cực trong năm mới.',
    ),
  ];

  List<BirthdayWish> _closeFriendTemplates(String name) => [
    BirthdayWish(
      style: 'Thân mật',
      text: 'Happy birthday $name! Lại thêm một tuổi mà mình vẫn chưa già đi.',
    ),
    BirthdayWish(
      style: 'Hài hước',
      text:
          'Chúc $name tuổi mới nhiều tiền hơn năm cũ — vì tiền vẫn quan trọng mà, đúng không?',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          '$name ơi, cảm ơn vì đã luôn là bạn thân từ ngày đó tới giờ. Sinh nhật vui vẻ nha.',
    ),
    BirthdayWish(
      style: 'Vui nhộn',
      text:
          'Chúc $name một năm mới ít drama, nhiều tiền, và đủ meme để cười mỗi ngày.',
    ),
    BirthdayWish(
      style: 'Ngắn gọn',
      text: 'Mừng sinh nhật $name — uống gì đó đi, hôm nay là ngày của bạn.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Mong $name luôn giữ được cái cười đặc trưng đó — bạn bè trân trọng lắm.',
    ),
    BirthdayWish(
      style: 'Hài hước',
      text: '$name thêm một tuổi — nhưng đừng già trước khi mình kịp già nhé!',
    ),
    BirthdayWish(
      style: 'Ngắn gọn',
      text:
          'Chúc $name tuổi mới thật nhiều sức khỏe và thật nhiều trải nghiệm mới.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Cảm ơn $name vì đã là một phần quan trọng của cuộc sống mình. Happy birthday!',
    ),
    BirthdayWish(
      style: 'Vui nhộn',
      text:
          'Sinh nhật $name mà — chúc bạn luôn là chính mình, đừng nghiêm túc quá nhiều!',
    ),
  ];

  List<BirthdayWish> _colleagueTemplates() => const [
    BirthdayWish(
      style: 'Trang trọng',
      text:
          'Kính chúc bạn một tuổi mới thật nhiều sức khỏe, công việc thuận lợi và thành công.',
    ),
    BirthdayWish(
      style: 'Lịch sự',
      text:
          'Chúc bạn sinh nhật vui vẻ — chúc mọi dự án đều thuận buồm xuôi gió.',
    ),
    BirthdayWish(
      style: 'Trang trọng',
      text: 'Trân trọng gửi lời chúc mừng sinh nhật tốt đẹp nhất đến bạn.',
    ),
    BirthdayWish(
      style: 'Lịch sự',
      text:
          'Chúc bạn tuổi mới an khang, thịnh vượng và đạt nhiều mục tiêu nghề nghiệp.',
    ),
    BirthdayWish(
      style: 'Trang trọng',
      text:
          'Kính chúc bạn đón một năm mới tràn đầy năng lượng và cảm hứng làm việc.',
    ),
    BirthdayWish(
      style: 'Lịch sự',
      text:
          'Chúc bạn sinh nhật hạnh phúc — cảm ơn vì luôn là một đồng nghiệp đáng tin cậy.',
    ),
    BirthdayWish(
      style: 'Trang trọng',
      text: 'Chúc bạn một tuổi mới với nhiều thành công và sức khỏe dồi dào.',
    ),
    BirthdayWish(
      style: 'Lịch sự',
      text:
          'Mừng sinh nhật bạn — chúc bạn luôn vững vàng trên con đường sự nghiệp.',
    ),
    BirthdayWish(
      style: 'Trang trọng',
      text:
          'Chúc bạn một sinh nhật đáng nhớ và một năm mới bình an, hạnh phúc.',
    ),
    BirthdayWish(
      style: 'Lịch sự',
      text:
          'Kính chúc bạn tuổi mới đạt được nhiều mục tiêu cá nhân và nghề nghiệp.',
    ),
  ];

  List<BirthdayWish> _parentTemplates(String name, _Relationship rel) {
    final word =
        rel == _Relationship.parent && name.toLowerCase().contains('mẹ')
            ? 'Mẹ'
            : rel == _Relationship.parent
            ? 'Bố'
            : '';
    return [
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Cảm ơn $name đã luôn yêu thương và dạy dỗ mình. Con chúc $name sức khỏe và bình an.'
                : 'Con cảm ơn $word vì đã luôn yêu thương và dạy dỗ con. Chúc $word sức khỏe và bình an.',
      ),
      BirthdayWish(
        style: 'Yêu thương',
        text:
            word.isEmpty
                ? 'Chúc $name sinh nhật vui vẻ — con luôn tự hào về $name.'
                : 'Chúc $word sinh nhật vui vẻ — con luôn tự hào về $word.',
      ),
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Mong $name luôn khỏe mạnh, hạnh phúc và sống vui mỗi ngày.'
                : 'Mong $word luôn khỏe mạnh, hạnh phúc và sống vui mỗi ngày.',
      ),
      BirthdayWish(
        style: 'Yêu thương',
        text:
            word.isEmpty
                ? 'Cảm ơn $name vì đã cho con một tuổi thơ đầy yêu thương.'
                : 'Cảm ơn $word vì đã cho con một tuổi thơ đầy yêu thương.',
      ),
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Chúc $name thêm một năm thật nhiều sức khỏe và niềm vui bên gia đình.'
                : 'Chúc $word thêm một năm thật nhiều sức khỏe và niềm vui bên gia đình.',
      ),
      BirthdayWish(
        style: 'Yêu thương',
        text:
            word.isEmpty
                ? 'Con chúc $name sinh nhật thật ấm áp và ý nghĩa.'
                : 'Con chúc $word sinh nhật thật ấm áp và ý nghĩa.',
      ),
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Mong mỗi ngày của $name đều an lành và đầy tiếng cười.'
                : 'Mong mỗi ngày của $word đều an lành và đầy tiếng cười.',
      ),
      BirthdayWish(
        style: 'Yêu thương',
        text:
            word.isEmpty
                ? 'Con luôn nhớ những bữa cơm gia đình — cảm ơn $name vì điều đó.'
                : 'Con luôn nhớ những bữa cơm gia đình — cảm ơn $word vì điều đó.',
      ),
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Chúc $name sống lâu, sống khỏe, sống vui cùng con cháu.'
                : 'Chúc $word sống lâu, sống khỏe, sống vui cùng con cháu.',
      ),
      BirthdayWish(
        style: 'Trân trọng',
        text:
            word.isEmpty
                ? 'Sinh nhật $name — con yêu $name rất nhiều.'
                : 'Sinh nhật $word — con yêu $word rất nhiều.',
      ),
    ];
  }

  List<BirthdayWish> _childTemplates(String name) => [
    BirthdayWish(
      style: 'Trẻ thơ',
      text:
          'Chúc $name tuổi mới ngoan ngoãn, ăn nhiều, ngủ ngoan, học giỏi nha!',
    ),
    BirthdayWish(
      style: 'Trẻ thơ',
      text: 'Happy birthday $name — cả nhà yêu thương $name lắm!',
    ),
    BirthdayWish(
      style: 'Dễ thương',
      text: 'Chúc $name mau lớn, vui vẻ và luôn khỏe mạnh nha.',
    ),
    BirthdayWish(
      style: 'Trẻ thơ',
      text:
          'Sinh nhật $name đến rồi — chúc $name thật nhiều quà và thật nhiều bánh kem!',
    ),
    BirthdayWish(
      style: 'Dễ thương',
      text: 'Chúc $name năm nay học tốt, vui chơi nhiều và luôn cười tươi nhé.',
    ),
    BirthdayWish(
      style: 'Trẻ thơ',
      text: '$name là đứa trẻ đáng yêu nhất — chúc mừng sinh nhật nha!',
    ),
    BirthdayWish(
      style: 'Dễ thương',
      text: 'Chúc $name luôn vui vẻ, mạnh khỏe và hạnh phúc bên gia đình.',
    ),
    BirthdayWish(
      style: 'Trẻ thơ',
      text: 'Mừng sinh nhật $name — cả nhà chúc $name thật nhiều điều tốt đẹp.',
    ),
    BirthdayWish(
      style: 'Dễ thương',
      text: 'Chúc $name mỗi ngày đều là ngày vui — yêu $name nhiều.',
    ),
    BirthdayWish(
      style: 'Trẻ thơ',
      text: 'Tuổi mới của $name rực rỡ và đầy màu sắc — cố lên nha!',
    ),
  ];

  List<BirthdayWish> _siblingTemplates(String name) => [
    BirthdayWish(
      style: 'Thân mật',
      text:
          'Happy birthday $name — mãi là người anh/chị/em tốt nhất của mình nha.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text:
          'Cảm ơn $name vì đã luôn ở đây — sinh nhật vui vẻ, người anh/chị/em yêu quý.',
    ),
    BirthdayWish(
      style: 'Hài hước',
      text: 'Chúc $name thêm một tuổi — nhưng nhớ đừng già trước mình nhé!',
    ),
    BirthdayWish(
      style: 'Trân trọng',
      text:
          'Mong $name luôn khỏe mạnh, hạnh phúc và đạt được những điều mình mong muốn.',
    ),
    BirthdayWish(
      style: 'Thân mật',
      text: 'Cùng $name đi ăn gì đó ngon đi — hôm nay là ngày của $name mà!',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text: 'Tự hào về $name — chúc mừng sinh nhật.',
    ),
    BirthdayWish(
      style: 'Vui nhộn',
      text:
          'Chúc $name tuổi mới nhiều tiền, ít phiền, và đủ sức khỏe để đi chơi với mình.',
    ),
    BirthdayWish(
      style: 'Trân trọng',
      text: 'Chúc $name một năm mới an khang, thịnh vượng và bình an.',
    ),
    BirthdayWish(
      style: 'Thân mật',
      text: 'Mừng sinh nhật $name — hãy luôn là chính mình nha.',
    ),
    BirthdayWish(
      style: 'Tình cảm',
      text: 'Cảm ơn $name vì đã cùng mình lớn lên — happy birthday!',
    ),
  ];

  List<BirthdayWish> _neutralTemplates(String name) {
    if (name.isEmpty) {
      return const [
        BirthdayWish(style: 'Ngắn gọn', text: 'Chúc mừng sinh nhật!'),
        BirthdayWish(style: 'Ngắn gọn', text: 'Tuổi mới thật nhiều niềm vui!'),
        BirthdayWish(
          style: 'Tình cảm',
          text: 'Mong mọi điều tốt đẹp nhất sẽ đến với bạn trong năm mới.',
        ),
        BirthdayWish(
          style: 'Trang trọng',
          text: 'Chúc bạn một sinh nhật hạnh phúc và một năm mới bình an.',
        ),
        BirthdayWish(
          style: 'Ngắn gọn',
          text: 'Một năm mới tràn đầy năng lượng tích cực!',
        ),
      ];
    }
    return [
      BirthdayWish(style: 'Ngắn gọn', text: 'Chúc mừng sinh nhật $name!'),
      BirthdayWish(
        style: 'Ngắn gọn',
        text: 'Tuổi mới thật nhiều niềm vui, $name nhé!',
      ),
      BirthdayWish(
        style: 'Tình cảm',
        text: 'Mong mọi điều tốt đẹp nhất sẽ đến với $name trong năm mới.',
      ),
      BirthdayWish(
        style: 'Trang trọng',
        text: 'Chúc $name một sinh nhật hạnh phúc và một năm mới bình an.',
      ),
      BirthdayWish(
        style: 'Ngắn gọn',
        text: 'Một năm mới tràn đầy năng lượng tích cực, $name nhé!',
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Templates — literary / generic
  // ---------------------------------------------------------------------------

  List<BirthdayWish> _literaryTemplates(String name, _Relationship rel) {
    return [
      BirthdayWish(
        style: 'Văn chương',
        text:
            'Năm tháng trôi qua, chúc ${name.isEmpty ? "bạn" : name} giữ trọn nụ cười và ánh sáng trong mắt.',
      ),
      BirthdayWish(
        style: 'Văn chương',
        text:
            name.isEmpty
                ? 'Mừng ngày bạn chào đời — mong hành trình phía trước luôn dịu dàng và đáng yêu.'
                : 'Mừng ngày $name chào đời — mong hành trình phía trước luôn dịu dàng và đáng yêu.',
      ),
      BirthdayWish(
        style: 'Văn chương',
        text:
            name.isEmpty
                ? 'Chúc bạn thêm một mùa xuân trong đời, nhẹ nhàng mà thật rực rỡ.'
                : 'Chúc $name thêm một mùa xuân trong đời, nhẹ nhàng mà thật rực rỡ.',
      ),
      BirthdayWish(
        style: 'Câu chúc',
        text:
            name.isEmpty
                ? 'Sinh nhật vui vẻ — hôm nay là ngày của bạn.'
                : 'Sinh nhật vui vẻ $name — hôm nay là ngày của bạn.',
      ),
      BirthdayWish(
        style: 'Yêu thương',
        text:
            name.isEmpty
                ? 'Chúc bạn luôn được yêu thương và trân trọng.'
                : 'Chúc $name luôn được yêu thương và trân trọng.',
      ),
    ];
  }

  List<BirthdayWish> get _genericWishes => const [
    BirthdayWish(
      style: 'Câu chúc',
      text: 'Chúc mừng sinh nhật! Mong mọi điều tuyệt vời nhất sẽ đến với bạn.',
    ),
    BirthdayWish(
      style: 'Câu chúc',
      text: 'Sinh nhật vui vẻ — hôm nay là ngày của bạn.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  _Relationship _relationship(String? raw) {
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
    if (s.contains('mẹ') || s.contains('má') || s.contains('mom')) {
      return _Relationship.parent;
    }
    if (s.contains('cha') ||
        s.contains('bố') ||
        s.contains('ba') ||
        s.contains('dad')) {
      return _Relationship.parent;
    }
    if (s.contains('con')) return _Relationship.child;
    if (s.contains('thân') || s.contains('bạn') || s.contains('friend')) {
      return _Relationship.closeFriend;
    }
    if (s.contains('anh') ||
        s.contains('chị') ||
        s.contains('em') ||
        s.contains('sibling')) {
      return _Relationship.sibling;
    }
    if (s.contains('đồng nghiệp') ||
        s.contains('colleague') ||
        s.contains('công ty')) {
      return _Relationship.colleague;
    }
    return _Relationship.neutral;
  }

  String _firstName(String? name) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return '';
    final idx = t.indexOf(' ');
    return idx <= 0 ? t : t.substring(0, idx);
  }

  _AgeBucket _bucket(int? age) {
    if (age == null) return _AgeBucket.unknown;
    if (age <= 3) return _AgeBucket.toddler;
    if (age <= 12) return _AgeBucket.child;
    if (age <= 18) return _AgeBucket.teen;
    if (age <= 30) return _AgeBucket.youngAdult;
    if (age <= 50) return _AgeBucket.adult;
    if (age <= 65) return _AgeBucket.middleAge;
    return _AgeBucket.elder;
  }

  String _normalise(String s) {
    final lower = s.toLowerCase();
    final stripped = lower.replaceAll(RegExp(r'[\s​-‍]+'), ' ').trim();
    return stripped;
  }
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
