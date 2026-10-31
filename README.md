# 🐾 PetCare - Ứng Dụng Chăm Sóc & Quản Lý Thú Cưng

> **Đồ án tốt nghiệp / Đồ án chuyên ngành Công nghệ Thông tin**  
> **Nhóm thực hiện:** Nhóm 17  
> **Nền tảng:** Flutter (Android Mobile) & Google Firebase  
> **Môi trường phát triển chính:** Android Studio

---

## 📌 1. Giới thiệu dự án

**PetCare** là giải pháp di động toàn diện kết nối **Chủ nuôi thú cưng**, **Đối tác phòng khám thú y** và **Quản trị viên (Admin)** trên cùng một hệ sinh thái đồng nhất. Ứng dụng giúp số hóa toàn bộ quá trình theo dõi sức khỏe thú cưng, tự động hóa nhắc nhở chăm sóc y tế, tìm kiếm phòng khám quanh vị trí GPS và đặt lịch khám bệnh trực tuyến chống trùng giờ.

### Các vai trò người dùng trong hệ thống:
* **Chủ nuôi (Pet Owner):** Quản lý hồ sơ thú cưng, theo dõi biểu đồ cân nặng, cài đặt lịch nhắc tiêm phòng/chăm sóc (ăn, tắm, dạo), tìm phòng khám trên Google Maps, đặt lịch khám theo khung giờ và tra cứu bệnh án điện tử.
* **Đối tác phòng khám (Clinic Partner):** Đăng ký hồ sơ phòng khám (tọa độ GPS, giờ làm việc, sức chứa), quản lý danh mục dịch vụ & bác sĩ, tiếp nhận/xác nhận/hủy lịch hẹn và ghi kết quả khám (chẩn đoán, đơn thuốc, ngày tái khám) trực tiếp vào hồ sơ khám của thú cưng.
* **Quản trị viên (Admin):** Kiểm duyệt phòng khám đối tác (phê duyệt, từ chối kèm lý do), khóa phòng khám vi phạm (tự động kích hoạt hủy các lịch hẹn đang chờ/đã xác nhận) và quản lý khóa/mở tài khoản người dùng.

---

## 🚀 2. Công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện | Mục đích sử dụng |
|---|---|---|
| **IDE chính** | **Android Studio** | Soạn thảo mã nguồn, chạy giả lập Android (AVD), gỡ lỗi và đóng gói APK |
| **Framework** | **Flutter** (Dart 3.x) | Phát triển ứng dụng di động Android đa nền tảng, giao diện Material 3 chuẩn hóa |
| **State Management** | **Flutter Riverpod** | Quản lý trạng thái phân tán, phản ứng nhanh (reactive), dễ viết Unit/Widget Test |
| **Định tuyến (Routing)** | **GoRouter** | Điều hướng tập trung, tự động chuyển trang theo vai trò (`user`, `clinic`, `admin`) và trạng thái duyệt phòng khám |
| **Backend & Database** | **Firebase Authentication** | Xác thực người dùng qua Email/Mật khẩu an toàn |
| | **Cloud Firestore** | Cơ sở dữ liệu NoSQL realtime, lưu trữ dữ liệu phân tán |
| | **Cloud Storage** | Lưu trữ ảnh đại diện, ảnh thú cưng, ảnh nhật ký sức khỏe |
| **Bản đồ & Định vị** | **Google Maps Flutter & Geolocator** | Hiển thị vị trí phòng khám trên bản đồ, tính khoảng cách thực tế từ GPS của người dùng |
| **Thông báo cục bộ** | **flutter_local_notifications & timezone** | Báo thức nhắc lịch ăn/tắm/dạo định kỳ, nhắc tiêm phòng lúc 08:00 trước 1 ngày, nhắc trước giờ khám 1 giờ |
| **Biểu đồ & Tiện ích** | **fl_chart** | Vẽ biểu đồ biến thiên cân nặng của thú cưng theo thời gian |
| | **image_picker & intl** | Chụp ảnh từ camera/thư viện và định dạng tiền tệ (VNĐ), ngày giờ Việt Nam |

---

## 📂 3. Cấu trúc thư mục dự án (Feature-First Architecture)

Mã nguồn được tổ chức theo kiến trúc **Feature-First** (tách biệt theo từng tính năng nghiệp vụ), phân tầng rõ ràng giữa **Data (Model, Repository)**, **Providers (State)** và **Presentation (Screens, Widgets)**:

```text
lib/
├── app.dart                             # MaterialApp cấu hình theme, router, locale vi_VN
├── main.dart                            # Điểm khởi chạy ứng dụng, nạp Firebase & Date formatting
├── firebase_options.dart                # Cấu hình định danh dự án Firebase (Android)
├── core/                                # Các thành phần lõi dùng chung
│   ├── constants/                       # Hằng số toàn hệ thống, Roles, Statuses
│   ├── errors/                          # AppException bắt lỗi Firebase và dịch sang tiếng Việt
│   ├── models/                          # Các Entity dùng chung: AppUser, Clinic, Appointment
│   ├── providers/                       # Riverpod providers phiên đăng nhập & phân quyền
│   ├── router/                          # GoRouter điều hướng tập trung theo vai trò
│   ├── services/                        # NotificationService (local notif), StorageService
│   ├── theme/                           # AppTheme Material 3 tông màu chủ đạo Teal
│   └── widgets/                         # State views (Loading, Empty, Error), AppAvatar, BottomNav
└── features/                            # Các module nghiệp vụ
    ├── auth/                            # Đăng nhập, Đăng ký (chọn vai trò), Quên mật khẩu, Cá nhân, Khóa
    ├── pets/                            # CRUD thú cưng, theo dõi cân nặng & biểu đồ fl_chart
    ├── vaccination/                     # Lịch tiêm phòng, tẩy giun, tự tạo mũi nhắc tiếp theo
    ├── reminders/                       # Nhắc lịch chăm sóc hàng ngày (cho ăn, tắm, đi dạo)
    ├── health_log/                      # Nhật ký triệu chứng kèm ảnh chụp
    ├── clinics/                         # Tìm phòng khám (Danh sách + Google Maps GPS), chi tiết dịch vụ & bác sĩ
    ├── appointments/                    # Đặt lịch hẹn (Firestore Transaction chống trùng slot 30p), quản lý lịch
    ├── clinic_admin/                    # Dành cho phòng khám: Thiết lập hồ sơ, Dashboard lịch hẹn, dịch vụ, bác sĩ, ghi bệnh án
    └── admin/                           # Dành cho Admin: Phê duyệt/từ chối/khóa phòng khám, quản lý người dùng
```

---

## 🛠️ 4. Hướng dẫn Mở & Chạy ứng dụng trên Android Studio

### Yêu cầu môi trường:
* **Android Studio:** Phiên bản Flamingo, Hedgehog, Iguana hoặc mới nhất.
* **Flutter SDK:** Phiên bản `>= 3.19.0` (đã cài đặt tại `D:\flutter`).
* **Java Development Kit (JDK):** JDK 17 (được cấu hình sẵn trong Android Studio).

---

### Bước 1: Mở dự án trong Android Studio
1. Khởi động **Android Studio**.
2. Trên màn hình chào mừng (Welcome Screen), chọn **Open** (hoặc vào menu **File > Open...**).
3. Dẫn tới thư mục dự án:  
   👉 `D:\Downloads\UIT\Mobile\AndroidStudioProjects\Pet_care`
4. Bấm **OK** và chọn **Trust Project** để Android Studio nạp dự án.

---

### Bước 2: Cài đặt Plugin Flutter & Dart (Nếu chưa cài)
1. Trong Android Studio, vào **File > Settings** (phím tắt `Ctrl + Alt + S`).
2. Chọn mục **Plugins** ở cột bên trái.
3. Ở tab **Marketplace**, tìm từ khóa:
   * **Flutter** -> Bấm **Install**.
   * **Dart** -> Bấm **Install** (thường sẽ được tự động cài kèm khi cài Flutter).
4. Bấm **OK** và chọn **Restart IDE** để khởi động lại Android Studio.

---

### Bước 3: Đồng bộ gói thư viện (Pub Get)
1. Trong cửa sổ **Project** bên trái, mở file `pubspec.yaml`.
2. Phía trên đầu file `pubspec.yaml`, Android Studio sẽ hiện một dải thanh màu vàng có nút:
   👉 **`Pub get`** (ở góc trên bên phải thanh soạn thảo).
3. Bấm vào chữ **`Pub get`** để Android Studio tự động tải về toàn bộ các gói phụ thuộc.

---

### Bước 4: Khởi động máy ảo Android (Device Manager / Emulator)
1. Trên thanh công cụ trên cùng của Android Studio, bấm vào biểu tượng điện thoại **Device Manager** (hoặc mở tab **Running Devices** ở thanh bên phải).
2. Bạn sẽ thấy máy ảo **`Pixel 8`** đã được cấu hình sẵn.
3. Bấm vào nút **Play (▶ tam giác)** ở dòng `Pixel 8` để khởi động máy ảo Android.
*(Nếu dùng điện thoại thật: Cắm cáp USB vào máy tính, bật "Gỡ lỗi USB" trên điện thoại, Android Studio sẽ tự động nhận diện thiết bị ở ô chọn thiết bị).*

---

### Bước 5: Chạy ứng dụng (Run App)
1. Trên thanh công cụ chính (trên cùng):
   * Ô chọn thiết bị: Chọn máy ảo **`Pixel 8`** (hoặc điện thoại thật của bạn).
   * Ô chọn cấu hình: Đảm bảo đang chọn file **`main.dart`** (nằm tại `lib/main.dart`).
2. Bấm vào nút **Run (tam giác màu xanh lá ▶)** hoặc nhấn phím tắt:  
   👉 **`Shift + F10`** (để chạy Debug: **`Shift + F9`**).
3. Ứng dụng sẽ được biên dịch và tự động cài đặt lên máy ảo Pixel 8.
4. **Tính năng Hot Reload:** Khi đang chạy, bạn sửa code và chỉ cần bấm nút **Tia sét màu vàng ⚡** (hoặc phím tắt `Ctrl + \`) để cập nhật giao diện ngay lập tức mà không cần khởi động lại app!

---

### Bước 6: Chạy kiểm thử tự động (Unit & Widget Tests)
Ngay trong Android Studio, bạn có thể chạy toàn bộ các bài kiểm thử:
1. Trong cây thư mục `Project`, tìm đến thư mục **`test/`**.
2. **Nhấp chuột phải vào thư mục `test/`** -> Chọn **`Run 'All Tests'`** (phím tắt `Ctrl + Shift + F10`).
3. Cửa sổ **Run/Test** dưới đáy Android Studio sẽ hiển thị toàn bộ **14 bài test đều đạt tích xanh (Pass 100%)**.

---

### Bước 7: Đóng gói file cài đặt APK (Release Build)
Khi cần nộp bài đồ án hoặc gửi file cài đặt cho giảng viên/thành viên khác:
1. Mở tab **Terminal** ở góc dưới cùng của Android Studio (phím tắt `Alt + F12`).
2. Gõ lệnh đóng gói:
   ```powershell
   flutter build apk --release
   ```
3. File cài đặt APK sẽ được tạo ra tại:  
   👉 `build\app\outputs\flutter-apk\app-release.apk`

---

## 🔒 5. Quy tắc nghiệp vụ & Bảo mật cốt lõi (Business Rules)

1. **Phân quyền đa tầng (Firestore Security Rules):**
   * Người dùng chỉ có quyền đọc/ghi thú cưng, nhật ký, cân nặng do chính mình sở hữu (`ownerId == auth.uid`).
   * Khi cập nhật hồ sơ cá nhân, người dùng chỉ được phép sửa 3 trường: `name`, `phone`, `avatarUrl`.
   * Phòng khám chỉ được quản lý dịch vụ, bác sĩ và lịch hẹn thuộc phòng khám của mình.
   * Admin có toàn quyền kiểm duyệt và quản trị người dùng.
2. **Chống trùng lịch khám bằng Firestore Transaction:**
   * Hệ thống chia thời gian thành các khung giờ 30 phút (`yyyyMMdd_HHmm`). Mỗi khung giờ giới hạn tối đa `slotCapacity` lượt đặt.
   * Khi người dùng đặt lịch, Firestore Transaction sẽ kiểm tra số lượng `booked`. Nếu đủ chỗ mới tăng `booked` và tạo lịch; nếu vừa hết chỗ sẽ trả về `SlotFullException`.
3. **Quy tắc hủy lịch khám:**
   * Lịch ở trạng thái **Chờ xác nhận (pending)** có thể hủy bất cứ lúc nào.
   * Lịch ở trạng thái **Đã xác nhận (confirmed)** chỉ được phép hủy trước giờ hẹn ít nhất **2 giờ**.
   * Khi hủy lịch, số lượng `booked` của khung giờ đó sẽ tự động được hoàn lại.
4. **Cơ chế khóa phòng khám an toàn:**
   * Khi Admin khóa một phòng khám vi phạm, hệ thống sử dụng **WriteBatch** tự động hủy tất cả các lịch hẹn đang chờ và đã xác nhận của phòng khám đó với lý do: *"Phòng khám bị khóa"*, người hủy: *"system"*.

---

## 👥 6. Phân công trách nhiệm thành viên (Nhóm 17)

| Thành viên | Trách nhiệm chính |
|---|---|
| **Đặng Nguyễn Hoàng Thạch** (TV1) | • Phân hệ Tài khoản (Đăng ký, Đăng nhập, Quên mật khẩu, Profile, Khóa tài khoản)<br>• Phân hệ Hồ sơ thú cưng & Biểu đồ cân nặng (`fl_chart`)<br>• Lịch tiêm phòng, tẩy giun & tự động tạo mũi nhắc<br>• Nhắc lịch chăm sóc hàng ngày (`flutter_local_notifications`)<br>• Nhật ký triệu chứng & Tab bệnh án/lịch sử khám bệnh |
| **Huỳnh Quang Minh Quân** (TV2) | • Phân hệ Tìm phòng khám trên bản đồ Google Maps & Danh sách lọc theo GPS<br>• Màn hình chi tiết phòng khám, bảng giá dịch vụ & đội ngũ bác sĩ<br>• Phân hệ Đặt lịch khám (Firestore Transaction chống trùng slot 30 phút)<br>• Lắng nghe realtime và bắn thông báo đổi trạng thái lịch hẹn<br>• Đóng gói APK Release & cấu hình Signing Keystore Android |
| **Tuấn** (TV3) | • Phân hệ Đối tác phòng khám: Đăng ký hồ sơ, Dashboard quản lý lịch hẹn, dịch vụ, bác sĩ, ghi kết quả khám<br>• Phân hệ Quản trị viên (Admin): Duyệt/từ chối/khóa phòng khám, quản lý người dùng<br>• Thiết kế kiến trúc Firestore Schema, Composite Indexes & Security Rules<br>• Quản trị dự án Firebase (Authentication, Firestore, Storage) |

---

## 📄 7. Giấy phép & Bản quyền

Dự án được xây dựng phục vụ mục đích học tập và bảo vệ đồ án tốt nghiệp. Mọi quyền sở hữu trí tuệ thuộc về các thành viên Nhóm 17.
