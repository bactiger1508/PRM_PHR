import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phrprmgroupproject/views/staff/patient_detail_screen.dart';
import '../theme/app_theme.dart';
import '../auth/personal_settings_screen.dart';
import '../auth/system_notification_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/family_member_viewmodel.dart';
import '../../data/implementations/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import 'add_family_member_screen.dart';

class CustomerFamilyHomeScreen extends StatefulWidget {
  const CustomerFamilyHomeScreen({super.key});

  @override
  State<CustomerFamilyHomeScreen> createState() => _CustomerFamilyHomeScreenState();
}

class _CustomerFamilyHomeScreenState extends State<CustomerFamilyHomeScreen> {
  int _selectedIndex = 0;
  final FamilyMemberViewModel _viewModel = FamilyMemberViewModel();
  String? avatarCurrentUser = AuthViewModel.instance.currentUser?.avatar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = AuthViewModel.instance.currentUser;
    if (user != null && user.id != null) {
      _viewModel.fetchFamilyMembers(user.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(context),
          const SystemNotificationScreen(embedded: true),
          const PersonalSettingsScreen(embedded: true),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0 && (AuthViewModel.instance.currentUser?.isFamilyHead ?? false))
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFamilyMemberScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Thông báo',
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Gia đình của tôi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danh sách thành viên',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    (AuthViewModel.instance.currentUser?.isFamilyHead ?? false)
                        ? 'Nhấn vào dấu + để liên kết hồ sơ người thân'
                        : 'Bạn có thể xem hồ sơ của các thành viên trong gia đình',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Family Members List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoading) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  
                  final selfMember = _viewModel.familyMembers.where((m) => m['relationship'] == 'Bản thân').firstOrNull;
                  final otherMembers = _viewModel.familyMembers.where((m) => m['relationship'] != 'Bản thân').toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Bản thân (Always show if exists)
                      if (selectedMember(selfMember)) ...[
                        _buildSectionHeader('Hồ sơ của bạn'),
                        _buildFamilyMemberCard(
                          context: context,
                          name: selfMember!['full_name'] ?? 'Không tên',
                          relation: selfMember['relationship'] ?? 'N/A',
                          id: selfMember['medical_code'],
                          patientId: selfMember['id'] as int?,
                          lastUpdate: _formatDate(selfMember['updated_at']),
                          isPrimary: true,
                          avatar: selfMember['avatar'],
                          email: selfMember['email'],
                          phone: selfMember['phone'],
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Section 2: Người thân
                      _buildSectionHeader('Người thân đã liên kết'),
                      if (otherMembers.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: otherMembers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final member = otherMembers[index];
                            return _buildFamilyMemberCard(
                              context: context,
                              name: member['full_name'] ?? 'Không tên',
                              relation: member['relationship'] ?? 'N/A',
                              id: member['medical_code'],
                              patientId: member['id'], // Pass patientId for removal
                              lastUpdate: _formatDate(member['updated_at']),
                              isPrimary: false,
                              email: member['email'],
                              phone: member['phone'],
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool selectedMember(dynamic member) => member != null;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: AppColors.textLight.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có người thân nào được liên kết',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Chưa cập nhật';
    try {
      if (timestamp is int) {
        return DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      }
      if (timestamp is String) {
        final parsed = int.tryParse(timestamp);
        if (parsed != null) {
          return DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(parsed));
        }
        final date = DateTime.tryParse(timestamp);
        if (date != null) return DateFormat('dd/MM/yyyy').format(date);
      }
      return 'Không rõ';
    } catch (_) {
      return 'Không rõ';
    }
  }


  Widget _buildFamilyMemberCard({
    required BuildContext context,
    required String name,
    required String relation,
    String? id,
    required String lastUpdate,
    bool isPrimary = false,
    String? avatar,
    String? email,
    String? phone,
    int? patientId,
  }) {
    final bool isCurrentUserHead = AuthViewModel.instance.currentUser?.isFamilyHead ?? false;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : null,
        boxShadow: isPrimary ? AppTheme.glowingShadow : AppTheme.softShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPrimary)
            Positioned(
              top: -24,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Tài khoản của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  image: (avatar != null && avatar.isNotEmpty && File(avatar).existsSync())
                      ? DecorationImage(
                          image: FileImage(File(avatar)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Quan hệ: $relation',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isPrimary
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPrimary && isCurrentUserHead)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                            onSelected: (value) async {
                              if (value == 'remove') {
                                if (patientId == null) return;
                                _showRemoveConfirm(context, name, patientId);
                              } else if (value == 'transfer') {
                                _showTransferConfirm(context, name, email);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'transfer',
                                child: ListTile(
                                  leading: Icon(Icons.swap_horiz, size: 20),
                                  title: Text('Chuyển quyền chủ gia đình'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: ListTile(
                                  leading: Icon(Icons.person_remove, color: Colors.red, size: 20),
                                  title: Text('Xóa khỏi gia đình', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (isPrimary && isCurrentUserHead) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Chủ gia đình',
                              style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (id != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mã Y Tế: $id',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.history, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          'Cập nhật cuối: $lastUpdate',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientDetailScreen(
                                patientProfileId: patientId,
                                email: email,
                                phone: phone,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text('Xem hồ sơ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  void _showRemoveConfirm(BuildContext context, String name, int patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa $name khỏi gia đình không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final headId = AuthViewModel.instance.currentUser?.id;
              if (headId != null) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final success = await _viewModel.removeMember(headId, patientId);
                
                if (success) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Đã xóa $name khỏi gia đình')),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTransferConfirm(BuildContext context, String name, String? email) {
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thành viên này không có tài khoản để chuyển quyền.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context2) => AlertDialog(
        title: const Text('Chuyển quyền'),
        content: Text('Bạn có muốn chuyển quyền Chủ gia đình cho $name không? Sau khi chuyển, bạn sẽ không còn quyền quản lý gia đình.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context2), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context2);

              try {
                final currentHead = AuthViewModel.instance.currentUser;
                if (currentHead == null) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Lỗi: Không tìm thấy thông tin tài khoản hiện tại.')),
                  );
                  return;
                }

                final targetUser = await AuthRepositoryImpl().findByEmail(email);
                if (targetUser == null || targetUser.id == null) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Không tìm thấy tài khoản của thành viên này.')),
                  );
                  return;
                }

                final success = await _viewModel.transferHead(currentHead.id!, targetUser.id!);
                navigator.pop();

                if (success) {
                  // Update local Auth status
                  final updatedHead = UserEntity(
                    id: currentHead.id,
                    fullName: currentHead.fullName,
                    phone: currentHead.phone,
                    email: currentHead.email,
                    role: currentHead.role,
                    avatar: currentHead.avatar,
                    familyId: currentHead.familyId,
                    isFamilyHead: false,
                  );
                  AuthViewModel.instance.refreshCurrentUser(updatedHead);
                  
                  if (mounted) {
                    setState(() {}); // Refresh UI
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Đã chuyển quyền chủ gia đình cho $name')),
                    );
                  }
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Chuyển quyền thất bại. Vui lòng thử lại.')),
                  );
                }
              } catch (e) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Đã xảy ra lỗi: ${e.toString()}')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}


