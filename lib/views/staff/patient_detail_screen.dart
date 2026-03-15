import 'package:flutter/material.dart';
import 'package:phrprmgroupproject/data/implementations/patient_repository_impl.dart';
import 'package:phrprmgroupproject/domain/entities/patient_entity.dart';
import '../theme/app_theme.dart';
import 'create_medical_exam_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String? email;
  final String? phone;

  const PatientDetailScreen({super.key, this.email, this.phone});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _selectedTab = 1; // Mặc định mở tab "Tài liệu" như trong ảnh

  bool _isLoading = true;
  PatientEntity? _patientProfile;
  final _patientRepository = PatientRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final data = await _patientRepository.getPatientByPhoneOrEmail(
        email: widget.email,
        phone: widget.phone,
      );

      if (mounted) {
        setState(() {
          _patientProfile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải hồ sơ: $e");
      if (mounted) setState(() => _isLoading = false);
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
                      'Tài khoản này chưa có Hồ sơ Y tế',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Nút chuyển sang màn tạo hồ sơ
                      },
                      child: const Text('Tạo hồ sơ ngay'),
                    )
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
                          _patientProfile!.fullName?.substring(0, 1).toUpperCase() ?? 'N',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patientProfile!.fullName ?? 'Chưa có tên',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ngày sinh: ${_patientProfile!.dob ?? 'Chưa cập nhật'}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            'Mã Y Tế: ${_patientProfile!.medicalCode ?? 'Chưa có'}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Add Document Button
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateMedicalExamScreen(
                          preselectedPatientId: 1, // TODO: Use actual patient ID
                          preselectedPatientName: 'Nguyễn Văn An',
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
                        borderRadius: BorderRadius.circular(8)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Số điện thoại',
              _patientProfile?.phone ?? 'Chưa cập nhật'),
          _buildInfoRow(Icons.email_outlined, 'Email',
              _patientProfile?.email ?? 'Chưa cập nhật'),
          _buildInfoRow(Icons.cake_outlined, 'Ngày sinh',
              _patientProfile?.dob ?? 'Chưa cập nhật'),
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
              Text(label, style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
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
                  decoration: InputDecoration(
                    hintText: 'Tìm tên tài liệu...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textLight),
                    prefixIcon: const Icon(
                        Icons.search, color: AppColors.textLight),
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
                    value: 'Tất cả loại',
                    items: ['Tất cả loại', 'Xét nghiệm', 'X-Quang', 'Đơn thuốc']
                        .map((e) =>
                        DropdownMenuItem(
                            value: e, child: Text(e, style: const TextStyle(
                            fontSize: 14))))
                        .toList(),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Đang hiển thị 12 tài liệu',
                style: TextStyle(fontSize: 13, color: AppColors.textLight)),
          ),
          const SizedBox(height: 16),

          // Document Items
          _buildDocCard(
            title: 'Kết quả xét nghiệm máu tổng quát',
            date: '12/10/2023',
            type: 'PDF • 2.4 MB',
            tags: ['Xét nghiệm', 'Quan trọng'],
          ),
          _buildDocCard(
            title: 'Phim chụp X-Quang phổi thẳng',
            date: '05/10/2023',
            type: 'DICOM • 15 MB',
            tags: ['Chẩn đoán hình ảnh'],
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(
      {required String title, required String date, required String type, required List<
          String> tags}) {
    return Container(
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
              const Icon(Icons.description, color: AppColors.primary, size: 32),
              Text(type, style: const TextStyle(
                  fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Ngày tải: $date', style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tags.map((t) =>
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t == 'Quan trọng' ? Colors.orange[50] : AppColors
                        .backgroundLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 10,
                      color: t == 'Quan trọng' ? Colors.orange[700] : AppColors
                          .textSecondary)),
                )).toList(),
          ),
        ],
      ),
    );
  }

}
