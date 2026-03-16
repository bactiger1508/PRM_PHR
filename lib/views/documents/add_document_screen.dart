import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  int _selectedIndex = 1; // "Tài liệu" on bottom nav bar
  int _docTypeIndex = 0; // 0: Xét nghiệm, 1: Đơn thuốc, 2: Chẩn đoán

  final List<String> _docTypes = ['Xét nghiệm', 'Đơn thuốc', 'Chẩn đoán'];

  // Tag management
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _showTagSuggestions = false;

  // Status tracking

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            // Auto-save as draft when pressing X
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tài liệu đã được lưu dưới dạng bản nháp'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Thêm Tài liệu Y tế',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài liệu đã được lưu thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document Type
            const Text(
              'LOẠI TÀI LIỆU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: _docTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final text = entry.value;
                  final isSelected = _docTypeIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _docTypeIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Options
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.camera_alt,
                    label: 'Chụp ảnh',
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.image,
                    label: 'Từ thư viện',
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upload Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ket-qua-xet-nghiem.jpg',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '45%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.45,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Form
            _buildInputLabel('Tiêu đề tài liệu'),
            const SizedBox(height: 6),
            _buildTextField(
              hintText: 'Ví dụ: Xét nghiệm máu tổng quát',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            _buildInputLabel('Ngày khám'),
            const SizedBox(height: 6),
            TextField(
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'dd/mm/yyyy',
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 16),

            _buildInputLabel('Nhãn (Tags)'),
            const SizedBox(height: 8),
            // Autocomplete tag input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _tagController,
                        onChanged: (value) {
                          setState(() {
                            _showTagSuggestions = value.isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Nhập để tìm hoặc thêm nhãn...',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                          prefixIcon: const Icon(Icons.label_outline, color: AppColors.textLight),
                          suffixIcon: _tagController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                  onPressed: () {
                                    final newTag = _tagController.text.trim();
                                    if (newTag.isNotEmpty && !_selectedTags.contains(newTag)) {
                                      setState(() {
                                        _selectedTags.add(newTag);
                                        if (!_availableTags.contains(newTag)) {
                                          _availableTags.add(newTag);
                                        }
                                        _tagController.clear();
                                        _showTagSuggestions = false;
                                      });
                                    }
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      if (_showTagSuggestions) ...[
                        const Divider(height: 1, color: AppColors.border),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: _availableTags
                                .where((tag) =>
                                    tag.toLowerCase().contains(_tagController.text.toLowerCase()) &&
                                    !_selectedTags.contains(tag))
                                .map((tag) => ListTile(
                                      dense: true,
                                      title: Text(tag, style: const TextStyle(fontSize: 14)),
                                      leading: const Icon(Icons.label, size: 18, color: AppColors.primary),
                                      onTap: () {
                                        setState(() {
                                          _selectedTags.add(tag);
                                          _tagController.clear();
                                          _showTagSuggestions = false;
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                        backgroundColor: Colors.blue[100],
                        deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue[600]),
                        onDeleted: () {
                          setState(() => _selectedTags.remove(tag));
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _buildInputLabel('Ghi chú'),
            const SizedBox(height: 6),
            const TextField(
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú thêm về tài liệu này...',
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Nhắc nhở',
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

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.5),
          style: BorderStyle.solid,
          width: 2,
        ),
        boxShadow: !isPrimary ? AppTheme.softShadow : [],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary : AppColors.backgroundLight,
              shape: BoxShape.circle,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hintText,
      ),
    );
  }
}
