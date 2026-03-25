import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrprmgroupproject/core/utils/string_utils.dart';
import 'package:phrprmgroupproject/data/implementations/medical_document_repository_impl.dart';
import 'package:phrprmgroupproject/data/implementations/patient_repository_impl.dart';
import 'package:phrprmgroupproject/domain/entities/patient_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../documents/document_detail_screen.dart';
import '../theme/app_theme.dart';
import 'create_medical_exam_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  /// Ưu tiên: mở đúng hồ sơ kể cả BN không có email/SĐT.
  final int? patientProfileId;
  final String? email;
  final String? phone;

  const PatientDetailScreen({
    super.key,
    this.patientProfileId,
    this.email,
    this.phone,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _selectedTab = 1; // Mặc định mở tab "Tài liệu" như trong ảnh

  PatientEntity? _patientProfile;
  List<Map<String, dynamic>> _documents = [];
  final _patientRepository = PatientRepositoryImpl();
  final _medicalDocRepository = MedicalDocumentRepositoryImpl();
  final _docSearchController = TextEditingController();
  String _docCategoryFilter = 'Tất cả loại';

  @override
  void initState() {
    super.initState();
    _docSearchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPatientData();
  }

  @override
  void dispose() {
    _docSearchController.dispose();
    super.dispose();
  }

  List<String> get _docCategoryOptions {
    final names = _documents
        .map((d) => d['category_name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Tất cả loại', ...names];
  }

  List<Map<String, dynamic>> get _filteredDocuments {
    var list = List<Map<String, dynamic>>.from(_documents);
    final q = StringUtils.removeDiacritics(_docSearchController.text.trim().toLowerCase());
    if (q.isNotEmpty) {
      list = list.where((d) {
        final title = StringUtils.removeDiacritics(
            (d['title'] as String? ?? '').toLowerCase());
        final notes = StringUtils.removeDiacritics(
            (d['notes'] as String? ?? '').toLowerCase());
        return title.contains(q) || notes.contains(q);
      }).toList();
    }
    if (_docCategoryFilter != 'Tất cả loại') {
      list = list
          .where((d) =>
              (d['category_name'] as String? ?? '') == _docCategoryFilter)
          .toList();
    }
    return list;
  }

  Future<void> _loadPatientData() async {
    try {
      PatientEntity? data;
      if (widget.patientProfileId != null) {
        data = await _patientRepository.getPatientById(widget.patientProfileId!);
      }
      data ??= await _patientRepository.getPatientByPhoneOrEmail(
        email: widget.email,
        phone: widget.phone,
      );

      if (mounted) {
        setState(() {
          _patientProfile = data;
        });

        if (data != null && data.id != null) {
          _loadDocuments(data.id!);
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadDocuments(int patientId) async {
    try {
      final docs = await _patientRepository.getDocumentsByPatientId(patientId);
      if (mounted) {
        setState(() {
          _documents = docs;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _openDocumentDetail(Map<String, dynamic> docRow) async {
    final id = docRow['id'] as int?;
    if (id == null) return;

    final entity = await _medicalDocRepository.getDocumentById(id);
    if (!mounted) return;
    if (entity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được chi tiết tài liệu.')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: entity),
      ),
    );
    if (result == true && mounted && _patientProfile?.id != null) {
      _loadDocuments(_patientProfile!.id!);
    }
  }

  String _formatDocDate(dynamic createdAt) {
    if (createdAt == null) return 'Chưa rõ';
    DateTime? d;
    if (createdAt is num) {
      d = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
    } else if (createdAt is String) {
      d = DateTime.tryParse(createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(int.tryParse(createdAt) ?? 0);
    }
    if (d == null) return 'Chưa rõ';
    return DateFormat('dd/MM/yyyy').format(d);
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết hồ sơ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_patientProfile == null)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy hồ sơ bệnh nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kiểm tra mã hồ sơ hoặc liên hệ nhân viên nếu bạn vừa được thêm vào gia đình.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Nút chuyển sang màn tạo hồ sơ
                      },
                      child: const Text('Tạo hồ sơ ngay'),
                    ),
                  ],
                ),
              )
            // TRƯỜNG HỢP 3: CÓ HỒ SƠ -> HIỂN THỊ DỮ LIỆU THẬT
            else ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar (Tự trích xuất chữ cái đầu của tên thật)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          _patientProfile!.fullName
                                  .substring(0, 1)
                                  .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            _patientProfile!.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ngày sinh: ${_patientProfile!.dob ?? 'Chưa cập nhật'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                           Text(
                            'Mã Y Tế: ${_patientProfile!.medicalCode}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Add Document Button
              if (AuthViewModel.instance.currentUser?.role != 'CUSTOMER')
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final p = _patientProfile;
                      if (p?.id == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateMedicalExamScreen(
                            preselectedPatientId: p!.id,
                            preselectedPatientName: p.fullName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tạo đơn khám'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

              // Navigation Tabs
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _buildTab('Thông tin', 0),
                    _buildTab('Tài liệu', 1),
                  ],
                ),
              ),

              // Dynamic Content Area
              if (_selectedTab == 0) _buildInfoTab(),
              if (_selectedTab == 1) _buildDocumentsTab(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    final p = _patientProfile;
    final noContact = p != null &&
        (p.phone == null || p.phone!.trim().isEmpty) &&
        (p.email == null || p.email!.trim().isEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noContact)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: const Text(
                  'Hồ sơ chưa có số điện thoại hoặc email. Thông tin cá nhân bên dưới có thể trống; tài liệu y tế vẫn xem tại tab Tài liệu.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          _buildInfoRow(
            Icons.phone_outlined,
            'Số điện thoại',
            _patientProfile?.phone ?? 'Chưa cập nhật',
          ),
          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            _patientProfile?.email ?? 'Chưa cập nhật',
          ),
          _buildInfoRow(
            Icons.cake_outlined,
            'Ngày sinh',
            _patientProfile?.dob ?? 'Chưa cập nhật',
          ),
          // _buildInfoRow(Icons.family_restroom_outlined, 'Người giám hộ', 'Trần Thị B (Vợ)'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textLight),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search and category filter row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _docSearchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm tên tài liệu...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _docCategoryOptions.contains(_docCategoryFilter)
                        ? _docCategoryFilter
                        : 'Tất cả loại',
                    items: _docCategoryOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _docCategoryFilter = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Đang hiển thị ${_filteredDocuments.length} / ${_documents.length} tài liệu',
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
            if (_documents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Chưa có tài liệu nào',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (_filteredDocuments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Không có tài liệu khớp bộ lọc',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ..._filteredDocuments.map((doc) {
              final String title = doc['title'] ?? 'Tài liệu không tên';

              final String date = _formatDocDate(
                doc['record_date'] ?? doc['created_at'],
              );

              final String categoryName =
                  doc['category_name'] ?? 'Chưa phân loại';

              final String status = doc['status'] ?? 'SAVED';

              return _buildDocCard(
                doc: doc,
                title: title,
                date: date,
                type: 'Hồ sơ y tế • $categoryName',
                tags: [categoryName, status],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required Map<String, dynamic> doc,
    required String title,
    required String date,
    required String type,
    required List<String> tags,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDocumentDetail(doc),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.description,
                      color: AppColors.primary, size: 32),
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                'Ngày tải: $date',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t == 'Quan trọng'
                              ? Colors.orange[50]
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 10,
                            color: t == 'Quan trọng'
                                ? Colors.orange[700]
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
