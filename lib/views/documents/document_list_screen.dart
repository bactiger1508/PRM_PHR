import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'document_detail_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/medical_document_viewmodel.dart';
import '../../domain/entities/medical_document_entity.dart';
import 'widgets/document_filter_bar.dart';
import 'trash_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final bool embedded;

  const DocumentListScreen({super.key, this.embedded = false});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final MedicalDocumentViewModel _viewModel = MedicalDocumentViewModel();

  String _selectedCategory = 'Tất cả';
  String _selectedStatus = 'Tất cả';
  String _selectedTimeFilter = 'Tất cả';
  String _selectedTag = 'Tất cả';

  final List<String> _statuses = ['Tất cả', 'DRAFT', 'SAVED'];
  final List<String> _timeFilters = ['Tất cả', '7 ngày qua', '30 ngày qua', '3 tháng qua', '6 tháng qua', '1 năm qua'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    await _viewModel.loadCategories();
    await _viewModel.loadTags();
    await _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final staffId = AuthViewModel.instance.currentUser?.id;
    if (staffId != null) {
      await _viewModel.loadDocumentsByCreator(staffId);
    }
  }

  List<MedicalDocumentEntity> _getFilteredDocuments() {
    final docs = _viewModel.documents;
    return docs.where((doc) {
      // Filter by Category
      if (_selectedCategory != 'Tất cả' && doc.categoryName != _selectedCategory) {
        return false;
      }
      // Filter by Status
      if (_selectedStatus == 'Tất cả') {
        if (doc.status == 'DELETED') return false;
      } else {
        if (doc.status != _selectedStatus) return false;
      }
      // Filter by Tag
      if (_selectedTag != 'Tất cả' && !doc.tags.contains(_selectedTag)) {
        return false;
      }
      // Filter by Time
      if (_selectedTimeFilter != 'Tất cả') {
        if (doc.recordDate == null) return false;
        final docDate = DateTime.fromMillisecondsSinceEpoch(doc.recordDate!);
        final now = DateTime.now();
        final difference = now.difference(docDate).inDays;

        switch (_selectedTimeFilter) {
          case '7 ngày qua':
            if (difference > 7) return false;
            break;
          case '30 ngày qua':
            if (difference > 30) return false;
            break;
          case '3 tháng qua':
            if (difference > 90) return false;
            break;
          case '6 tháng qua':
            if (difference > 180) return false;
            break;
          case '1 năm qua':
            if (difference > 365) return false;
            break;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<MedicalDocumentEntity>> _groupDocumentsByMonth(List<MedicalDocumentEntity> docs) {
    final Map<String, List<MedicalDocumentEntity>> grouped = {};
    for (var doc in docs) {
      final date = doc.recordDate != null 
          ? DateTime.fromMillisecondsSinceEpoch(doc.recordDate!)
          : DateTime.now();
      final monthStr = DateFormat('\'Tháng\' MM, yyyy').format(date);
      if (!grouped.containsKey(monthStr)) {
        grouped[monthStr] = [];
      }
      grouped[monthStr]!.add(doc);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _getFilteredDocuments();
    final groupedDocs = _groupDocumentsByMonth(filteredDocs);
    final displayedCategories = ['Tất cả', ..._viewModel.categoryNames];
    final displayedTags = ['Tất cả', ..._viewModel.availableTags];

    // Ensure selected items are still valid if lists changed
    if (!displayedCategories.contains(_selectedCategory)) {
      _selectedCategory = 'Tất cả';
    }
    if (!displayedTags.contains(_selectedTag)) {
      _selectedTag = 'Tất cả';
    }

    final body = _viewModel.isLoading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DocumentFilterBar(
            selectedCategory: _selectedCategory,
            selectedStatus: _selectedStatus,
            selectedTimeFilter: _selectedTimeFilter,
            selectedTag: _selectedTag,
            categories: displayedCategories,
            statuses: _statuses,
            timeFilters: _timeFilters,
            availableTags: displayedTags,
            onCategoryChanged: (val) => setState(() => _selectedCategory = val),
            onStatusChanged: (val) => setState(() => _selectedStatus = val),
            onTimeFilterChanged: (val) => setState(() => _selectedTimeFilter = val),
            onTagChanged: (val) => setState(() => _selectedTag = val),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
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

          if (filteredDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('Không tìm thấy tài liệu nào', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...groupedDocs.entries.map((entry) {
              return Column(
                children: [
                  _buildMonthHeader(entry.key),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildRealDocItem(context, entry.value[index]);
                    },
                  ),
                ],
              );
            }),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashScreen()),
              ).then((_) => _loadDocuments());
            },
          ),
        ],
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

  Widget _buildRealDocItem(BuildContext context, MedicalDocumentEntity doc) {
    // Simplify: use only one icon and one primary color style
    const icon = Icons.description;
    final iconBgColor = AppColors.primary.withValues(alpha: 0.1);
    const iconColor = AppColors.primary;

    final dateStr = doc.recordDate != null
        ? DateFormat('dd MMM, yyyy').format(DateTime.fromMillisecondsSinceEpoch(doc.recordDate!))
        : 'N/A';
    
    final createdByName = doc.createdByName ?? 'Ẩn danh';
    final subtitle = '$dateStr • BS. $createdByName';

    final List<Map<String, dynamic>> tagsData = [];
    if (doc.categoryName != null) {
      tagsData.add({
        'name': doc.categoryName!,
        'color': AppColors.backgroundLight,
        'textColor': AppColors.textSecondary,
      });
    }
    if (doc.status == 'SAVED') {
      tagsData.add({
        'name': 'Đã lưu',
        'color': Colors.green[50],
        'textColor': Colors.green[600],
      });
    } else if (doc.status == 'DRAFT') {
      tagsData.add({
        'name': 'Bản nháp',
        'color': Colors.amber[50],
        'textColor': Colors.amber[800],
      });
    }

    // Add extra custom tags from doc.tags
    for (var tag in doc.tags) {
       tagsData.add({
         'name': tag,
         'color': Colors.grey[200],
         'textColor': Colors.grey[800],
       });
    }

    return _buildDocItem(
      context,
      doc: doc,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      title: doc.title ?? 'Không có tiêu đề',
      subtitle: subtitle,
      status: doc.status,
      tags: tagsData,
    );
  }

  Widget _buildDocItem(
    BuildContext context, {
    required MedicalDocumentEntity doc,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> tags,
    String status = 'SAVED',
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DocumentDetailScreen(document: doc)),
          ).then((_) {
            _loadDocuments();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
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
                            horizontal: 10,
                            vertical: 4,
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
      ),
    );
  }
}
