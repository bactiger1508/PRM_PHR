import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/document_category_horizontal_bar.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/medical_document_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

import '../../domain/entities/medical_document_entity.dart';

class UpdateDocumentScreen extends StatefulWidget {
  final MedicalDocumentEntity document;

  const UpdateDocumentScreen({super.key, required this.document});

  @override
  State<UpdateDocumentScreen> createState() => _UpdateDocumentScreenState();
}

class _UpdateDocumentScreenState extends State<UpdateDocumentScreen> {
  final MedicalDocumentViewModel _viewModel = MedicalDocumentViewModel();

  final _titleController = TextEditingController();
  final _examDateController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _customCategoryController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    
    // Initialize properties with existing document data
    _titleController.text = widget.document.title ?? '';
    if (widget.document.notes != null) {
      _notesController.text = widget.document.notes!;
    }
    if (widget.document.recordDate != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.document.recordDate!);
    }
    
    // Set category index based on categoryId (1-indexed)
    if (widget.document.categoryId > 0) {
      _viewModel.setCategoryById(widget.document.categoryId);
    }
    
    // Initialize tags
    for (var tag in widget.document.tags) {
      _viewModel.addTag(tag);
    }

    // Initialize files if they exist
    if (widget.document.files.isNotEmpty) {
      final paths = widget.document.files.map((f) => f.filePath).toList();
      _viewModel.initWithFiles(paths);
    }

    _viewModel.loadPatients();
    _viewModel.loadCategories();
    _viewModel.loadTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _examDateController.dispose();
    _notesController.dispose();
    _tagInputController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Chọn ngày khám',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _examDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _updateDocument() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề tài liệu.', isError: true);
      return;
    }

    final staffId = AuthViewModel.instance.currentUser?.id ?? 0;
    String? customCategory;
    if (_viewModel.categoryNames.isNotEmpty && 
        _viewModel.selectedCategoryIndex < _viewModel.categoryNames.length && 
        _viewModel.categoryNames[_viewModel.selectedCategoryIndex] == 'Khác') {
      customCategory = _customCategoryController.text.trim();
      if (customCategory.isEmpty) {
        _showSnackBar('Vui lòng nhập tên loại tài liệu mới.', isError: true);
        return;
      }
    }

    final success = await _viewModel.updateDocument(
      docId: widget.document.id!,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      recordDate: _selectedDate?.millisecondsSinceEpoch,
      performedByUserId: staffId,
      customCategoryName: customCategory,
    );

    if (success) {
      if (!mounted) return;
      _showSnackBar('Cập nhật tài liệu thành công!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      _showSnackBar(
        _viewModel.errorMsg ?? 'Có lỗi xảy ra khi cập nhật tài liệu.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _showTagDropdown = false;

  void _onTagInputChanged(String value) {
    setState(() {
      _showTagDropdown = value.trim().isNotEmpty;
    });
  }

  void _selectTag(String tag) {
    setState(() {
      _viewModel.addTag(tag);
      _tagInputController.clear();
      _showTagDropdown = false;
    });
  }

  void _addCustomTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty) {
      setState(() {
        _viewModel.addTag(tag);
        _tagInputController.clear();
        _showTagDropdown = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cập nhật Tài liệu',
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
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return ElevatedButton(
                    onPressed: _viewModel.isSaving ? null : _updateDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                    ),
                    child: _viewModel.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Không hiển thị Patient Selector khi Cập nhật
                const SizedBox(height: 8),

                // ========== LOẠI TÀI LIỆU ==========
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
                _buildDocTypeSelector(),
                if (_viewModel.categoryNames.isNotEmpty && 
                    _viewModel.selectedCategoryIndex < _viewModel.categoryNames.length && 
                    _viewModel.categoryNames[_viewModel.selectedCategoryIndex] == 'Khác') ...[
                  const SizedBox(height: 12),
                  _buildInputLabel('Nhập tên loại tài liệu mới'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _customCategoryController,
                    hintText: 'Ví dụ: Giấy chuyển viện',
                  ),
                ],
                const SizedBox(height: 24),

                // ========== Upload Options ==========
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadOption(
                        icon: Icons.camera_alt,
                        label: 'Chụp ảnh',
                        isPrimary: true,
                        onTap: () => _viewModel.pickFromCamera(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildUploadOption(
                        icon: Icons.image,
                        label: 'Từ thư viện',
                        isPrimary: false,
                        onTap: () => _viewModel.pickFromGallery(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ========== File previews ==========
                ..._buildFileList(),

                const SizedBox(height: 8),

                // ========== Tiêu đề tài liệu ==========
                _buildInputLabel('Tiêu đề tài liệu'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _titleController,
                  hintText: 'Ví dụ: Xét nghiệm máu tổng quát',
                ),
                const SizedBox(height: 16),

                // ========== Ngày khám ==========
                _buildInputLabel('Ngày khám'),
                const SizedBox(height: 6),
                _buildDateField(),
                const SizedBox(height: 16),

                // ========== Nhãn (Tags) ==========
                _buildInputLabel('Nhãn (Tags)'),
                const SizedBox(height: 8),
                _buildTagsSection(),
                const SizedBox(height: 16),

                // ========== Ghi chú ==========
                _buildInputLabel('Ghi chú'),
                const SizedBox(height: 6),
                _buildTextArea(
                  controller: _notesController,
                  hintText: 'Nhập ghi chú thêm về tài liệu này...',
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============ UI Builder Widgets ============

  Widget _buildDocTypeSelector() {
    if (_viewModel.categoryNames.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return DocumentCategoryHorizontalBar(
      categoryNames: _viewModel.categoryNames,
      selectedName: _viewModel.selectedCategoryName,
      onCategorySelected: _viewModel.selectCategoryByName,
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isPrimary ? AppColors.primary : AppColors.backgroundLight,
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
                color:
                    isPrimary ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFileList() {
    final files = _viewModel.selectedFiles;
    if (files.isEmpty) return [];

    return files.asMap().entries.map((entry) {
      final index = entry.key;
      final file = entry.value;
      final fileName = file.path.split(Platform.pathSeparator).last;
      final progress = _viewModel.uploadProgress[fileName] ?? 1.0;
      final isDone = progress >= 1.0;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Icons.description,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 18)
                else
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _viewModel.removeFile(index),
                  child: const Icon(Icons.close,
                      color: AppColors.textLight, size: 18),
                ),
              ],
            ),
            if (!isDone) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.backgroundLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTagsSection() {
    final colors = [
      [Colors.blue[50]!, Colors.blue[600]!],
      [Colors.purple[50]!, Colors.purple[600]!],
      [Colors.teal[50]!, Colors.teal[600]!],
      [Colors.orange[50]!, Colors.orange[700]!],
      [Colors.pink[50]!, Colors.pink[600]!],
    ];

    // Filter available tags: prefix match (startsWith) and not already selected
    final query = _tagInputController.text.trim().toLowerCase();
    final filteredSuggestions = _viewModel.availableTags
        .where((t) =>
            t.toLowerCase().startsWith(query) &&
            !_viewModel.selectedTags.contains(t))
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags as chips
        if (_viewModel.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _viewModel.selectedTags.asMap().entries.map((entry) {
              final tag = entry.value;
              final colorPair = colors[entry.key % colors.length];
              return Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorPair[1],
                  ),
                ),
                backgroundColor: colorPair[0],
                deleteIcon: Icon(Icons.close, size: 14, color: colorPair[1]),
                onDeleted: () => setState(() => _viewModel.removeTag(tag)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Autocomplete input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showTagDropdown ? AppColors.primary : AppColors.border,
              width: _showTagDropdown ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _tagInputController,
                onChanged: _onTagInputChanged,
                onSubmitted: (_) => _addCustomTag(),
                decoration: InputDecoration(
                  hintText: 'Gõ để tìm hoặc tạo nhãn mới...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                  prefixIcon: const Icon(
                    Icons.label_outline,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  suffixIcon: _tagInputController.text.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.primary,
                          ),
                          onPressed: _addCustomTag,
                          tooltip: 'Thêm nhãn mới',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              // Dropdown suggestions
              if (_showTagDropdown && filteredSuggestions.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredSuggestions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final tag = filteredSuggestions[index];
                      // Highlight starting portion
                      final lowerTag = tag.toLowerCase();
                      final isMatch = lowerTag.startsWith(query);
                      return InkWell(
                        onTap: () => _selectTag(tag),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.label,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: isMatch
                                    ? RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: tag.substring(
                                                  0, query.length),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            TextSpan(
                                                text: tag.substring(
                                                    query.length)),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        tag,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                              ),
                              const Icon(
                                Icons.add,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // No suggestions hint
              if (_showTagDropdown &&
                  filteredSuggestions.isEmpty &&
                  _tagInputController.text.trim().isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Tạo nhãn "${_tagInputController.text.trim()}"',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Quick-pick suggestions (show 5 tags when not typing)
        if (!_showTagDropdown) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _viewModel.availableTags
                .where((t) => !_viewModel.selectedTags.contains(t))
                .take(5)
                .map((tag) => GestureDetector(
                      onTap: () => _selectTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
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
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: TextField(
          controller: _examDateController,
          decoration: InputDecoration(
            hintText: 'mm/dd/yyyy',
            hintStyle:
                const TextStyle(fontSize: 14, color: AppColors.textLight),
            suffixIcon: const Icon(Icons.calendar_today,
                color: AppColors.textLight, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

}
