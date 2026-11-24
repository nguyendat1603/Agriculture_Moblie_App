# 01. Tầm Nhìn Sản Phẩm & Phân Tích Học Hỏi Từ Plantix (Product Vision & Benchmark)

## 1. Bối cảnh & Bài toán Cốt lõi

Trong một trang trại canh tác mở hiện đại trồng **$N$ luống cây (hoặc $N$ loại cây trồng khác nhau)**, hệ thống thủy lợi thường chỉ sử dụng **một bể phối trộn dinh dưỡng trung tâm (100)** duy nhất kết nối với mạng lưới đường ống chính và các van phân phối (113) dẫn tới từng luống cây (117).

Mỗi loại cây ở từng giai đoạn sinh trưởng lại yêu cầu một cặp thông số dinh dưỡng mục tiêu riêng biệt:
* **$x_{i,t}^{\text{target}}$ (Độ pH):** Quyết định khả năng hòa tan và hấp thụ ion khoáng của bộ rễ.
* **$y_{i,t}^{\text{target}}$ (Độ dẫn điện EC - $\text{mS/cm}$):** Đại diện cho tổng nồng độ muối khoáng dinh dưỡng hòa tan.

### Rào cản của các hệ thống hiện tại:
1. **Cách pha riêng từng luống ($4 \times N$ chu kỳ/ngày):** Bắt buộc đóng/ngắt van định lượng (107–110), sục khuấy và xả rửa đường ống liên tục giữa các lần đổi công thức. Hệ quả là hao mòn phần cứng cơ khí, lãng phí nước sạch xả ống và gây trễ pha thủy lực.
2. **Cách lấy trung bình cộng ngây thơ (Euclidean đối xứng):** Coi việc dư thừa hay thiếu hụt 1 đơn vị EC là như nhau. Trong thực tế sinh học, **thiếu hụt nhẹ** chỉ làm cây chậm lớn tạm thời, nhưng **dư thừa nồng độ quá ngưỡng** (đặc biệt vào buổi trưa nắng gắt) gây áp suất thẩm thấu ngược làm **cháy rễ cấp tính, hoại tử mô tế bào và khóa dinh dưỡng (nutrient lockout)** không thể cứu vãn.

### Giải pháp của Ứng dụng (AgroOT Mobile):
Xây dựng một ứng dụng di động đa nền tảng đóng vai trò là **"Bộ não điều phối dinh dưỡng thông minh"** cho trang trại $N$ loại cây:
* Sử dụng **Mô hình Vận tải tối ưu (Optimal Transport - Generalized Wasserstein Barycenter)** kết hợp **Hàm chi phí tổn thất sinh học bất đối xứng** để tìm ra bộ độ đo dinh dưỡng tổng thể tối ưu $(x^*, y^*)$ thích ứng theo **4 khối giờ sinh học** và **điều kiện thời tiết thực địa**.
* Tự động chuyển sang **Đa tâm động (Wasserstein K-Means)** khi nhu cầu giữa $N$ loại cây phân hóa quá sâu, kết hợp **Hàng đợi thủy lực** và **Bơm bù vi phân** để tái sử dụng 100% dung dịch nền tồn lưu trong đường ống.

---

## 2. Phân tích Học hỏi từ Ứng dụng Plantix (Plantix UX/UI Benchmark)

**Plantix** là ứng dụng nông nghiệp di động thành công bậc nhất thế giới nhờ khả năng biến các kiến thức nông học phức tạp thành giao diện trực quan, dễ hiểu và hành động được ngay ngoài đồng ruộng. Dưới đây là 6 nguyên lý cốt lõi của Plantix được áp dụng trực tiếp vào thiết kế MVP của chúng ta:

| Đặc trưng của Plantix | Cách Plantix thực hiện | Áp dụng vào App Độ đo Dinh dưỡng Tổng thể ($N$ loại cây) |
| :--- | :--- | :--- |
| **1. Visual-First Crop Cards (Trực quan hóa cây trồng)** | Dùng hình ảnh/icon cây trồng rõ nét, màu sắc phân biệt trạng thái sức khỏe thay vì bảng số liệu khô khan. | Mỗi luống cây trong $N$ luống được hiển thị bằng một **Crop Card** sinh động (icon cây trồng, giai đoạn sinh trưởng, nhãn pH & EC mục tiêu, thanh chỉ báo ngưỡng chịu đựng stress). |
| **2. "Doctor Diagnosis" Banner (Thẻ Chẩn đoán & Cảnh báo An toàn)** | Đưa ra kết luận tức thì (Xanh: An toàn / Vàng: Thiếu hụt nhẹ / Đỏ: Nguy hiểm) kèm giải thích ngắn gọn dễ hiểu. | Hiển thị thẻ **"Chẩn đoán An toàn Sinh học Rễ"**: Chỉ rõ tại sao thuật toán chọn $y^* = 1.2\text{ mS/cm}$ thay vì trung bình cộng $1.5\text{ mS/cm}$ (ví dụ: *"Bảo vệ luống Xà lách khỏi nguy cơ cháy rễ dưới nắng trưa"*). |
| **3. Agri-Weather & Bio-Clock Card (Thẻ Thời tiết & Khối giờ)** | Đặt widget thời tiết nông nghiệp ngay đầu màn hình chính để khuyến nghị thời điểm tưới/bón phân. | Tích hợp **Thanh Đồng hồ Sinh học 4 Khối giờ ($t=1..4$)** và **Bộ chọn Vi khí hậu (Ôn hòa / Nắng gắt / Mưa lớn)** ngay đầu Dashboard, tự động cập nhật hệ số phạt $(w_{\text{low},t}, w_{\text{high},t})$. |
| **4. Fertilizer Calculator (Máy tính phối trộn trực quan)** | Nhập diện tích và loại cây $\rightarrow$ Xuất ngay công thức phân bón thành từng bước thực hiện. | Từ nghiệm tối ưu $(x^*, y^*)$ hoặc đa tâm $(x_{j,t}^*, y_{j,t}^*)$, ứng dụng xuất ngay **Lịch đóng/mở van A, B, C, D (107–110)** và **Lượng bơm bù vi phân $(\Delta x, \Delta y)$** rõ ràng theo từng kỳ. |
| **5. Data Density Control (Kiểm soát mật độ dữ liệu)** | Chia thông tin phức tạp thành các thẻ (Cards) gọn gàng, dùng biểu đồ thanh và huy hiệu (Badges) dễ đọc. | Không bắt nông dân đọc công thức đạo hàm/tích phân phức tạp; các thông số toán học $(\mathcal{D}_{\text{bio}}, \alpha_t, k_t)$ được gom vào chế độ **"Chi tiết Kỹ thuật / Chuyên gia"** có thể mở rộng khi cần. |
| **6. High-Contrast Outdoor UI & Offline-First** | Giao diện sáng, chữ to, độ tương phản cao để nhìn rõ dưới ánh nắng mặt trời ngoài ruộng; chạy mượt không cần mạng. | Toàn bộ thuật toán Vận tải tối ưu & Wasserstein K-Means chạy **100% cục bộ (On-device)** trong `< 50ms`, giao diện tương phản cao chuẩn Material 3 / Plantix Green. |

---

## 3. Chân dung Người dùng (User Personas)

### Persona 1: Anh Minh – Chủ trang trại rau thủy canh / tưới nhỏ giọt đa canh (Quy mô $N = 2..15$ luống)
* **Nhu cầu:** Trồng xen canh nhiều loại rau (Xà lách, Cải ngọt, Cà chua, Dưa lưới) dùng chung 1 bể pha phân trung tâm. Muốn biết mỗi sáng, trưa, chiều nên cài đặt máy pha mức pH và EC bao nhiêu để cây nhạy cảm không bị cháy rễ mà cây ăn phân đặc vẫn đủ chất, không phải xả bỏ nước phân cũ trong ống.
* **Trải nghiệm mong muốn trên App:** Mở app thấy ngay Khối giờ hiện tại, chọn thời tiết hôm nay (Nắng gắt hay Mưa), bấm 1 nút là thấy ngay thông số $(x^*, y^*)$ cần pha hoặc lịch pha 2 kỳ cuốn chiếu.

### Persona 2: Bạn Lan – Sinh viên / Kỹ sư Nông nghiệp Công nghệ cao & IoT
* **Nhu cầu:** Nghiên cứu, kiểm thử và trình diễn thuật toán **Vận tải tối ưu (Optimal Transport)** trong tài liệu sáng chế với số lượng luống cây $N$ tùy biến, thay đổi các trọng số $(w_{\text{low}}, w_{\text{high}}, k_t, K_{\text{sunny}}, K_{\text{rainy}})$ và quan sát sự dịch chuyển của tâm hình học $(x^*, y^*)$ trên biểu đồ.
* **Trải nghiệm mong muốn trên App:** Có biểu đồ 2D trực quan đối chiếu giữa **Tâm sinh học Wasserstein** và **Tâm trung bình cộng Euclidean**, xem được bảng tính chi phí tổn thất $\mathcal{D}_{\text{bio}}$ của từng luống và luồng điều khiển phần cứng IoT (112).

---

## 4. Mục tiêu Thành công của bản MVP (Success Metrics)

1. **Độ chính xác Toán học 100%:** Khi chạy bộ dữ liệu mẫu $N=2$ (Xà lách: $\text{pH}=5.8, \text{EC}=1.2$; Cải ngọt: $\text{pH}=6.4, \text{EC}=1.8$), thuật toán phải tái tạo chính xác Kịch bản 1 ($x^* = 6.1, y^* = 1.2\text{ mS/cm}$) và Kịch bản 2 (chia 2 cụm cuốn chiếu + bơm bù vi phân $\Delta x = +0.6, \Delta y = +0.6$) trong tài liệu sáng chế.
2. **Khả năng mở rộng linh hoạt với $N$ loại cây:** Hỗ trợ thêm/sửa/xóa $N$ luống cây bất kỳ ($N$ từ 1 đến 50+ luống), thời gian tính toán tối ưu dưới `50ms` trên thiết bị di động.
3. **Trải nghiệm trực quan chuẩn Plantix:** Người dùng mới có thể hiểu và vận hành toàn bộ quy trình 4 bước của thuật toán chỉ trong vòng 1 phút làm quen.
