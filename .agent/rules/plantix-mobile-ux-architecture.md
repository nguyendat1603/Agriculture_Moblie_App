# Quy tắc Kiến trúc Mobile App & Trải nghiệm Người dùng Phong cách Plantix

## 1. Công nghệ Flutter & Kiến trúc Tách lớp (Clean Architecture)
* **Framework chính thức:** **Flutter (Dart)** hỗ trợ đa nền tảng (Android, iOS, Web, Desktop).
* **Tách biệt tuyệt đối 3 tầng (`lib/domain/`, `lib/data/`, `lib/presentation/`):**
  * Các hàm tính toán Vận tải tối ưu, Wasserstein K-Means, Lập lịch thủy lực và Định lượng van A/B/C/D trong `lib/domain/` không được phụ thuộc vào bất kỳ thư viện UI nào.
  * Mọi thay đổi trên danh sách $N$ luống cây, Giai đoạn sinh trưởng, Khối giờ ($t=1..4$) hoặc Thời tiết đều phải tính toán lại kết quả tức thời trên thiết bị (Offline-first, thời gian phản hồi `< 50ms`).
* **Lưu trữ Cục bộ + Đồng bộ Cloud (Supabase / Firebase) & Đăng nhập:**
  * Hỗ trợ màn hình Đăng nhập tài khoản trang trại và đồng bộ cấu hình $N$ luống cây lên đám mây (`114`), đồng thời luôn có lưu trữ cục bộ (`SharedPreferences` / local JSON) và nút vào nhanh chế độ Demo/Offline.

## 2. Nguyên tắc Thiết kế Giao diện lấy cảm hứng từ Plantix
1. **Visual-First & Card-Based Layout:**
   * Mỗi luống cây trong $N$ luống được trình bày dưới dạng thẻ trực quan (Crop Card) có biểu tượng cây trồng, giai đoạn sinh trưởng, thông số mục tiêu $(x_i^{\text{target}}, y_i^{\text{target}})$ và huy hiệu chẩn đoán trạng thái rễ.
2. **Thẻ Chẩn đoán "Bác sĩ Cây trồng" (Actionable Diagnostic Banner):**
   * Mọi kết quả toán học $(x^*, y^*)$ đều phải đi kèm lời giải thích nông học rõ ràng bằng tiếng Việt tự nhiên (ví dụ: chỉ rõ luống cây nào đang được bảo vệ khỏi nguy cơ cháy rễ, tiết kiệm được bao nhiêu % nước xả rửa đường ống).
3. **Độ tương phản cao ngoài trời (Outdoor High-Contrast UI):**
   * Sử dụng tông màu nông nghiệp rõ nét: Xanh lá đậm (`#1B5E20` / `#2E7D32`), Xanh ngọc Barycenter (`#00897B`), Xanh dương thủy lực (`#0288D1`), Vàng cảnh báo thiếu hụt nhẹ (`#F57F17`), Đỏ cảnh báo cháy rễ (`#C62828`).
4. **Sơ đồ Phần cứng Đánh số Chuẩn Sáng chế:**
   * Khi mô phỏng hệ thống vật lý trên giao diện, sử dụng đúng ký hiệu đánh số của tài liệu sáng chế:
     * `100`: Bể phối trộn dinh dưỡng trung tâm
     * `101`: Bể nước sơ cấp chưa lọc | `102`: Bể nước trung gian đã lọc | `122`: Hệ lọc
     * `103–106`: Bể dung dịch thành phần A, B, C, D
     * `107–110`: Van định lượng thành phần A, B, C, D
     * `112`: Phần cứng điều khiển IoT | `114`: Giải pháp đám mây
     * `113`: Cụm van phân phối dinh dưỡng | `117` (`117_1..117_N`): $N$ luống cây trồng
     * `119`: Hệ thống đầu đo pH/EC tức thời
