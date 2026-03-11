
## ⚙ Cấu hình Môi trường (.env)

Dự án này sử dụng biến môi trường (Environment Variables) để bảo mật thông tin như mật khẩu Email, API keys, v.v.

**Quy tắc:**
1. **Tuyệt đối KHÔNG ĐẨY (push) file `.env` lên GitHub**. File này đã được đưa vào `.gitignore`.
2. **Cách setup ban đầu cho mỗi người**:
   - Khi clone project về, bạn sẽ thấy file `.env.example`.
   - Mở Terminal tại thư mục project, tạo file `.env` từ file mẫu:
     - Trên Windows/Mac/Linux: Hãy sao chép file `.env.example` và đổi tên bản sao thành `.env`.
   - Mở file `.env` vừa tạo và điền các giá trị thực tế (VD: `SMTP_PASSWORD`) do team leader cung cấp.

---

## 🛠 Hướng dẫn làm việc nhóm (Workflow Rules)

Để hai bạn code không bị dẫm chân lên nhau, tuyệt đối tuân thủ Git Flow sau:

1. **Không code chung trên một nhánh `main` hay `develop`**
2. **Luồng nhánh (Branching):**
   - **`main`**: Code phiên bản chuẩn nhất, không lỗi.
   - **`dev`**: Nhánh dùng để ghép code của cả 2 bạn để test chung.
   - Khi làm chức năng nào, hãy rẽ nhánh (branch) ra từ nhánh `dev`.
     * Tên nhánh cho Dev 1: `feature/dev1-[tên-chức-năng]` (VD: `feature/dev1-login-remember`)
     * Tên nhánh cho Dev 2: `feature/dev2-[tên-chức-năng]` (VD: `feature/dev2-medical-tags`)

3. **Quy trình khi Pull và Push:**
   - **Trước khi code**: Mở Terminal gõ `git pull origin develop` để lấy code mới nhất về.
   - Bắt đầu tạo branch: `git checkout -b feature/ten-tinh-nang`
   - **Sau khi code xong**:
     ```bash
     git add .
     git commit -m "Thêm tính năng filter tài liệu y tế"
     git checkout dev
     git pull origin dev     <-- RẤT QUAN TRỌNG: Lấy code thằng kia vừa đẩy lên về trước
     git merge feature/ten-tinh-nang
     git push origin dev
     ```

4. **Xử lý Conflict (Xung đột):**
   - Sự phân chia trên đã cố gắng tách màn hình để giảm thiểu conflict tối đa (Dev1 lo màn Profile & Dashboard / Dev2 lo màn Document).
   - Tuy nhiên, nếu hai người có sửa chung các tệp cấu hình (như `pubspec.yaml`, `route.dart`, `app_colors.dart`), thì khi báo chữ CONFLICT lúc merge, hãy bình tĩnh mở file đó ra, họp bàn cùng người kia và quyết định giữ đoạn code nào rồi mới PUSH.
