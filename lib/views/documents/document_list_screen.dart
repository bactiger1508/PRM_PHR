import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'document_detail_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final bool embedded;

  const DocumentListScreen({super.key, this.embedded = false});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Section: 10/2023
          _buildMonthHeader('Tháng 10, 2023'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildDocItem(
                  context,
                  icon: Icons.medication,
                  iconBgColor: Colors.blue[50]!,
                  iconColor: Colors.blue[600]!,
                  title: 'Đơn thuốc viêm họng cấp',
                  subtitle: '15 thg 10, 2023 • BS. Nguyễn Văn A',
                  tags: [
                    {
                      'name': 'Nội khoa',
                      'color': Colors.blue[50],
                      'textColor': Colors.blue[600],
                    },
                    {
                      'name': 'Hoàn thành',
                      'color': Colors.green[50],
                      'textColor': Colors.green[600],
                    },
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildDocItem(
                  context,
                  icon: Icons.science,
                  iconBgColor: Colors.purple[50]!,
                  iconColor: Colors.purple[600]!,
                  title: 'Xét nghiệm máu tổng quát',
                  subtitle: '10 thg 10, 2023 • BV Đa khoa Tâm Anh',
                  tags: [
                    {
                      'name': 'Xét nghiệm',
                      'color': Colors.purple[50],
                      'textColor': Colors.purple[600],
                    },
                  ],
                ),
              ],
            ),
          ),

          // Month Section: 09/2023
          _buildMonthHeader('Tháng 09, 2023'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildDocItem(
                  context,
                  icon: Icons.masks, // Radiology sort of
                  iconBgColor: Colors.orange[50]!,
                  iconColor: Colors.orange[600]!,
                  title: 'Kết quả Chụp X-Quang phổi',
                  subtitle: '22 thg 09, 2023 • Trung tâm CDHA',
                  tags: [
                    {
                      'name': 'Chẩn đoán hình ảnh',
                      'color': Colors.orange[50],
                      'textColor': Colors.orange[600],
                    },
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                _buildDocItem(
                  context,
                  icon: Icons.description,
                  iconBgColor: Colors.red[50]!,
                  iconColor: Colors.red[600]!,
                  title: 'Giấy ra viện',
                  subtitle: '05 thg 09, 2023 • Khoa Nội tiết',
                  tags: [
                    {
                      'name': 'Hành chính',
                      'color': Colors.red[50],
                      'textColor': Colors.red[600],
                    },
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
        title: const Text(
          'Tài liệu Y tế',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
      // Luôn ẩn menu bên dưới cho màn hình này
      bottomNavigationBar: null,
    );
  }

  Widget _buildMonthHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDocItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> tags,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DocumentDetailScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: t['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t['name'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: t['textColor'],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
