import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlights,
  });
  final IconData icon;
  final String title;
  final String description;
  final List<String> highlights;

  static const pages = [
    OnboardingPageData(
      icon: Icons.cake_outlined,
      title: 'Chào mừng đến Birthday Reminder',
      description: 'Lưu những ngày sinh nhật quan trọng và nhận nhắc nhở để bạn không bỏ lỡ những khoảnh khắc ý nghĩa.',
      highlights: ['Sinh nhật', 'Nhắc nhở', 'Lịch', 'Sao lưu'],
    ),
    OnboardingPageData(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Thêm sinh nhật thật nhanh',
      description: 'Lưu tên, ngày sinh, biệt danh, mối quan hệ, ghi chú và ảnh của những người bạn quan tâm. Hỗ trợ Dương lịch và Âm lịch.',
      highlights: ['Tên', 'Ngày sinh', 'Ảnh', 'Mối quan hệ'],
    ),
    OnboardingPageData(
      icon: Icons.notifications_active_outlined,
      title: 'Không bỏ lỡ ngày quan trọng',
      description: 'Bật thông báo, chọn số ngày nhắc trước và thời gian nhận nhắc phù hợp với bạn.',
      highlights: [
        'Thông báo',
        'Nhắc trước',
        'Thời gian nhắc',
        'Lặp lại hằng năm',
      ],
    ),
    OnboardingPageData(
      icon: Icons.auto_awesome_outlined,
      title: 'Chuẩn bị lời chúc thật ý nghĩa',
      description: 'Xem sinh nhật trên lịch và sử dụng gợi ý thông minh để chuẩn bị quà hoặc lời chúc phù hợp cho từng người.',
      highlights: [
        'Lịch sinh nhật',
        'Gợi ý quà',
        'Gợi ý lời chúc',
        'Cá nhân hóa',
      ],
    ),
    OnboardingPageData(
      icon: Icons.inventory_2_outlined,
      title: 'Dữ liệu của bạn luôn có phương án dự phòng',
      description: 'Sao lưu toàn bộ dữ liệu thành file ZIP để lưu giữ an toàn và khôi phục khi cần.',
      highlights: ['Sinh nhật', 'Ảnh', 'Ghi chú', 'Cấu hình nhắc'],
    ),
  ];
}
