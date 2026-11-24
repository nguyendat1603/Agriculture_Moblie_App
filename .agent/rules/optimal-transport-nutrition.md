# Quy tắc Toán - Sinh học & Thuật toán Vận tải Tối ưu (Optimal Transport Nutrition Rules)

Mọi mã nguồn tính toán độ đo dinh dưỡng tổng thể trong dự án này **BẮT BUỘC** phải tuân thủ nghiêm ngặt các nguyên lý toán học và an toàn sinh học được quy định trong tài liệu sáng chế [Tài liệu gửi sinh viên.docx](file:///d:/App_trong_cay/Agriculture_App/T%C3%A0i%20li%E1%BB%87u%20g%E1%BB%ADi%20sinh%20vi%C3%AAn.docx):

## 1. Cấm sử dụng Trung bình cộng đối xứng làm kết quả điều khiển chính
* Không bao giờ dùng trung bình cộng Euclidean đơn thuần $\bar{y} = \frac{1}{N}\sum_{i=1}^N y_{i,t}^{\text{target}}$ để điều khiển nồng độ dinh dưỡng EC ($y$), vì sai lệch dương (dư thừa phân bón gây cháy rễ, ngộ độc chất tan) nguy hiểm gấp nhiều lần sai lệch âm (thiếu hụt nhẹ trong ngắn hạn).
* Trung bình cộng Euclidean chỉ được tính để làm **mốc đối chiếu (Baseline Comparison)** trên giao diện nhằm chứng minh tính ưu việt của thuật toán Vận tải tối ưu.

## 2. Hàm Khoảng cách Toán - Sinh học Bất đối xứng ($\mathcal{D}_{\text{bio}}$)
* Khoảng cách từ cấu hình bể phối trộn $(x, y)$ đến luống cây $i \in \{1..N\}$ tại khối giờ $t$ luôn được phân rã đại số:
  $$\mathcal{D}_{\text{bio}}\left((x, y) \rightarrow (x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})\right) = \mathcal{L}_{x,t}(x, x_{i,t}^{\text{target}}) + \mathcal{L}_{y,t}(y, y_{i,t}^{\text{target}})$$
* Với độ pH ($x$): $\mathcal{L}_{x,t}(x, x_{i,t}^{\text{target}}) = \alpha_t \cdot (x - x_{i,t}^{\text{target}})^2$.
* Với độ dẫn điện EC ($y$):
  * Khi $y \le y_{i,t}^{\text{target}}$ (thiếu hụt): $\mathcal{L}_{y,t} = w_{\text{low},t} \cdot (y_{i,t}^{\text{target}} - y)$.
  * Khi $y > y_{i,t}^{\text{target}}$ (dư thừa): $\mathcal{L}_{y,t} = w_{\text{high},t} \cdot (y - y_{i,t}^{\text{target}})$.

## 3. Ràng buộc Hàng rào Kỹ thuật Bảo vệ Rễ
* Tại mọi khối giờ hoạt động $t \in \{1, 2, 3\}$, luôn đảm bảo bất đẳng thức:
  $$w_{\text{high},t} \ge k_t \cdot w_{\text{low},t} \quad (k_t \ge 5, \text{ riêng Khối 2: } k_2 \in [5, 20])$$
* Khi thời tiết nắng gắt ($K_{\text{sunny}} > 1$): nhân hệ số phạt lệch trên $w_{\text{high},t}^{\text{new}} = K_{\text{sunny}} \cdot w_{\text{high},t}$.
* Khi thời tiết mưa lớn ($K_{\text{rainy}} > 1$): nhân hệ số phạt lệch dưới $w_{\text{low},t}^{\text{new}} = K_{\text{rainy}} \cdot w_{\text{low},t}$, nhưng giữ nguyên mục tiêu độ pH ($x^*$).

## 4. Quy tắc Bất biến của 4 Khối giờ Sinh học
* **Khối 1 ($t=1$, 06h–08h - Sáng sớm):** Tăng nhẹ $w_{\text{low},1}$ để kích hoạt bộ rễ đầu ngày.
* **Khối 2 ($t=2$, 10h–14h - Trưa nắng gắt):** Đẩy $w_{\text{high},2}$ lên mức cực đoan, hạ $w_{\text{low},2}$ để kéo $y^*$ về vùng loãng an toàn, chống cháy rễ cấp tính.
* **Khối 3 ($t=3$, 15h–17h - Chiều mát):** Đẩy $w_{\text{low},3}$ lên cao để tối ưu tích lũy khoáng chất trước tối.
* **Khối 4 ($t=4$, Sau 18h - Ban đêm):** **BẮT BUỘC** đưa $(w_{\text{low},4} = 0, w_{\text{high},4} = 0)$, ngắt toàn bộ quá trình phối trộn và xả sạch đường ống chính để chống ngập úng rễ và nấm bệnh.

## 5. Quy tắc Đa tâm động, Trọng số Kép & Định lượng 4 Van Thủy canh (107–110)
* **Chế độ Trọng số Kép (Dual Weighting Mode):**
  * Mặc định dùng trọng số đồng đều $p_i = 1/N$ để khớp tuyệt đối ví dụ tài liệu sáng chế.
  * Cho phép người dùng bật tùy chọn tính trọng số theo diện tích luống ($\text{m}^2$) và độ nhạy cảm giống cây ($s_i$): $p_i = \frac{A_i \cdot s_i}{\sum_{k=1}^N A_k \cdot s_k}$.
* **Chế độ Điều phối Đơn tâm / Đa tâm (Auto-Detect & Manual Override):**
  * Khi độ phân hóa nhu cầu giữa $N$ luống cây vượt ngưỡng an toàn (đặc biệt ở Khối 2), hệ thống tự động chuyển từ **Đơn tâm** sang **Đa tâm động (Wasserstein K-Means)** với $M_t \in \{2, 3\}$ cụm.
  * Giao diện vẫn cho phép người dùng gạt chọn thủ công giữa **Đơn tâm** hoặc chọn số cụm **$M_t \in \{2, 3, 4\}$** để đối chiếu.
* **Hàng đợi Thủy lực & Tái sử dụng Dung dịch nền Đường ống:**
  * Hàng đợi thủy lực ưu tiên cấp từ cụm nồng độ loãng (nhạy cảm cao) đến cụm nồng độ đặc: $y_{1,t}^* \le y_{2,t}^* \le \dots \le y_{M_t,t}^*$.
  * Khi chuyển từ Kỳ $j$ sang Kỳ $j+1$:
    * Nếu $y_{j+1,t}^* \ge y_{j,t}^*$: **Không xả rửa đường ống**, tính khoảng cách vận tải vi phân $(\Delta x, \Delta y)$ để bơm bổ sung trực tiếp vào dòng chảy tồn lưu.
    * Nếu $y_{j+1,t}^* < y_{j,t}^*$ (đặc biệt ở Khối 2): **Bắt buộc kích hoạt xả nhanh đường ống bằng nước sạch từ bể 102** trước khi pha kỳ tiếp theo.
* **Quy ước Định lượng 4 Bể A, B, C, D (`103–106`) & 4 Van (`107–110`):**
  * **Bể A (`103` - Van `107`) & Bể B (`104` - Van `108`):** Dung dịch phân dinh dưỡng gốc A & B giúp tăng nồng độ EC ($\Delta y > 0$).
  * **Bể C (`105` - Van `109`):** Dung dịch Acid ($\text{pH Down}$) giúp hạ độ pH ($\Delta x < 0$).
  * **Bể D (`106` - Van `110`):** Dung dịch Bazơ ($\text{pH Up}$) giúp nâng độ pH ($\Delta x > 0$).
  * Từ $(\Delta x, \Delta y)$ và thể tích bể `100` ($V_{\text{tank}}$), luôn tính rõ thể tích cần bơm ($\text{mL}$) và thời gian mở từng van ($t_{\text{open}}$ giây).
