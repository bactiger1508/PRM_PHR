import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DocumentFilterBar extends StatelessWidget {
  final String selectedCategory;
  final String selectedStatus;
  final String selectedTimeFilter;

  final List<String> categories;
  final List<String> statuses;
  final List<String> timeFilters;
  final List<String> availableTags;

  final String selectedTag;

  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTimeFilterChanged;
  final ValueChanged<String> onTagChanged;

  const DocumentFilterBar({
    super.key,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.selectedTimeFilter,
    required this.categories,
    required this.statuses,
    required this.timeFilters,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onTimeFilterChanged,
    required this.availableTags,
    required this.selectedTag,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Category and Status filters row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text('Loại tài liệu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: categories.map((e) => DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                if (e != 'Tất cả') const Icon(Icons.folder_open, size: 16, color: AppColors.textLight),
                                if (e != 'Tất cả') const SizedBox(width: 8),
                                Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) onCategoryChanged(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text('Trạng thái', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: statuses.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e == 'DRAFT' ? 'Bản nháp' : e == 'SAVED' ? 'Đã lưu' : e,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) onStatusChanged(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tag and Time filters row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text('Nhãn tag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTag,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: availableTags.map((e) => DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                const Icon(Icons.tag, size: 16, color: AppColors.textLight),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) onTagChanged(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text('Thời gian', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTimeFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: timeFilters.map((e) => DropdownMenuItem(
                            value: e,
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) onTimeFilterChanged(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
