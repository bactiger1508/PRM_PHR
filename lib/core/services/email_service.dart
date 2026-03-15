import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  SmtpServer get _smtpServer {
    final email = dotenv.env['SMTP_EMAIL'] ?? '';
    final password = dotenv.env['SMTP_PASSWORD'] ?? '';
    return gmail(email, password);
  }

  String get _senderEmail => dotenv.env['SMTP_EMAIL'] ?? '';

  /// Generate a random 6-digit OTP
  String generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }

  /// Send OTP verification email
  Future<bool> sendOtpEmail({
    required String toEmail,
    required String otpCode,
    String subject = 'Mã xác thực PHR',
  }) async {
    try {
      final message = Message()
        ..from = Address(_senderEmail, 'PHR System')
        ..recipients.add(toEmail)
        ..subject = '$subject - $otpCode'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h2 style="color: #00897B;">PHR - Hồ sơ Y tế</h2>
            </div>
            <p>Xin chào,</p>
            <p>Mã xác thực (OTP) của bạn là:</p>
            <div style="text-align: center; margin: 24px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #00897B; background: #E0F2F1; padding: 12px 24px; border-radius: 8px;">$otpCode</span>
            </div>
            <p style="color: #666;">Mã có hiệu lực trong <b>5 phút</b>. Không chia sẻ mã này cho bất kỳ ai.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
            <p style="font-size: 12px; color: #999;">Email này được gửi tự động từ hệ thống PHR. Vui lòng không trả lời.</p>
          </div>
        ''';

      await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send welcome email with account credentials
  Future<bool> sendWelcomeEmail({
    required String toEmail,
    required String defaultPassword,
    String? patientName,
  }) async {
    try {
      final message = Message()
        ..from = Address(_senderEmail, 'PHR System')
        ..recipients.add(toEmail)
        ..subject = 'Chào mừng bạn đến với PHR - Thông tin tài khoản'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h2 style="color: #00897B;">PHR - Hồ sơ Y tế</h2>
            </div>
            <p>Xin chào ${patientName ?? 'bạn'},</p>
            <p>Hồ sơ y tế của bạn đã được tạo trên hệ thống PHR. Dưới đây là thông tin tài khoản để tra cứu hồ sơ:</p>
            <div style="background: #F5F5F5; padding: 16px; border-radius: 8px; margin: 16px 0;">
              <p><b>Email đăng nhập:</b> $toEmail</p>
              <p><b>Mật khẩu mặc định:</b> $defaultPassword</p>
            </div>
            <p style="color: #E65100;"><b>⚠️ Lưu ý:</b> Vui lòng đổi mật khẩu ngay sau lần đăng nhập đầu tiên để bảo mật tài khoản.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;">
            <p style="font-size: 12px; color: #999;">Email này được gửi tự động từ hệ thống PHR.</p>
          </div>
        ''';

      await send(message, _smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}
