# Bộ Tài Liệu Đặc Tả MVP (Minimum Viable Product)
## Dự án: Ứng dụng Di động Điều phối Dinh dưỡng Trang trại Thông minh (AgroOT - Plantix-Inspired Mobile App)

Bộ tài liệu này định nghĩa toàn diện sản phẩm MVP cho ứng dụng di động đa nền tảng giúp tính toán, trực quan hóa và điều phối **Độ đo dinh dưỡng tổng thể $(x^*, y^*)$** cho trang trại có $N$ loại cây trồng/luống cây, dựa trên tài liệu sáng chế:
> *"Phương pháp xác định độ đo dinh dưỡng tổng thể thích ứng theo khối giờ sinh học và thời tiết cho hệ thống cung cấp dinh dưỡng tự động cho cây trồng tại cánh đồng mở sử dụng mô hình toán học Vận tải tối ưu"* ([Tài liệu gửi sinh viên.docx](file:///d:/App_trong_cay/Agriculture_App/T%C3%A0i%20li%E1%BB%87u%20g%E1%BB%ADi%20sinh%20vi%C3%AAn.docx))

Đồng thời, trải nghiệm người dùng (UX/UI) được thiết kế lấy cảm hứng trực tiếp từ ứng dụng nông nghiệp hàng đầu thế giới **Plantix** ("Bác sĩ cây trồng & Trợ lý dinh dưỡng số").

---

## Danh mục Tài liệu trong thư mục `MVP/`

1. **[01_Product_Vision_and_Plantix_Benchmark.md](./01_Product_Vision_and_Plantix_Benchmark.md)**
   * Tầm nhìn sản phẩm, bài toán thực tế tại trang trại đa canh $N$ luống cây.
   * Phân tích học hỏi từ **Plantix** (Visual-First UI, Thẻ chẩn đoán trực quan, Máy tính dinh dưỡng, Cảnh báo thời tiết nông nghiệp) và cách kết hợp với thuật toán Vận tải tối ưu (Optimal Transport).
   * Chân dung người dùng (User Personas) & Giá trị cốt lõi.

2. **[02_Mathematical_Core_and_Algorithm_Spec.md](./02_Mathematical_Core_and_Algorithm_Spec.md)**
   * Đặc tả toán học chi tiết của thuật toán: Hàm tổn thất sinh học bất đối xứng $\mathcal{D}_{\text{bio}}$, 4 Khối giờ sinh học ($t=1..4$).
   * Mô hình **Đơn tâm (Single-Barycenter)** và **Đa tâm động 2 tầng (Multi-Barycenter Dynamic Tuning)**: Trọng số thích ứng vi khí hậu ($K_{\text{sunny}}, K_{\text{rainy}}$), Phân cụm **Wasserstein K-Means**, **Hàng đợi thủy lực** và **Bơm bù vi phân tái sử dụng dung dịch nền** $(\Delta x, \Delta y)$.
   * Mã giả (Pseudocode) sẵn sàng lập trình và Bộ Test Cases chuẩn kiểm chứng theo tài liệu sáng chế ($N=2$: Xà lách & Cải ngọt; $N$ tổng quát).

3. **[03_Features_and_UX_UI_Design_Spec.md](./03_Features_and_UX_UI_Design_Spec.md)**
   * Danh sách tính năng MVP (MoSCoW Prioritization: Must-have, Should-have, Could-have).
   * Thiết kế chi tiết 4 màn hình chính của Mobile App theo phong cách Plantix.
   * Hệ thống thiết kế (Design System): Bảng màu nông nghiệp độ tương phản cao ngoài trời, Typography, Thẻ cảnh báo cháy rễ (Root Safety Badge) và Sơ đồ mô phỏng bể phối trộn IoT (100) + hệ thống van (107–113).

4. **[04_Technical_Architecture_and_Roadmap.md](./04_Technical_Architecture_and_Roadmap.md)**
   * Kiến trúc phần mềm Mobile đa nền tảng bằng **Flutter (Dart)** (Clean Architecture tách biệt tầng lõi thuật toán `domain/algorithm`, tầng dữ liệu Hybrid Offline + Cloud Sync `data`, và tầng giao diện `presentation`).
   * Thiết kế Data Models / Schemas cho Luống cây (kèm 4 giai đoạn sinh trưởng), Khối giờ, Thời tiết, Định lượng 4 van A/B/C/D (`107–110`) và Kết quả tối ưu.
   * Lộ trình phát triển theo từng lát cắt dọc (Vertical Slices) và Tiêu chí nghiệm thu (Definition of Done).

5. **[05_Confirmed_Product_Decisions_and_Specs.md](./05_Confirmed_Product_Decisions_and_Specs.md)**
   * **Tổng hợp 7 quyết định thiết kế đã chốt với người dùng:**
     1. Framework phát triển: **Flutter (Dart)** đa nền tảng.
     2. Tích hợp IoT & Thời tiết: **Bộ mô phỏng tương tác trực quan (Interactive Simulator)** cho bể trung tâm `100`, 4 khối giờ và vi khí hậu.
     3. Quy ước 4 bể A, B, C, D (`103–106`) & 4 van (`107–110`): **Chuẩn thủy canh thực tế** (A & B tăng EC, C là Acid hạ pH, D là Bazơ nâng pH) kèm công thức tính $\text{mL}$ và thời gian mở van (giây).
     4. Trọng số $N$ luống cây: **Chế độ Kép** (Mặc định đồng đều $1/N$ khớp ví dụ sáng chế + Tùy chọn bật trọng số theo diện tích $\text{m}^2$ & độ nhạy cảm $s_i$).
     5. Điều khiển Đơn tâm / Đa tâm: **Auto-Detect thông minh** + cho phép bật/tắt thủ công hoặc chọn số cụm $M_t \in \{2..4\}$ để so sánh.
     6. Tính năng Plantix: **Thư viện Cây trồng chuẩn (Plantix Crop Library)** với thông số $(\text{pH}, \text{EC})$ tự động theo **4 giai đoạn sinh trưởng** (Cây con, Sinh trưởng lá, Ra hoa, Nuôi quả).
     7. Lưu trữ & Tài khoản: **Kết hợp lưu cục bộ (Offline-first) và đồng bộ Cloud Database (Supabase / Firebase)** kèm màn hình Đăng nhập tài khoản trang trại (hỗ trợ cả chế độ Demo nhanh).
