import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/ai/services/birthday_ai_service.dart';

/// Displays AI availability and a settings link.
class BirthdayAiSection extends StatelessWidget {
  const BirthdayAiSection({super.key, required this.birthdayName});

  final String birthdayName;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Consumer<BirthdayAiService>(
          builder: (ctx, service, _) {
            return FutureBuilder<bool>(
              future: service.isAvailable(),
              builder: (ctx, snap) {
                final available = snap.data ?? false;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFFFF80AB)],
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trợ lý AI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Cá nhân hóa cho $birthdayName',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (available
                                    ? Colors.green
                                    : Colors.amber.shade700)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            available ? 'AI sẵn sàng' : 'Chưa cấu hình',
                            style: TextStyle(
                              color:
                                  available
                                      ? Colors.green.shade700
                                      : Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!available)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Mở cài đặt AI'),
                          onPressed:
                              () => Navigator.pushNamed(ctx, '/settings'),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
