import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Kiểm tra và yêu cầu quyền Camera
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) return true;

    if (context.mounted) {
      _showSettingsDialog(context, 'Camera');
    }
    return false;
  }

  /// Kiểm tra và yêu cầu quyền Bộ nhớ (Photos/Storage tùy OS)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    PermissionStatus status;
    
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (status.isDenied) {
          status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) return true;

    if (context.mounted) {
      _showSettingsDialog(context, 'Bộ nhớ/Ảnh');
    }
    return false;
  }

  /// Hiển thị hộp thoại hướng dẫn vào Cài đặt
  static void _showSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yêu cầu quyền $permissionName'),
        content: Text(
          'Bạn đã từ chối quyền $permissionName vĩnh viễn trong Cài đặt hệ thống. Vui lòng cấp quyền thủ công để tiếp tục sử dụng chức năng này.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  /// Yêu cầu các quyền cơ bản (Không khuyến khích gọi hàng loạt)
  static Future<void> requestInitialPermissions() async {
    // Để trống hoặc gọi hạn chế
  }
}
