import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Thanh chọn loại tài liệu cuộn ngang; **"Khác"** luôn nằm cuối danh sách hiển thị.
class DocumentCategoryHorizontalBar extends StatelessWidget {
  final List<String> categoryNames;
  final String? selectedName;
  final ValueChanged<String> onCategorySelected;

  const DocumentCategoryHorizontalBar({
    super.key,
    required this.categoryNames,
    required this.selectedName,
    required this.onCategorySelected,
  });

  /// Đưa mục "Khác" về cuối (các tên khác giữ thứ tự gốc).
  static List<String> orderedForDisplay(List<String> names) {
    final rest = names.where((n) => n != 'Khác').toList();
    if (names.contains('Khác')) {
      rest.add('Khác');
    }
    return rest;
  }

  @override
  Widget build(BuildContext context) {
    final ordered = orderedForDisplay(categoryNames);
    if (ordered.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: ordered.length,
          separatorBuilder: (context, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final text = ordered[index];
            final isSelected = selectedName == text;
            return GestureDetector(
              onTap: () => onCategorySelected(text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minWidth: 92, maxWidth: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
