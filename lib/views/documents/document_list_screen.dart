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
  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedTimeFilter = 'Tất cả';

  final List<String> _categories = ['Tất cả', 'Xét nghiệm', 'Đơn thuốc', 'Chẩn đoán hình ảnh', 'Đơn Khám Bệnh', 'Khác'];
  final List<String> _statuses = ['Tất cả', 'DRAFT', 'SAVED'];
  final List<String> _timeFilters = ['Tất cả', '7 ngày qua', '30 ngày qua', '3 tháng qua', '6 tháng qua', '1 năm qua'];

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Category and Status filters row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            items: _categories.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            items: _statuses.map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e == 'DRAFT' ? 'Bản nháp' : e == 'SAVED' ? 'Đã lưu' : e,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Time filter row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimeFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      items: _timeFilters.map((e) => DropdownMenuItem(
                        value: e,
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text(e),
                          ],
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedTimeFilter = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // "Created by me" indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Hiển thị tài liệu do bạn tạo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                  status: 'SAVED',
                  tags: [
                    {
                      'name': 'Nội khoa',
                      'color': Colors.blue[50],
                      'textColor': Colors.blue[600],
                    },
                    {
                      'name': 'Đã lưu',
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
                  status: 'SAVED',
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
                  icon: Icons.masks,
                  iconBgColor: Colors.orange[50]!,
                  iconColor: Colors.orange[600]!,
                  title: 'Kết quả Chụp X-Quang phổi',
                  subtitle: '22 thg 09, 2023 • Trung tâm CDHA',
                  status: 'DRAFT',
                  tags: [
                    {
                      'name': 'Chẩn đoán hình ảnh',
                      'color': Colors.orange[50],
                      'textColor': Colors.orange[600],
                    },
                    {
                      'name': 'Bản nháp',
                      'color': Colors.amber[50],
                      'textColor': Colors.amber[800],
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
                  status: 'SAVED',
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
    String status = 'SAVED',
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
