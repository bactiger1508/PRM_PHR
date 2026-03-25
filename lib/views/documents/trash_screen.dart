import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/medical_document_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../domain/entities/medical_document_entity.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final MedicalDocumentViewModel _viewModel = MedicalDocumentViewModel();
  static const Color danger = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _loadDeletedDocuments();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDeletedDocuments() async {
    final staffId = AuthViewModel.instance.currentUser?.id;
    if (staffId != null) {
      await _viewModel.loadDocumentsByCreator(staffId);
    }
  }

  List<MedicalDocumentEntity> get _deletedDocs {
    return _viewModel.documents
        .where((doc) => doc.status == 'DELETED' || doc.isDeleted == 1)
        .toList();
  }

  int _calculateDaysLeft(DateTime? updatedAt) {
    if (updatedAt == null) return 30;
    final updatedDate = updatedAt;
    final expiryDate = updatedDate.add(const Duration(days: 30));
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  Future<void> _handleRestore(MedicalDocumentEntity doc) async {
    final success = await _viewModel.restoreDocument(doc.id!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã khôi phục tài liệu: ${doc.title}')),
      );
      _loadDeletedDocuments();
    }
  }

  Future<void> _handleHardDelete(MedicalDocumentEntity doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa vĩnh viễn'),
        content: Text('Tài liệu "${doc.title}" sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn có chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _viewModel.hardDeleteDocument(doc.id!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa vĩnh viễn tài liệu.')),
        );
        _loadDeletedDocuments();
      }
    }
  }

  Future<void> _handleClearTrash() async {
    final deletedDocsCount = _deletedDocs.length;
    if (deletedDocsCount == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dọn sạch thùng rác'),
        content: Text('Tất cả $deletedDocsCount tài liệu trong thùng rác sẽ bị xóa vĩnh viễn. Thao tác này không thể hoàn tác. Bạn có chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: danger),
            child: const Text('Dọn sạch'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final staffId = AuthViewModel.instance.currentUser?.id;
      if (staffId != null) {
        final success = await _viewModel.clearTrash(staffId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã dọn sạch thùng rác.')),
          );
          _loadDeletedDocuments();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deletedDocs = _deletedDocs;

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
          'Thùng rác tài liệu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (deletedDocs.isNotEmpty)
            TextButton(
              onPressed: _handleClearTrash,
              style: TextButton.styleFrom(
                foregroundColor: danger,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Dọn sạch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : deletedDocs.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      _buildInfoBanner(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: List.generate(deletedDocs.length, (index) {
                              final doc = deletedDocs[index];
                              final isLast = index == deletedDocs.length - 1;
                              return Column(
                                children: [
                                  _buildTrashItem(doc),
                                  if (!isLast) const Divider(height: 1, color: AppColors.border),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(Icons.delete_outline, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thùng rác trống',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các tài liệu bạn xóa sẽ xuất hiện ở đây.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tài liệu trong thùng rác sẽ tự động bị xóa vĩnh viễn sau 30 ngày.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrashItem(MedicalDocumentEntity doc) {
    final deletedDate = doc.updatedAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(doc.updatedAt!)
        : 'N/A';
    
    final daysLeft = _calculateDaysLeft(doc.updatedAt);

    IconData getIcon() {
      switch (doc.categoryId) {
        case 1: return Icons.science;
        case 2: return Icons.medication;
        case 3: return Icons.masks;
        default: return Icons.description;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(getIcon(), color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title ?? 'Không có tiêu đề',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã xóa: $deletedDate',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: daysLeft <= 3 ? danger : Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Còn $daysLeft ngày',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: daysLeft <= 3 ? danger : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _handleRestore(doc),
                icon: const Icon(Icons.restore, color: AppColors.primary, size: 22),
                tooltip: 'Khôi phục',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => _handleHardDelete(doc),
                icon: const Icon(Icons.delete_forever, color: danger, size: 22),
                tooltip: 'Xóa vĩnh viễn',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
