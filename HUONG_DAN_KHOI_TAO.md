# PetCare: hướng dẫn khởi tạo dự án (Tuần 1, Ngày 1 và 2)

Bộ khung đi kèm gồm: cấu trúc thư mục, theme, router chuyển hướng theo vai trò, model dùng chung (AppUser, Clinic, Appointment), widget ba trạng thái, Security Rules, index Firestore và test. Mã nguồn chưa được biên dịch trong môi trường soạn (không có Flutter SDK), nên bước 8 (`flutter analyze`, `flutter test`) là bước kiểm tra đầu tiên.

## 0. Chuẩn bị

- Flutter SDK, Android Studio (cài plugin Flutter và Dart), Node.js (để cài Firebase CLI).
- Một tài khoản Google dùng chung cho dự án Firebase.
- Một thẻ thanh toán để bật gói Blaze của Firebase. Từ 30/10/2024 Cloud Storage for Firebase yêu cầu gói Blaze (theo tài liệu của Firebase), mà PetCare dùng Storage để lưu ảnh thú cưng, nhật ký và phòng khám. Gói Blaze vẫn có hạn mức miễn phí; nên đặt cảnh báo ngân sách (Budget alert) trong Google Cloud Billing ngay khi bật.
- Google Maps Platform cũng yêu cầu dự án Google Cloud có bật thanh toán. Dự án Firebase chính là một dự án Google Cloud, nên dùng chung một dự án và một tài khoản thanh toán cho cả hai.

## 1. Phân công Ngày 1 và Ngày 2

| Việc | Người làm |
|---|---|
| Tạo repo Git, chạy `flutter create`, thêm thư viện, đẩy bộ khung lên nhánh main (bước 2 đến 4) | Thạch |
| Tạo dự án Firebase, bật Authentication, Firestore, Storage, đưa Rules và index lên (bước 5), tạo tài khoản Admin | Tuấn |
| Tạo Google Maps API key, lấy SHA-1 của cả ba máy, cấu hình Android (bước 6 và 7) | Quân |
| Ngày 2: cả nhóm đọc và chỉnh core, chạy `flutter analyze`, `flutter test`, chốt model dùng chung | Cả nhóm |

## 2. Tạo repo và dự án Flutter

```bash
git clone <url-repo> petcare && cd petcare
flutter create --org com.petcare --project-name petcare --platforms=android .
```

Tên dự án là `petcare` (các import trong bộ khung dùng `package:petcare/...`). Nếu bạn đặt tên khác, thay chuỗi này trong thư mục `test/`.

## 3. Thêm thư viện

```bash
flutter pub add flutter_riverpod go_router
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub add google_maps_flutter geolocator
flutter pub add flutter_local_notifications timezone shared_preferences
flutter pub add image_picker cached_network_image fl_chart intl
flutter pub add flutter_localizations --sdk=flutter
```

Phiên bản do `pub` tự chọn. Bộ khung chỉ dùng phần API của Riverpod có ở cả bản 2 và bản 3 (Provider, StreamProvider, `when`, `isLoading`, `hasError`).

## 4. Chép bộ khung vào dự án

1. Chép thư mục `lib/` và `test/` của gói này đè lên thư mục tương ứng của dự án (thay `lib/main.dart`).
2. Xóa `test/widget_test.dart` do `flutter create` sinh ra, vì nó tham chiếu `MyApp` đã không còn.
3. Chép `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `storage.rules` vào thư mục gốc dự án.
4. Thêm nội dung `gitignore_bo_sung.txt` vào cuối `.gitignore`.
5. Commit và đẩy lên: `feat: khởi tạo cấu trúc dự án, core, router, rules`.

Lúc này `lib/main.dart` còn báo lỗi thiếu `firebase_options.dart`; file đó được tạo ở bước 5.

## 5. Firebase (Tuấn)

1. Vào console.firebase.google.com, tạo dự án mới. Nâng lên gói Blaze và đặt cảnh báo ngân sách.
2. Authentication: Sign-in method, bật Email/Password.
3. Firestore Database: tạo cơ sở dữ liệu ở chế độ production, chọn vùng gần Việt Nam (ví dụ asia-southeast1). Vùng không đổi được sau khi tạo.
4. Storage: bật Cloud Storage (chọn cùng vùng).
5. Cài công cụ và liên kết dự án:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=<project-id> --platforms=android
```

Lệnh cuối tạo `lib/firebase_options.dart` và `android/app/google-services.json`. Hai file này chứa định danh dự án, không phải mật khẩu; bảo vệ dữ liệu là việc của Security Rules. Nên commit để cả nhóm dùng chung. Nếu giảng viên yêu cầu không đưa lên repo, để ngoài Git và gửi riêng cho từng người.

6. Đưa Rules và index lên:

```bash
firebase use <project-id>
firebase deploy --only firestore:rules,firestore:indexes,storage
```

7. Mời hai thành viên còn lại vào dự án (Project settings, Users and permissions).
8. Tạo tài khoản Admin: Authentication, Users, Add user; sao chép UID. Rồi Firestore, collection `users`, thêm tài liệu có id là UID đó với các trường: `role` = `admin`, `name`, `email`, `isLocked` = `false` (kiểu boolean), `createdAt` (kiểu timestamp). Rules không cho đăng ký tự nhận role admin, nên bước này chỉ làm tay trong console.

## 6. Google Maps API key (Quân)

1. Trong Google Cloud Console (cùng dự án với Firebase), bật Maps SDK for Android.
2. Tạo API key. Trong phần hạn chế: Application restrictions chọn Android apps, thêm package name `com.petcare.petcare` kèm SHA-1; API restrictions chọn Maps SDK for Android.
3. Lấy SHA-1 debug của từng máy, rồi thêm tất cả vào key:

```bash
cd android
./gradlew signingReport          # Windows: gradlew signingReport
```

Tìm dòng SHA1 của biến thể `debug`. Mỗi máy có SHA-1 debug riêng nên phải thêm cả ba. Bản release (tuần 4) có SHA-1 khác và cũng phải thêm.

4. Đặt key vào `android/local.properties` (file này đã nằm trong `.gitignore`, mỗi người tự thêm vào máy mình, không commit):

```
MAPS_API_KEY=<key của nhóm>
```

## 7. Cấu hình Android (Quân)

`android/app/build.gradle.kts`: thêm dòng import ở đầu file, và đặt placeholder trong `defaultConfig`.

```kotlin
import java.util.Properties

val localProperties = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    defaultConfig {
        manifestPlaceholders["MAPS_API_KEY"] = localProperties.getProperty("MAPS_API_KEY") ?: ""
    }
}
```

Nếu dự án dùng `build.gradle` (Groovy):

```groovy
def localProperties = new Properties()
def f = rootProject.file('local.properties')
if (f.exists()) f.withInputStream { localProperties.load(it) }

android {
    defaultConfig {
        manifestPlaceholders = [MAPS_API_KEY: localProperties.getProperty('MAPS_API_KEY', '')]
    }
}
```

`android/app/src/main/AndroidManifest.xml`: thêm quyền (ngoài thẻ `<application>`) và khóa bản đồ (trong thẻ `<application>`):

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application ...>
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}"/>
    ...
</application>
```

Nếu lúc build Gradle báo `minSdkVersion` thấp hơn mức yêu cầu của một thư viện Firebase, nâng `minSdk` trong `defaultConfig` lên mức mà thông báo lỗi nêu.

Cấu hình riêng cho thông báo (khử đường cú pháp Java, quyền khởi động lại máy, báo thức) làm ở Tuần 2 theo README của `flutter_local_notifications`, do Thạch phụ trách.

## 8. Kiểm tra

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

- `flutter test` chạy các test cho điều hướng theo vai trò (chủ nuôi, đối tác theo từng trạng thái phòng khám, Admin, tài khoản bị khóa), quy tắc hủy lịch 2 giờ và định dạng id khung giờ.
- `flutter run`: app mở màn hình tải rồi vào `/login` (màn hình tạm). Chưa có form đăng nhập, nên chưa thử được đăng nhập bằng tay trước khi Thạch xong phần Auth (Ngày 3). Nếu `flutter analyze` hoặc `flutter test` báo lỗi biên dịch, gửi nguyên văn lỗi để sửa.

## 9. Cách các thành viên dùng bộ khung

- Mỗi route trong `lib/core/router/app_router.dart` đang trỏ tới `PlaceholderScreen`. Khi làm xong màn hình thật, thay builder của route thuộc feature của mình (thông báo cả nhóm vì cùng sửa một file; nên tách mỗi người một khối route nếu muốn tránh xung đột merge).
- Mọi màn hình dùng dữ liệu bất đồng bộ nên bọc bằng `AsyncValueView` (đủ ba trạng thái: đang tải, rỗng, lỗi có nút thử lại).
- Repository bắt lỗi Firebase và ném lại bằng `AppException.fromFirebase(e)`; UI hiển thị `AppException.messageOf(e)`.
- Khi tạo tài liệu mới dùng `toMap()` của model; khi sửa, chỉ gửi các trường thay đổi (Rules giới hạn trường được sửa).
- Thay đổi model và hằng số trong `core/` phải báo cả nhóm.

## 10. Checklist hoàn thành khởi tạo (cuối Ngày 2)

- [ ] Repo Git có nhánh main chạy được và quy ước nhánh feature/<tên>
- [ ] Dự án Firebase đã bật Auth, Firestore, Storage; Blaze và cảnh báo ngân sách đã đặt
- [ ] `firebase_options.dart` và `google-services.json` đã có trong repo
- [ ] Rules và index đã đưa lên Firebase
- [ ] Tài khoản Admin đã tạo (Authentication và tài liệu `users`)
- [ ] Maps API key đã hạn chế theo package name và SHA-1 của cả ba máy; không có key trong mã nguồn
- [ ] `flutter analyze` và `flutter test` không lỗi
- [ ] Cả ba máy đều chạy được `flutter run`
