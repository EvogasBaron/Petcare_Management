# PetCare - Ứng Dụng Chăm Sóc & Quản Lý Thú Cưng

- **Môn học:** Phát triển ứng dụng trên thiết bị di động
- **Nhóm thực hiện:** Nhóm 17
- **Nền tảng:** Flutter (Android) & Firebase
- **IDE:** Android Studio

---

## 1. Giới thiệu dự án

PetCare là ứng dụng di động hỗ trợ kết nối giữa Chủ nuôi thú cưng, Đối tác phòng khám thú y và Quản trị viên (Admin). Ứng dụng cung cấp các tính năng quản lý hồ sơ sức khỏe thú cưng, đặt lịch khám trực tuyến, nhắc lịch chăm sóc y tế và tìm kiếm phòng khám gần vị trí hiện tại.

### Các vai trò người dùng trong hệ thống
- **Chủ nuôi (Pet Owner):** Quản lý hồ sơ thú cưng, theo dõi biểu đồ cân nặng, cài đặt lịch nhắc tiêm phòng/chăm sóc (ăn, tắm, dạo), tìm phòng khám trên bản đồ, đặt lịch khám theo khung giờ và theo dõi bệnh án điện tử.
- **Đối tác phòng khám (Clinic Partner):** Đăng ký thông tin phòng khám (vị trí, giờ làm việc, sức chứa), quản lý danh mục dịch vụ & bác sĩ, tiếp nhận/xác nhận/hủy lịch hẹn và ghi kết quả khám (chẩn đoán, đơn thuốc, ngày tái khám) trực tiếp vào hồ sơ khám.
- **Quản trị viên (Admin):** Kiểm duyệt phòng khám đối tác (phê duyệt, từ chối), khóa phòng khám vi phạm và quản lý trạng thái tài khoản người dùng.

---

## 2. Công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện | Mục đích sử dụng |
|---|---|---|
| **Môi trường phát triển** | **Android Studio** | Soạn thảo mã nguồn, chạy máy ảo Android (AVD) và đóng gói APK |
| **Framework** | **Flutter** (Dart 3.x) | Phát triển ứng dụng Android, giao diện Material 3 |
| **Quản lý trạng thái** | **Flutter Riverpod** | Quản lý state tập trung |
| **Điều hướng (Routing)** | **GoRouter** | Điều hướng màn hình và chuyển hướng theo vai trò (`user`, `clinic`, `admin`) |
| **Backend & Database** | **Firebase Authentication** | Xác thực người dùng bằng Email/Password |
| | **Cloud Firestore** | Cơ sở dữ liệu NoSQL realtime |
| | **Cloud Storage** | Lưu trữ hình ảnh thú cưng, hồ sơ khám |
| **Bản đồ & Định vị** | **Google Maps Flutter & Geolocator** | Hiển thị vị trí phòng khám và định vị GPS |
| **Thông báo** | **flutter_local_notifications & timezone** | Cài đặt nhắc lịch chăm sóc, lịch tiêm phòng và lịch hẹn khám |
| **Biểu đồ & Tiện ích** | **fl_chart** | Biểu đồ theo dõi cân nặng thú cưng |
| | **image_picker & intl** | Chọn ảnh từ máy và định dạng ngày giờ, tiền tệ |

---

## 3. Hướng dẫn cài đặt và chạy ứng dụng

### Yêu cầu môi trường
- Android Studio (cài đặt plugin Flutter và Dart)
- Flutter SDK (phiên bản >= 3.19.0)
- Java Development Kit (JDK 17)

### Các bước khởi chạy

1. **Mở dự án:**
   Mở Android Studio, chọn `Open` và duyệt đến thư mục dự án `Pet_care`.

2. **Cài đặt dependencies:**
   Mở terminal tại thư mục dự án và chạy:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**
   - Khởi động máy ảo Android (hoặc cắm thiết bị thật có bật USB Debugging).
   - Chọn thiết bị trên thanh công cụ và nhấn `Run` (hoặc phím tắt `Shift + F10`).
   - Lệnh chạy qua terminal:
     ```bash
     flutter run
     ```

4. **Chạy kiểm thử (Tests):**
   ```bash
   flutter test
   ```

5. **Đóng gói file APK:**
   ```bash
   flutter build apk --release
   ```
   File APK sau khi build nằm tại đường dẫn: `build/app/outputs/flutter-apk/app-release.apk`.

---

## 4. Quy tắc nghiệp vụ chính

1. **Phân quyền dữ liệu (Firestore Security Rules):**
   - Người dùng chỉ có quyền đọc/ghi hồ sơ thú cưng, nhật ký, cân nặng do chính mình tạo (`ownerId == auth.uid`).
   - Phòng khám chỉ quản lý danh mục dịch vụ, bác sĩ và lịch hẹn thuộc phòng khám của mình.
   - Admin kiểm duyệt phòng khám và quản lý tài khoản người dùng.
2. **Quản lý lịch khám:**
   - Hệ thống chia thời gian khám thành các khung giờ 30 phút. Mỗi khung giờ có giới hạn số lượng đặt khám (`slotCapacity`).
   - Sử dụng Firestore Transaction để tránh trùng lịch khi nhiều người cùng đặt một khung giờ.
   - Hủy lịch hẹn: Cho phép hủy lịch đang chờ xác nhận bất kỳ lúc nào; lịch đã xác nhận chỉ được phép hủy trước giờ hẹn tối thiểu 2 giờ.
3. **Cơ chế khóa phòng khám:**
   - Khi Admin khóa phòng khám, hệ thống tự động cập nhật hủy các lịch hẹn đang chờ và đã xác nhận của phòng khám đó.

---

## 5. Phân công trách nhiệm thành viên (Nhóm 17)

| Thành viên | Nhiệm vụ thực hiện |
|---|---|
| **Đặng Nguyễn Hoàng Thạch** | - Module Tài khoản: Đăng ký, đăng nhập, quên mật khẩu, hồ sơ cá nhân, khóa tài khoản<br>- Module Hồ sơ thú cưng và biểu đồ theo dõi cân nặng<br>- Lịch tiêm phòng, tẩy giun<br>- Hệ thống thông báo nhắc lịch chăm sóc<br>- Nhật ký triệu chứng và theo dõi sức khỏe |
| **Huỳnh Quang Minh Quân** | - Module Tìm kiếm phòng khám qua Google Maps và GPS<br>- Chi tiết phòng khám, danh mục dịch vụ và đội ngũ bác sĩ<br>- Module Đặt lịch khám và xử lý chống trùng slot khám<br>- Lắng nghe realtime trạng thái lịch hẹn<br>- Cấu hình và đóng gói APK Release |
| **Tuấn** | - Module Đối tác phòng khám: Đăng ký thông tin, quản lý lịch hẹn, dịch vụ, bác sĩ, ghi kết quả khám<br>- Module Quản trị viên (Admin): Duyệt/từ chối/khóa phòng khám, quản lý người dùng<br>- Thiết kế cấu trúc Firestore, Indexes và Security Rules<br>- Quản lý cấu hình Firebase (Auth, Firestore, Storage) |
