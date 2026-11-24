# 05. Tổng Hợp Quyết Định Thiết Kế Đã Chốt & Đặc Tả Chi Tiết Bổ Sung (Confirmed Product Decisions)

Tài liệu này ghi nhận toàn bộ **7 quyết định thiết kế cốt lõi** đã được chốt cho bản MVP của ứng dụng di động **AgroOT (Plantix-Inspired Farm Nutrition Mobile App)** và quy định chi tiết cách thức hiện thực hóa từng quyết định trong mã nguồn.

---

## 1. Bảng Tổng Hợp 7 Quyết Định Đã Chốt

| STT | Hạng mục Thiết kế | Quyết định đã chốt cho bản MVP |
| :-: | :--- | :--- |
| **1** | **Nền tảng & Công nghệ (Tech Stack)** | **Flutter (Dart)** – Đa nền tảng (Android, iOS, Web, Desktop), sử dụng `CustomPainter` / Canvas hiệu năng cao để vẽ biểu đồ tọa độ 2D $(\text{pH}, \text{EC})$ và sơ đồ bể phối trộn trung tâm `100` + hệ thống van `107–113`. |
| **2** | **Mô phỏng Phần cứng IoT (112) & Thời tiết (114)** | **Bộ mô phỏng tương tác trực tiếp trên App (Interactive Simulator)**: Cho phép chọn 4 Khối giờ sinh học ($t=1..4$), điều chỉnh kịch bản Thời tiết ($K_{\text{sunny}}, K_{\text{rainy}}$) và mô phỏng trạng thái tức thời của bể phối trộn trung tâm `100` cùng đầu đo `119`. |
| **3** | **Quy ước 4 Bể A, B, C, D (103–106) & Van (107–110)** | **Chuẩn thủy canh thực tế kèm tính toán định lượng ($\text{mL}$ & giây mở van):**<br>• **Bể A (103) - Van 107:** Phân dinh dưỡng gốc A (Calcium Nitrate + Fe) $\rightarrow$ Tăng EC ($y$).<br>• **Bể B (104) - Van 108:** Phân dinh dưỡng gốc B (P, K, Mg, S + Vi lượng) $\rightarrow$ Tăng EC ($y$).<br>• **Bể C (105) - Van 109:** Dung dịch Acid ($\text{pH Down}$) $\rightarrow$ Hạ độ pH ($x$).<br>• **Bể D (106) - Van 110:** Dung dịch Bazơ ($\text{pH Up}$) $\rightarrow$ Nâng độ pH ($x$). |
| **4** | **Trọng số $N$ Luống cây trong bài toán Vận tải tối ưu** | **Hỗ trợ chế độ Kép (Dual Weighting Mode):**<br>• **Chế độ Mặc định (Đồng đều $1/N$):** Mọi luống cây có trọng số $p_i = 1/N$ để khớp 100% số liệu ví dụ trong tài liệu sáng chế.<br>• **Chế độ Nâng cao (Theo Diện tích & Độ nhạy cảm):** Tính trọng số $p_i$ dựa trên diện tích canh tác ($\text{m}^2$) và hệ số nhạy cảm sinh học $s_i$ của từng giống cây. |
| **5** | **Chuyển đổi Đơn tâm vs. Đa tâm động (Wasserstein K-Means)** | **Tự động phát hiện (Auto-Detect) kết hợp Tùy chọn Thủ công (Manual Override):**<br>• Mặc định hệ thống tự động chuyển sang Đa tâm khi độ phân hóa vượt ngưỡng sinh học.<br>• Người dùng có thể gạt nút ép chạy **Đơn tâm** hoặc chọn số cụm **$M_t \in \{2, 3, 4\}$** để trực tiếp so sánh chi phí tổn thất $\mathcal{D}_{\text{bio}}$. |
| **6** | **Tính năng Phong cách Plantix** | **Thư viện Cây trồng chuẩn (Plantix Crop Library) theo 4 Giai đoạn Sinh trưởng:**<br>Mỗi loại cây có bộ thông số $(x^{\text{target}}, y^{\text{target}}, s_i)$ chuẩn nông học ứng với 4 giai đoạn: *1. Cây con (Kiến thiết cơ bản)* $\rightarrow$ *2. Sinh trưởng thân lá* $\rightarrow$ *3. Ra hoa* $\rightarrow$ *4. Nuôi quả / Thu hoạch*. |
| **7** | **Lưu trữ Dữ liệu & Tài khoản Trang trại** | **Hybrid Offline-First + Cloud Database Sync (Supabase / Firebase) & Màn hình Đăng nhập:**<br>• Hỗ trợ màn hình Đăng nhập / Đăng ký tài khoản trang trại và đồng bộ cấu hình $N$ luống cây lên Cloud.<br>• Luôn có bộ nhớ cục bộ (Local Storage) và chế độ **"Dùng ngay / Nạp kịch bản mẫu Offline"** để không bao giờ bị gián đoạn khi mất mạng. |

---

## 2. Đặc Tả Công Thức Định Lượng 4 Van A, B, C, D (107–110)

Khi hệ thống xác định được cấu hình mục tiêu $(x^*, y^*)$ (trong chế độ Đơn tâm hoặc Kỳ 1 của Đa tâm) hoặc vector chênh lệch vi phân $(\Delta x, \Delta y)$ (trong các kỳ tiếp theo của chế độ Đa tâm tái sử dụng dung dịch nền), bộ điều khiển IoT `112` tính toán lượng bơm cho 4 van định lượng `107, 108, 109, 110` như sau:

### 2.1. Thông số cấu hình Bể trung tâm (100) và Hệ thống Van (107–110)
* $V_{\text{tank}}$ (Lít): Thể tích dung dịch xử lý tại bể phối trộn trung tâm `100` (hoặc thể tích dòng chảy trong ống chính khi bơm bù vi phân, mặc định $V_{\text{tank}} = 500\text{ L}$, cho phép người dùng chỉnh trên App).
* $(x_{\text{base}}, y_{\text{base}})$: Độ pH và nồng độ EC của nguồn nước trung gian đã lọc từ bể `102` (mặc định nước lọc trung tính: $x_{\text{base}} = 7.0\text{ pH}$, $y_{\text{base}} = 0.10\text{ mS/cm}$), hoặc của dung dịch nền tồn lưu trong đường ống chính từ kỳ trước $(x_{j-1,t}^*, y_{j-1,t}^*)$.
* $Q_{\text{valve}}$ ($\text{mL/s}$): Lưu lượng định mức của van điện từ định lượng `107–110` khi mở $100\%$ (mặc định $Q_{\text{valve}} = 25\text{ mL/s}$).
* Hệ số quy đổi thực nghiệm chuẩn thủy canh:
  * $C_{AB} = 2.0\text{ mL / Lít / } 1.0\text{ mS/cm}$ (Cần $2\text{ mL}$ dung dịch gốc A và $2\text{ mL}$ dung dịch gốc B cho mỗi Lít nước để tăng $1.0\text{ mS/cm}$ độ dẫn điện EC).
  * $C_{\text{acid}} = 0.5\text{ mL / Lít / } 1.0\text{ đơn vị pH}$ (Lượng dung dịch Acid từ bể C `105` để hạ $1.0$ độ pH trên $1\text{ Lít}$ nước).
  * $C_{\text{base}} = 0.5\text{ mL / Lít / } 1.0\text{ đơn vị pH}$ (Lượng dung dịch Bazơ từ bể D `106` để nâng $1.0$ độ pH trên $1\text{ Lít}$ nước).

### 2.2. Công thức tính Thể tích bơm ($\text{mL}$) và Thời gian mở van ($t_{\text{open}}$ giây)
Đặt độ chênh lệch cần điều chỉnh so với nền hiện tại:
$$\Delta y = y_{\text{target}}^{*} - y_{\text{current}}, \quad \Delta x = x_{\text{target}}^{*} - x_{\text{current}}$$

1. **Van 107 (Bể A - 103) & Van 108 (Bể B - 104) – Điều chỉnh Nồng độ EC ($\Delta y$):**
   * Nếu $\Delta y > 0$ (Cần tăng nồng độ dinh dưỡng EC):
     $$V_A = V_B = \Delta y \cdot V_{\text{tank}} \cdot C_{AB} \quad (\text{mL})$$
     $$t_{\text{open}, 107} = t_{\text{open}, 108} = \frac{V_A}{Q_{\text{valve}}} \quad (\text{giây})$$
   * Nếu $\Delta y \le 0$: $V_A = V_B = 0\text{ mL}$ (Van `107` và `108` đóng; nếu $\Delta y < 0$ ở Khối 2 thì mở van nước sạch từ bể `102` để xả/pha loãng đường ống).

2. **Van 109 (Bể C - 105: Acid / pH Down) – Khi cần hạ độ pH ($\Delta x < 0$):**
   * Nếu $\Delta x < 0$:
     $$V_C = |\Delta x| \cdot V_{\text{tank}} \cdot C_{\text{acid}} \quad (\text{mL}), \quad t_{\text{open}, 109} = \frac{V_C}{Q_{\text{valve}}} \quad (\text{giây})$$
   * Nếu $\Delta x \ge 0$: $V_C = 0\text{ mL}$, $t_{\text{open}, 109} = 0\text{ s}$ (Van `109` đóng).

3. **Van 110 (Bể D - 106: Bazơ / pH Up) – Khi cần nâng độ pH ($\Delta x > 0$):**
   * Nếu $\Delta x > 0$:
     $$V_D = \Delta x \cdot V_{\text{tank}} \cdot C_{\text{base}} \quad (\text{mL}), \quad t_{\text{open}, 110} = \frac{V_D}{Q_{\text{valve}}} \quad (\text{giây})$$
   * Nếu $\Delta x \le 0$: $V_D = 0\text{ mL}$, $t_{\text{open}, 110} = 0\text{ s}$ (Van `110` đóng).

---

## 3. Đặc Tả Thư Viện Cây Trồng Theo 4 Giai Đoạn Sinh Trưởng (Plantix Crop Library)

Dưới đây là bảng thông số chuẩn nông học được tích hợp sẵn vào **Plantix Crop Library** của ứng dụng. Khi người dùng chọn một loại cây và chuyển đổi giữa **4 giai đoạn sinh trưởng**, ứng dụng tự động điền bộ thông số $(x^{\text{target}}, y^{\text{target}}, s_i)$ (và vẫn cho phép tinh chỉnh thủ công nếu muốn):

| Loại cây trồng | Icon | GĐ 1: Cây con (Kiến thiết) `(pH, EC)` | GĐ 2: Sinh trưởng thân lá `(pH, EC)` | GĐ 3: Ra hoa `(pH, EC)` | GĐ 4: Nuôi quả / Thu hoạch `(pH, EC)` | Độ nhạy cảm $s_i$ | Đặc tính sinh học (Plantix Note) |
| :--- | :-: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Rau Xà Lách** *(Mẫu Sáng chế 117_1)* | 🥬 | `(5.8, 0.8)` | **`(5.8, 1.2)`** | `(6.0, 1.3)` | `(6.0, 1.1)` | **2.0 (Cao)** | Thân mềm, cực kỳ nhạy cảm với muối khoáng cao; EC > 1.4 dưới nắng gắt gây cháy chóp lá và thối rễ ngay. |
| **Rau Cải Ngọt** *(Mẫu Sáng chế 117_2)* | 🌿 | `(6.2, 1.2)` | **`(6.4, 1.8)`** | `(6.4, 2.0)` | `(6.3, 1.6)` | **1.0 (Thấp)** | Cần dinh dưỡng đậm đặc để phát triển bẹ và lá lớn; chịu đựng nồng độ khoáng tốt. |
| **Cà Chua** | 🍅 | `(6.0, 1.2)` | `(6.0, 2.0)` | `(6.2, 2.5)` | `(6.3, 3.0)` | **1.4 (TB)** | Giai đoạn ra hoa và nuôi quả cần Kali/EC rất cao, dễ lệch lớn so với nhóm rau ăn lá. |
| **Dâu Tây** | 🍓 | `(5.6, 0.8)` | `(5.8, 1.1)` | `(5.8, 1.4)` | `(5.9, 1.6)` | **2.2 (Rất cao)** | Bộ rễ cực kỳ nhạy cảm với độ dẫn điện EC cao và nhiệt độ trưa; ưu tiên cấp đầu hàng đợi thủy lực. |
| **Dưa Lưới** | 🍈 | `(6.0, 1.2)` | `(6.1, 1.8)` | `(6.3, 2.2)` | `(6.5, 2.6)` | **1.3 (TB)** | Tăng mạnh nhu cầu EC ở giai đoạn tạo lưới và tích đường nuôi quả. |
| **Ớt Chuông** | 🫑 | `(5.8, 1.3)` | `(6.0, 1.8)` | `(6.2, 2.2)` | `(6.2, 2.5)` | **1.5 (TB-Cao)** | Cần pH ổn định quanh 5.8–6.2 để hấp thụ Canxi, chống thối đáy quả. |
| **Dưa Chuột (Dưa Leo)** | 🥒 | `(5.6, 1.1)` | `(5.8, 1.6)` | `(5.9, 2.0)` | `(6.0, 2.2)` | **1.6 (Cao)** | Bốc thoát hơi nước rất lớn vào buổi trưa (Khối 2), cần hạ thấp EC trưa để hút nước. |
| **Rau Muống / Rau Dền** | 🌱 | `(6.0, 1.2)` | `(6.3, 1.9)` | `(6.4, 2.1)` | `(6.3, 1.8)` | **0.9 (Thấp)** | Sức chống chịu cao, ưa đạm và khoáng đậm đặc ở giai đoạn phát triển thân lá. |

---

## 4. Đặc Tả Chế Độ Trọng Số Kép (Dual Weighting Mode)

Trong thuật toán tìm tâm hình học Wasserstein $(x^*, y^*)$, mỗi luống cây $i \in \{1..N\}$ được gán một trọng số xác suất chuẩn hóa $p_i > 0$ sao cho $\sum_{i=1}^N p_i = 1$:

1. **Chế độ 1 – Trọng số Đồng đều (Equal Weights – Mặc định):**
   $$p_i = \frac{1}{N} \quad \forall i \in \{1, \dots, N\}$$
   * Dùng làm chế độ mặc định để khi người dùng chạy kịch bản mẫu trong tài liệu ($N=2$: Xà lách & Cải ngọt), kết quả ra chính xác tuyệt đối $x^* = 6.10$, $y^* = 1.20\text{ mS/cm}$.

2. **Chế độ 2 – Trọng số theo Diện tích & Độ nhạy cảm Sinh học (Area & Sensitivity Weighted):**
   * Khi người dùng gạt công tắc **"Tính trọng số theo Diện tích ($\text{m}^2$) & Độ nhạy cảm ($s_i$)"**:
     $$p_i = \frac{A_i \cdot s_i}{\sum_{k=1}^{N} A_k \cdot s_k}$$
   * Khi đó:
     * Độ pH tổng thể tối ưu là trung bình có trọng số: $x^* = \sum_{i=1}^N p_i \cdot x_{i,t}^{\text{target}}$.
     * Nồng độ EC tổng thể tối ưu $y^*$ là phân vị có trọng số ứng với ngưỡng $\tau_t = \frac{w_{\text{low},t}}{w_{\text{low},t} + w_{\text{high},t}}$: Sắp xếp $y_{(1)} \le y_{(2)} \le \dots \le y_{(N)}$ và chọn $y_{(m)}$ đầu tiên thỏa mãn $\sum_{r=1}^m p_{(r)} \ge \tau_t$.

---

## 5. Đặc Tả Chế Độ Chọn Đơn Tâm / Đa Tâm Động (Auto-Detect & Manual Override)

Trên thanh điều khiển thuật toán của App, người dùng có bộ chọn 3 chế độ điều phối:
1. **`AUTO` (Tự động thông minh theo tài liệu sáng chế – Mặc định):**
   * Hệ thống tự động kiểm tra độ phân hóa $\Delta y_{\max} = \max_i y_i - \min_i y_i$ và mức tổn thất $\mathcal{D}_{\text{bio}}$ tại khối giờ $t$:
     * Nếu nằm trong ngưỡng an toàn (như Khối 1 sáng sớm ôn hòa): Chạy **Đơn tâm (Single-Barycenter)**.
     * Nếu vượt ngưỡng phân hóa (như Khối 2 trưa nắng gắt hoặc khi trang trại trồng cả Dâu tây $1.1$ lẫn Cà chua nuôi quả $3.0$): Tự động kích hoạt **Đa tâm động (Wasserstein K-Means)** với số cụm tối ưu $M_t \in \{2, 3\}$.
2. **`FORCE_SINGLE` (Ép chạy Đơn tâm toàn cục):**
   * Luôn gom toàn bộ $N$ luống về 1 tâm duy nhất $(x^*, y^*)$ để người dùng quan sát mức tổn thất sinh học $\mathcal{D}_{\text{bio}}$ tăng lên thế nào khi nhu cầu cây phân hóa quá xa.
3. **`FORCE_MULTI (M = 2, 3, 4)` (Chủ động chọn số cụm Wasserstein K-Means):**
   * Cho phép người dùng chọn trực tiếp số cụm $M_t \in \{2, 3, 4\}$ (với $M_t \le N$) để xem cách thuật toán phân nhóm cây trồng, lập hàng đợi thủy lực và tính lượng bơm bù vi phân $(\Delta x, \Delta y)$ qua $M_t$ kỳ cuốn chiếu.

---

## 6. Đặc Tả Lưu Trữ Cục Bộ & Đồng Bộ Đám Mây (Offline-First + Cloud Sync & Auth)

Ứng dụng Flutter được thiết kế theo mô hình **Hybrid Local + Cloud Repository**:
1. **Tầng Lưu trữ Cục bộ (Offline-First Local Storage):**
   * Lưu toàn bộ cấu hình trang trại, danh sách $N$ luống cây, lịch sử chạy tối ưu và cấu hình bể phối trộn trung tâm `100` ngay trên thiết bị (`SharedPreferences` / local JSON store).
   * Đảm bảo ứng dụng mở lên là chạy ngay lập tức ngoài cánh đồng không có Internet.
2. **Tầng Tài khoản & Đồng bộ Đám mây (Cloud Auth & Database Sync – Supabase / Firebase):**
   * Có màn hình **Đăng nhập / Đăng ký Tài khoản Trang trại** (Email/Password hoặc chế độ **Khách / Demo Nhanh 1 chạm**) và nút **Đồng bộ Cloud (Giải pháp đám mây 114)**.
   * Khi cấu hình URL & Key của Supabase (hoặc dùng Cloud Sync Service trong App), danh sách $N$ luống cây và lịch cung cấp dinh dưỡng theo khối giờ (tham số mục tiêu `118`) được đồng bộ hai chiều giữa thiết bị di động và đám mây `114`.
