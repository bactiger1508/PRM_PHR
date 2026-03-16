import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrprmgroupproject/viewmodels/staff_management_viewmodel.dart';
import '../theme/app_theme.dart';
import '../../domain/entities/patient_entity.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool embedded;
  final StaffManagementViewModel? viewModel;

  const PatientListScreen({super.key, this.embedded = false, this.viewModel});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  late StaffManagementViewModel _staffViewModel;
  bool _isLocalViewModel = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _staffViewModel = widget.viewModel!;
    } else {
      _staffViewModel = StaffManagementViewModel();
      _isLocalViewModel = true;
      _staffViewModel.loadStats();
      _staffViewModel.loadPatients();
    }
    _staffViewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _staffViewModel.removeListener(_onViewModelChanged);
    if (_isLocalViewModel) {
      _staffViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _staffViewModel.stats;
    final patients = _staffViewModel.filteredPatients;
    final formatter = NumberFormat('#,###', 'en_US');

    final String totalDocuments = stats != null ? formatter.format(stats.totalDocuments) : '0';
    final String docsThisMonth = stats != null ? '+${formatter.format(stats.documentsThisMonth)} tháng này' : '+0 tháng này';

    final String totalPatients = stats != null ? formatter.format(stats.totalPatients) : '0';
    final String patientsThisMonth = stats != null ? '+${formatter.format(stats.patientsThisMonth)} tháng này' : '+0 tháng này';

    final Widget mainContent = Column(
      children: [
        // Stats Row
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng số hồ sơ',
                    value: totalDocuments,
                    trendText: docsThisMonth,
                    trendIcon: Icons.trending_up,
                    trendColor: Colors.green[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng số bệnh nhân',
                    value: totalPatients,
                    trendText: patientsThisMonth,
                    trendIcon: Icons.trending_up,
                    trendColor: Colors.green[600]!,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00897B), width: 1.5),
            ),
            child: TextField(
              onChanged: _staffViewModel.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm tên hoặc mã y tế...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textLight,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (_staffViewModel.isLoading && patients.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_staffViewModel.errorMsg != null && patients.isEmpty)
          Expanded(child: Center(child: Text(_staffViewModel.errorMsg!)))
        else if (patients.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Chưa có hồ sơ bệnh nhân nào',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                return _buildPatientItem(patients[index]);
              },
            ),
          ),
      ],
    );

    if (widget.embedded) {
      return mainContent;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Danh sách Bệnh nhân'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: mainContent,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trendText,
    required IconData trendIcon,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trendText,
                style: TextStyle(
                  fontSize: 10,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(PatientEntity patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              patient.phone != null && patient.phone!.isNotEmpty
                  ? patient.phone!
                  : (patient.medicalCode.isNotEmpty ? patient.medicalCode : 'ID: ${patient.id}'),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailScreen(
                email: patient.email,
                phone: patient.phone,
              ),
            ),
          ).then((_) {
             _staffViewModel.loadPatients();
             _staffViewModel.loadStats();
          });
        },
      ),
    );
  }
}
