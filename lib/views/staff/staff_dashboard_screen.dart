import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrprmgroupproject/viewmodels/staff_management_viewmodel.dart';
import '../theme/app_theme.dart';
import 'create_patient_screen.dart';
import 'patient_list_screen.dart';
import 'create_medical_exam_screen.dart';
import '../auth/personal_settings_screen.dart';
import '../documents/document_list_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _selectedIndex = 0;
  int _documentRefreshKey = 0;
  String? avatarCurrentUser = AuthViewModel.instance.currentUser?.avatar;
  final StaffManagementViewModel _staffViewModel = StaffManagementViewModel();

  @override
  void initState() {
    super.initState();
    _staffViewModel.addListener(_onViewModelChanged);
    _loadInitialData();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {
        avatarCurrentUser = AuthViewModel.instance.currentUser?.avatar;
      });
    }
  }

  Future<void> _loadInitialData() async {
    _staffViewModel.loadStats();
    _staffViewModel.loadRecentDocuments();
    _staffViewModel.loadPatients();
  }

  @override
  void dispose() {
    _staffViewModel.removeListener(_onViewModelChanged);
    _staffViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthViewModel.instance.currentUser;
    final bool isCustomer = user?.role == 'CUSTOMER';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(context),
            PatientListScreen(embedded: true, viewModel: _staffViewModel),
            DocumentListScreen(key: ValueKey('doc_list_$_documentRefreshKey'), embedded: true),
            const PersonalSettingsScreen(embedded: true),
          ],
        ),
      ),
      floatingActionButton: isCustomer ? null : SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () async {
            Widget targetScreen;
            if (_selectedIndex == 1) {
              targetScreen = const CreatePatientScreen();
            } else {
              targetScreen = const CreateMedicalExamScreen();
            }

            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );
            
            if (result == true) {
              setState(() {
                _documentRefreshKey++;
                if (_selectedIndex != 1 && _selectedIndex != 2) {
                   _selectedIndex = 2; // Chuyển qua tab Tài liệu nếu tạo đơn khám từ Home
                }
              });
              _loadInitialData(); // Điều này đã bao gồm loadPatients()
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            // Force reload documents tab khi chuyển sang
            if (index == 2) {
              _documentRefreshKey++;
            }
            // Reload stats khi quay về Home
            if (index == 0) {
              _loadInitialData();
            }
          });
        },
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
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Bệnh nhân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Tài liệu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    final user = AuthViewModel.instance.currentUser;
    final bool isCustomer = user?.role == 'CUSTOMER';
    final isLoading = _staffViewModel.isLoading;
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _staffViewModel.stats;
    final recentPatientsList = _staffViewModel.recentPatients;
    final formatter = NumberFormat('#,###', 'en_US');
    final String documentsToday = stats != null ? formatter.format(stats.documentToday) : '0';

    final percentFormatter = NumberFormat.percentPattern('en_US');

    final double ratio = (stats != null && stats.totalDocuments > 0)
        ? (stats.documentToday / stats.totalDocuments)
        : 0.0;

    final String percentText = percentFormatter.format(ratio);


    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AppBar Style Header for Home
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    image: (avatarCurrentUser != null)
                        ? DecorationImage(
                      image: FileImage(File(avatarCurrentUser!)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (avatarCurrentUser == null)
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào buổi sáng,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      AuthViewModel.instance.currentUser?.fullName ??
                          'Nhân viên',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.notifications_none,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),


          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isCustomer) ...[
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.person_add,
                          label: 'Tạo hồ sơ\nBệnh nhân',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreatePatientScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.assignment_add,
                          label: 'Tạo Đơn\nKhám',
                          color: Colors.blue[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateMedicalExamScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.group,
                        label: 'Danh sách\nBệnh nhân',
                        color: Colors.orange,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.folder_open,
                        label: 'Tài liệu\nY tế',
                        color: Colors.teal,
                        onTap: () {
                          setState(() => _selectedIndex = 2);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildStatCard(
              icon: Icons.description,
              iconBgColor: AppColors.primary.withValues(alpha: 0.1),
              iconColor: AppColors.primary,
              title: 'Hồ sơ tài liệu hôm nay',
              value: documentsToday,
              badgeText: percentText,
              badgeColor: AppColors.primary,
              badgeBgColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Profiles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hồ sơ gần đây',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: recentPatientsList.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'Chưa có hồ sơ nào gần đây',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                      : Column(
                    children: List.generate(recentPatientsList.length, (index) {
                      final patient = recentPatientsList[index];

                      final String fullName = patient['full_name'] ?? 'Chưa cập nhật tên';
                      final String medicalCode = patient['medical_code'] ?? 'Không có mã';
                      final String? dob = patient['dob'];
                      final dynamic createdAt = patient['created_at'];

                      final String subtitle = '${_calculateAge(dob)} • $medicalCode';

                      final String timeAgo = _getTimeAgo(createdAt);

                      return Column(
                        children: [
                          _buildRecentItem(
                            fullName,
                            subtitle,
                            timeAgo,
                          ),
                          if (index < recentPatientsList.length - 1)
                            const Divider(height: 1, color: Colors.black12),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String value,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBgColor,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String name, String details, String time) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'Không rõ tuổi';
    try {
      DateTime birthDate = DateFormat('dd/MM/yyyy').parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age tuổi';
    } catch (e) {
      return 'Không rõ tuổi';
    }
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Vừa xong';

    DateTime? createdDate;

    if (createdAt is num) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
    } else if (createdAt is String) {
      final parsedInt = int.tryParse(createdAt);
      if (parsedInt != null) {
        createdDate = DateTime.fromMillisecondsSinceEpoch(parsedInt);
      } else {
        createdDate = DateTime.tryParse(createdAt);
      }
    }

    if (createdDate == null) return 'Vừa xong';

    final difference = DateTime.now().difference(createdDate);

    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours}h trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes}p trước';
    return 'Vừa xong';
  }
}
