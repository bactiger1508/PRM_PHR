import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final bool embedded;
  const PatientListScreen({super.key, this.embedded = false});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  int _selectedIndex = 0; // "Bệnh nhân" initially selected on bottom nav bar

  @override
  Widget build(BuildContext context) {
    // Extract the main body content into a variable
    final Widget mainContent = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng số hồ sơ',
                    value: '1,245',
                    trendText: '+12 tháng này',
                    trendIcon: Icons.trending_up,
                    trendColor: Colors.green[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng số bệnh nhân',
                    value: '156',
                    trendText: '+5 tháng này',
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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên hoặc mã y tế...',
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),



          // Patient List
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildPatientCard(
                name: 'Nguyễn Văn An',
                code: 'BN123456',
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Nguyen+Van+An&background=e2e8f0&color=475569',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                name: 'Nguyễn Thị Lan',
                code: '#BN-2023-001',
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Nguyen+Thi+Lan&background=fce7f3&color=db2777',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                name: 'Trần Văn Hùng',
                code: '#BN-2023-142',
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Tran+Van+Hung&background=e0e7ff&color=156bc1',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                name: 'Lê Minh Tuấn',
                code: '#BN-2023-088',
                initial: 'L',
                isOnline: true,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                name: 'Phạm Anh Đức',
                code: '#BN-2023-205',
                avatarUrl:
                    'https://ui-avatars.com/api/?name=Pham+Anh+Duc&background=ffedd5&color=c2410c',
                isOnline: true,
                opacity: 0.8,
              ),
            ],
          ),
        ],
      ),
    );

    // If embedded, return only the main content without Scaffold's furniture
    if (widget.embedded) {
      return mainContent;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        title: const Text(
          'Danh sách Bệnh nhân',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.backgroundLight,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://ui-avatars.com/api/?name=Doctor&background=e2e8f0&color=475569',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: mainContent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: widget.embedded ? null : BottomNavigationBar(
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
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Bệnh nhân',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trendText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required String name,
    required String code,
    String? avatarUrl,
    String? initial,
    bool isOnline = false,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientDetailScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Stack(
                children: [
                  if (avatarUrl != null)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.backgroundLight,
                      backgroundImage: NetworkImage(avatarUrl),
                    )
                  else if (initial != null)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.backgroundLight,
                      child: Icon(Icons.person, color: AppColors.textLight),
                    ),
      
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent[400]!,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
