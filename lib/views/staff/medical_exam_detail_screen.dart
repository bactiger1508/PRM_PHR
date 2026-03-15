import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../domain/entities/medical_exam_entity.dart';

class MedicalExamDetailScreen extends StatelessWidget {
  final MedicalExamEntity exam;

  const MedicalExamDetailScreen({super.key, required this.exam});

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
          'Chi tiết Đơn Khám',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'print', child: Text('In đơn khám')),
              const PopupMenuItem(value: 'share', child: Text('Chia sẻ')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle actions
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== Patient Info Card ==========
            _buildCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(exam.patientName ?? ''),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.patientName ?? 'Bệnh nhân',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exam.patientMedicalCode ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          Icons.calendar_today,
                          'Ngày khám',
                          exam.examDate,
                          Colors.blue[600]!,
                        ),
                      ),
                      if (exam.createdByName != null)
                        Expanded(
                          child: _buildDetailRow(
                            Icons.person,
                            'Bác sĩ',
                            exam.createdByName!,
                            AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== Triệu chứng ==========
            if (exam.symptoms != null && exam.symptoms!.isNotEmpty)
              _buildSection(
                icon: Icons.sick,
                title: 'Triệu chứng',
                color: Colors.orange[600]!,
                content: exam.symptoms!,
              ),

            // ========== Dấu hiệu sinh tồn ==========
            if (exam.vitalSigns != null && exam.vitalSigns!.isNotEmpty)
              _buildSection(
                icon: Icons.monitor_heart,
                title: 'Dấu hiệu sinh tồn',
                color: Colors.red[600]!,
                content: exam.vitalSigns!,
              ),

            // ========== Chẩn đoán ==========
            if (exam.diagnosis != null && exam.diagnosis!.isNotEmpty)
              _buildHighlightSection(
                icon: Icons.medical_information,
                title: 'Chẩn đoán',
                content: exam.diagnosis!,
              ),

            // ========== Đơn thuốc ==========
            if (exam.prescription != null && exam.prescription!.isNotEmpty)
              _buildSection(
                icon: Icons.medication,
                title: 'Đơn thuốc / Chỉ định điều trị',
                color: Colors.green[600]!,
                content: exam.prescription!,
              ),

            // ========== Tái khám ==========
            if (exam.followUpDate != null && exam.followUpDate!.isNotEmpty)
              _buildCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.event_repeat,
                          color: Colors.purple[600], size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày tái khám',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exam.followUpDate!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ========== Ghi chú ==========
            if (exam.notes != null && exam.notes!.isNotEmpty)
              _buildSection(
                icon: Icons.edit_note,
                title: 'Ghi chú',
                color: Colors.teal[600]!,
                content: exam.notes!,
              ),

            const SizedBox(height: 24),

            // Footer info
            if (exam.createdAt != null)
              Center(
                child: Text(
                  'Tạo lúc: ${_formatDateTime(exam.createdAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.orange[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    Icon(icon, color: Colors.orange[700], size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.orange[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusColor = exam.status == 'COMPLETED'
        ? Colors.green
        : exam.status == 'DRAFT'
            ? Colors.orange
            : Colors.red;
    final statusText = exam.status == 'COMPLETED'
        ? 'Hoàn thành'
        : exam.status == 'DRAFT'
            ? 'Nháp'
            : 'Đã hủy';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: statusColor[700],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
