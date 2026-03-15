import 'package:flutter/material.dart';
import '../../data/implementations/audit_log_repository.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../theme/app_theme.dart';

class SystemAuditLogScreen extends StatefulWidget {
  final bool embedded;
  const SystemAuditLogScreen({super.key, this.embedded = false});

  @override
  State<SystemAuditLogScreen> createState() => _SystemAuditLogScreenState();
}

class _SystemAuditLogScreenState extends State<SystemAuditLogScreen> {
  final AuditLogRepository _repo = AuditLogRepository();

  List<AuditLogEntity> _logs = [];
  bool _isLoading = true;

  // Filter state
  String? _selectedRole;
  DateTimeRange? _selectedDateRange;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultLogs();
  }

  /// Mặc định: chỉ hôm nay + hôm qua
  Future<void> _loadDefaultLogs() async {
    setState(() {
      _isLoading = true;
      _isFiltered = false;
      _selectedRole = null;
      _selectedDateRange = null;
    });
    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final endOfToday = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      _logs = await _repo.getLogs(from: yesterday, to: endOfToday);
    } catch (_) {
      _logs = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Lọc theo bộ lọc đã chọn
  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);

    DateTime? from;
    DateTime? to;

    if (_selectedDateRange != null) {
      from = _selectedDateRange!.start;
      to = _selectedDateRange!.end.add(const Duration(days: 1));
    } else {
      // Nếu chỉ lọc role mà không chọn ngày → vẫn lấy hôm nay + hôm qua
      final now = DateTime.now();
      from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      to = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    }

    try {
      _logs = await _repo.getLogs(from: from, to: to, role: _selectedRole);
    } catch (_) {
      _logs = [];
    }

    _isFiltered = _selectedRole != null || _selectedDateRange != null;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      _selectedDateRange = picked;
      _applyFilters();
    }
  }

  void _pickRole() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Tất cả vai trò'),
                leading: const Icon(Icons.people),
                selected: _selectedRole == null,
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedRole = null;
                  _applyFilters();
                },
              ),
              ListTile(
                title: const Text('Admin'),
                leading: const Icon(Icons.admin_panel_settings),
                selected: _selectedRole == 'ADMIN',
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedRole = 'ADMIN';
                  _applyFilters();
                },
              ),
              ListTile(
                title: const Text('Nhân viên (Staff)'),
                leading: const Icon(Icons.badge),
                selected: _selectedRole == 'STAFF',
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedRole = 'STAFF';
                  _applyFilters();
                },
              ),
              ListTile(
                title: const Text('Khách hàng (Customer)'),
                leading: const Icon(Icons.person),
                selected: _selectedRole == 'CUSTOMER',
                onTap: () {
                  Navigator.pop(ctx);
                  _selectedRole = 'CUSTOMER';
                  _applyFilters();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Group logs by date header ──

  Map<String, List<AuditLogEntity>> _groupByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <String, List<AuditLogEntity>>{};

    for (final log in _logs) {
      if (log.timestamp == null) continue;
      final logDay = DateTime(log.timestamp!.year, log.timestamp!.month, log.timestamp!.day);
      String label;
      if (logDay == today) {
        label = 'HÔM NAY';
      } else if (logDay == yesterday) {
        label = 'HÔM QUA';
      } else {
        label = '${logDay.day.toString().padLeft(2, '0')}/${logDay.month.toString().padLeft(2, '0')}/${logDay.year}';
      }
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(log);
    }
    return grouped;
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'ADMIN': return 'Admin';
      case 'STAFF': return 'Nhân viên';
      case 'CUSTOMER': return 'Khách hàng';
      default: return role ?? '';
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final Widget mainContent = Column(
      children: [
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildFilterButton(
                icon: Icons.date_range,
                label: _selectedDateRange != null
                    ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                    : 'Khoảng thời gian',
                active: _selectedDateRange != null,
                onTap: _pickDateRange,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                icon: Icons.people_outline,
                label: _selectedRole != null ? _roleLabel(_selectedRole) : 'Vai trò',
                active: _selectedRole != null,
                onTap: _pickRole,
              ),
              if (_isFiltered) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loadDefaultLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(color: AppColors.border, height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? const Center(child: Text('Không có nhật ký nào', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: _buildGroupedList(),
                    ),
        ),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            'Nhật ký hệ thống',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: mainContent,
      );
    }

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
          'Nhật ký hệ thống',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: mainContent,
    );
  }

  List<Widget> _buildGroupedList() {
    final grouped = _groupByDate();
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(_buildDateHeader(entry.key));
      for (int i = 0; i < entry.value.length; i++) {
        widgets.add(_buildLogItem(entry.value[i]));
        if (i < entry.value.length - 1) {
          widgets.add(const Divider(height: 1, color: AppColors.border));
        }
      }
    }
    return widgets;
  }

  Widget _buildFilterButton({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.1) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: AppColors.primary, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textPrimary)),
    );
  }

  Widget _buildLogItem(AuditLogEntity log) {
    final time = log.timestamp != null
        ? '${log.timestamp!.hour.toString().padLeft(2, '0')}:${log.timestamp!.minute.toString().padLeft(2, '0')}'
        : '';
    final name = log.userName ?? 'Hệ thống';
    final roleBadge = log.userRole != null ? _roleLabel(log.userRole) : '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                    ),
                    if (roleBadge.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(roleBadge, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log.action, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.details!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
