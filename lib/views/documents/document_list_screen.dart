import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  int _selectedIndex = 1; // "Tài liệu" on bottom nav bar
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Tất cả',
    'Đơn thuốc',
    'Xét nghiệm',
    'Chẩn đoán',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tài liệu Y tế',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            120,
          ), // App bar bottom height to accommodate search & chips
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tài liệu, bác sĩ...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Filter Chips
              SizedBox(
                height: 48,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedFilterIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                      child: ChoiceChip(
                        label: Text(_filters[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilterIndex = index);
                        },
                        showCheckmark: false,
                        backgroundColor: AppColors.backgroundLight,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(color: AppColors.border, height: 1), // bottom border
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: Colors.white,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Tài liệu',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
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

  Widget _buildDocItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> tags,
  }) {
    return InkWell(
      onTap: () {},
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
