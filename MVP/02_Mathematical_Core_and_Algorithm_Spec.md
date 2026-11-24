# 02. Đặc Tả Toán Học & Thuật Toán Cốt Lõi (Mathematical Core & Algorithm Specification)

Tài liệu này chuyển hóa toàn bộ mô hình toán học trong [Tài liệu gửi sinh viên.docx](file:///d:/App_trong_cay/Agriculture_App/T%C3%A0i%20li%E1%BB%87u%20g%E1%BB%ADi%20sinh%20vi%C3%AAn.docx) thành đặc tả kỹ thuật chính xác để lập trình module Core Engine của ứng dụng di động.

---

## 1. Ký hiệu & Biến số Đầu vào (Input Variables & Notations)

### 1.1. Tập hợp $N$ luống cây / loại cây trồng
Trang trại gồm $N$ luống cây biệt lập ($i \in \{1, 2, \dots, N\}$). Tại khối giờ $t$, mỗi luống cây $i$ có vector tham số:
* $x_{i,t}^{\text{target}} \in [4.0, 8.5]$: Chỉ số **độ pH mục tiêu** của luống cây $i$ tại khối giờ $t$.
* $y_{i,t}^{\text{target}} \in [0.2, 5.0]$: Chỉ số **nồng độ dinh dưỡng / độ dẫn điện EC mục tiêu** ($\text{mS/cm}$) của luống cây $i$ tại khối giờ $t$.
* $s_i \in [0.8, 3.0]$: Hệ số nhạy cảm sinh học của giống cây tại luống $i$ (ví dụ: Xà lách thân mềm nhạy cảm cao $s_1 = 2.0$; Cải ngọt chịu đựng tốt hơn $s_2 = 1.0$).
* $A_i > 0$: Diện tích canh tác ($\text{m}^2$) của luống cây thứ $i$ (mặc định $100\text{ m}^2$).
* $p_i \in (0, 1]$ với $\sum_{i=1}^N p_i = 1$: Trọng số chuẩn hóa của luống cây $i$ theo **Chế độ Trọng số Kép (Dual Weighting Mode)**:
  * **Chế độ Mặc định (Đồng đều $1/N$):** $p_i = \frac{1}{N}$ (khớp tuyệt đối với ví dụ kiểm chứng trong tài liệu sáng chế).
  * **Chế độ Nâng cao (Theo Diện tích & Độ nhạy cảm):** $p_i = \frac{A_i \cdot s_i}{\sum_{k=1}^N A_k \cdot s_k}$.

### 1.2. Chu kỳ 4 Khối giờ sinh học ($t \in \{1, 2, 3, 4\}$)
Mỗi ngày canh tác được chia làm 4 khối giờ sinh học với bộ tham số nền $(w_{\text{low},t}^{\text{base}}, w_{\text{high},t}^{\text{base}}, \alpha_t, k_t)$:

| Khối giờ $t$ | Tên khối giờ | Khung giờ | $\alpha_t$ (Trọng số pH) | $w_{\text{low},t}^{\text{base}}$ (Phạt thiếu EC) | $k_t$ (Hệ số phạt cực đoan) | $w_{\text{high},t}^{\text{base}} = k_t \cdot w_{\text{low},t}^{\text{base}}$ | Trạng thái hệ thống |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **$t = 1$** | **Khối 1: Sáng sớm** | 06:00 – 08:00 | $1.0$ | $1.5$ (Tăng nhẹ kích rễ) | $6.0$ | $9.0$ | Hoạt động (Ưu tiên Đơn tâm) |
| **$t = 2$** | **Khối 2: Trưa nắng gắt** | 10:00 – 14:00 | $1.2$ | $0.8$ (Hạ thấp ưu tiên nước) | $15.0$ ($5..20$) | $12.0$ (Mức cực đoan chống cháy rễ) | Hoạt động (Dễ kích hoạt Đa tâm) |
| **$t = 3$** | **Khối 3: Chiều mát** | 15:00 – 17:00 | $1.0$ | $2.5$ (Tăng cao tích lũy khoáng) | $5.0$ | $12.5$ | Hoạt động (Đơn tâm / Đa tâm) |
| **$t = 4$** | **Khối 4: Ban đêm** | Sau 18:00 | $0.0$ | $0.0$ (Đóng hoàn toàn) | $0.0$ | $0.0$ | **Ngắt cấp dịch & Xả sạch ống** |

> [!IMPORTANT]
> **Ràng buộc biên kỹ thuật bắt buộc:** Tại mọi khối giờ hoạt động $t \in \{1, 2, 3\}$, hệ thống luôn đảm bảo:
> $$w_{\text{high},t} \ge k_t \cdot w_{\text{low},t} \quad \text{với } k_t \ge 5$$
> Điều này tạo ra một "hàng rào kỹ thuật ảo" kéo nghiệm $y^*$ về vùng an toàn sinh học, tuyệt đối không để vượt ngưỡng gây cháy rễ.

---

## 2. Tầng 1: Hiệu chỉnh Trọng số Thích ứng Vi khí hậu (Adaptive Climate-Driven Weights)

Trước khi giải bài toán tối ưu tại khối giờ $t \in \{1, 2, 3\}$, bộ trọng số nền $(w_{\text{low},t}^{\text{base}}, w_{\text{high},t}^{\text{base}})$ được hiệu chỉnh động theo dữ liệu thời tiết thực địa:

1. **Kịch bản Nắng gắt / Bức xạ PAR & Thoát hơi nước cao ($K_{\text{sunny}} \ge 1.0$):**
   $$w_{\text{high},t}^{\text{new}} = K_{\text{sunny}} \cdot w_{\text{high},t}^{\text{base}}$$
   * Với thời tiết ôn hòa: $K_{\text{sunny}} = 1.0$.
   * Với thời tiết nắng gắt / bức xạ cao (đặc biệt ở Khối 2): $K_{\text{sunny}} \in [1.5, 3.0]$.

2. **Kịch bản Mưa lớn / Độ ẩm đất cao gây rửa trôi phân ($K_{\text{rainy}} \ge 1.0$):**
   $$w_{\text{low},t}^{\text{new}} = K_{\text{rainy}} \cdot w_{\text{low},t}^{\text{base}}$$
   * Với thời tiết không mưa: $K_{\text{rainy}} = 1.0$.
   * Với thời tiết mưa lớn cục bộ (đặc biệt ở Khối 1 hoặc Khối 3): $K_{\text{rainy}} \in [1.5, 2.5]$, giúp nâng nhẹ nồng độ $y^*$ để bù trừ lượng ion dinh dưỡng bị nước mưa làm loãng mà vẫn giữ nguyên mục tiêu độ pH $x^*$.

3. **Kiểm tra bảo toàn ràng buộc sau hiệu chỉnh:**
   $$w_{\text{high},t} = \max\left(w_{\text{high},t}^{\text{new}}, \, k_t \cdot w_{\text{low},t}^{\text{new}}\right), \quad w_{\text{low},t} = w_{\text{low},t}^{\text{new}}$$

---

## 3. Hàm Chi Phí Tổn Thất Sinh Học Bất Đối Xứng ($\mathcal{D}_{\text{bio}}$)

Khoảng cách toán – sinh học hiệu chỉnh $\mathcal{D}_{\text{bio}}$ từ một điểm cấu hình dung dịch $(x, y)$ tại bể trung tâm (100) đến tọa độ mục tiêu $(x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})$ của luống cây thứ $i$ tại khối giờ $t$ được định nghĩa là:

$$\mathcal{D}_{\text{bio}}\left((x, y) \rightarrow \left(x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}}\right)\right) = \mathcal{L}_{x,t}\left(x, x_{i,t}^{\text{target}}\right) + \mathcal{L}_{y,t}\left(y, y_{i,t}^{\text{target}}\right)$$

Trong đó:
1. **Hàm tổn thất chỉ số pH ($\mathcal{L}_{x,t}$):**
   $$\mathcal{L}_{x,t}\left(x, x_{i,t}^{\text{target}}\right) = \alpha_t \cdot \left(x - x_{i,t}^{\text{target}}\right)^2$$

2. **Hàm tổn thất bất đối xứng chỉ số dẫn điện EC ($\mathcal{L}_{y,t}$):**
   $$\mathcal{L}_{y,t}\left(y, y_{i,t}^{\text{target}}\right) = \begin{cases} w_{\text{low},t} \cdot \left(y_{i,t}^{\text{target}} - y\right) & \text{khi } y \le y_{i,t}^{\text{target}} \text{ (thiếu hụt nồng độ)} \\ w_{\text{high},t} \cdot \left(y - y_{i,t}^{\text{target}}\right) & \text{khi } y > y_{i,t}^{\text{target}} \text{ (dư thừa nồng độ)} \end{cases}$$

---

## 4. Giải Bài Toán Tối Ưu Tâm Hình Học Wasserstein (Single-Barycenter Solver)

### 4.1. Bài toán tối ưu toàn cục
Cho một tập hợp (hoặc một cụm) gồm $N$ luống cây, bộ tham số đặc trưng dinh dưỡng tổng thể $(x^*, y^*)$ là nghiệm của bài toán:

$$(x^*, y^*) = \arg\min_{(x,y)} J_t(x, y) = \arg\min_{(x,y)} \sum_{i=1}^{N} \left[ \mathcal{L}_{x,t}\left(x, x_{i,t}^{\text{target}}\right) + \mathcal{L}_{y,t}\left(y, y_{i,t}^{\text{target}}\right) \right]$$

### 4.2. Nghiệm chính xác và Giải thuật thực thi trên thiết bị
Do hàm mục tiêu $J_t(x, y) = J_{x,t}(x) + J_{y,t}(y)$ phân rã hoàn toàn thành hai hàm lồi độc lập theo biến $x$ và biến $y$:

1. **Tìm chỉ số pH tổng thể tối ưu ($x^*$):**
   Lấy đạo hàm $\frac{\partial J_{x,t}(x)}{\partial x} = 2\alpha_t \sum_{i=1}^N (x - x_{i,t}^{\text{target}}) = 0$, ta thu được nghiệm giải tích duy nhất:
   $$x^* = \frac{1}{N} \sum_{i=1}^{N} x_{i,t}^{\text{target}}$$
   *(Nếu mỗi luống cây có trọng số diện tích/lưu lượng $p_i > 0$ với $\sum_{i=1}^N p_i = 1$, thì $x^* = \sum_{i=1}^N p_i x_{i,t}^{\text{target}}$).*

2. **Tìm chỉ số nồng độ dinh dưỡng EC tổng thể tối ưu ($y^*$):**
   Hàm $J_{y,t}(y) = \sum_{i=1}^N \mathcal{L}_{y,t}(y, y_{i,t}^{\text{target}})$ là hàm lồi tuyến tính từng khúc (Piecewise-Linear Convex Pinball Loss).
   * **Phương pháp 1 – Phân vị mẫu chính xác (Exact Quantile Solution, độ phức tạp $O(N \log N)$):**
     Đặt tỷ lệ phân vị an toàn sinh học:
     $$\tau_t = \frac{w_{\text{low},t}}{w_{\text{low},t} + w_{\text{high},t}} = \frac{1}{1 + (w_{\text{high},t} / w_{\text{low},t})} \le \frac{1}{1 + k_t}$$
     Sắp xếp dãy nồng độ mục tiêu theo thứ tự tăng dần: $y_{(1)} \le y_{(2)} \le \dots \le y_{(N)}$.
     Nghiệm tối ưu $y^*$ chính là giá trị nhỏ nhất $y_{(m)}$ sao cho tổng trọng số tích lũy đạt hoặc vượt $\tau_t$:
     $$m = \min \left\{ r \in \{1, \dots, N\} \;\middle|\; \frac{r}{N} \ge \tau_t \right\} \implies y^* = y_{(m)}$$
     *(Nhận xét: Với $k_t \ge 5 \implies \tau_t \le \frac{1}{6} \approx 0.167$. Khi $N=2$ luống cây như trong ví dụ Xà lách $1.2$ và Cải ngọt $1.8$, ta có $\frac{1}{2} = 0.5 \ge \tau_t \implies m=1 \implies y^* = y_{(1)} = 1.2\text{ mS/cm}$! Nghiệm khớp 100% với tài liệu sáng chế).*
   * **Phương pháp 2 – Tối ưu hóa làm trơn Entropy Sinkhorn / Nelder-Mead (Hỗ trợ trong Engine để mô phỏng hội tụ số):**
     Có thể tùy chọn bật chế độ hội tụ Nelder-Mead hoặc làm trơn Log-Sum-Exp với tham số điều hòa entropy $\varepsilon > 0$ để vẽ quỹ đạo hội tụ trên giao diện.

---

## 5. Tầng 2: Cơ chế Phân Cụm Động & Đa Tâm (Multi-Barycenter Dynamic Tuning)

### 5.1. Điều kiện kích hoạt Đa tâm động (Trigger Condition)
Tại khối giờ $t \in \{1, 2, 3\}$, sau khi tính tâm đơn $(x^*, y^*)$, hệ thống đánh giá xem mô hình đơn tâm có gây thiệt hại quá lớn hay không dựa trên 3 tiêu chí:
1. **Độ lệch tổn thất trung bình hoặc cực đại vượt ngưỡng cho phép:**
   $$\max_{1 \le i \le N} \mathcal{D}_{\text{bio}}\left((x^*, y^*) \rightarrow (x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})\right) > \Theta_{\text{loss}, t}$$
2. **Độ phân hóa nồng độ EC giữa các luống quá sâu:**
   $$\Delta y_{\max} = \max_i y_{i,t}^{\text{target}} - \min_i y_{i,t}^{\text{target}} > \Theta_{\text{spread}, t}$$
   *(Đặc biệt tại Khối 2 trưa nắng gắt hoặc khi $K_{\text{sunny}} > 1$, ngưỡng $\Theta_{\text{spread}, 2} = 0.4\text{ mS/cm}$ được siết chặt; ví dụ Xà lách $1.2$ và Cải ngọt $1.8$ có $\Delta y_{\max} = 0.6 > 0.4 \rightarrow$ tự động từ chối Đơn tâm và kích hoạt Đa tâm động!).*

### 5.2. Thuật toán Phân cụm Wasserstein K-Means (Pha 1 & Pha 2)
Khi kích hoạt Đa tâm động, hệ thống chọn số cụm tối ưu $M_t \in \{2, 3\}$ ($1 < M_t \le \min(3, N)$) và chạy thuật toán lặp **Wasserstein K-Means**:
1. **Khởi tạo (Initialization):** Chọn $M_t$ tâm khởi tạo $\{(x_{j,t}^{(0)}, y_{j,t}^{(0)})\}_{j=1}^{M_t}$ bằng cách chia theo các mốc phân vị của dãy $\{y_{i,t}^{\text{target}}\}$.
2. **Bước Gán cụm (Assignment Step):** Ở vòng lặp $r$, gán mỗi luống cây $i \in \{1, \dots, N\}$ vào cụm $C_j^{(r)}$ có khoảng cách sinh học bất đối xứng $\mathcal{D}_{\text{bio}}$ nhỏ nhất:
   $$c_i^{(r)} = \arg\min_{j \in \{1, \dots, M_t\}} \mathcal{D}_{\text{bio}}\left((x_{j,t}^{(r-1)}, y_{j,t}^{(r-1)}) \rightarrow (x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})\right)$$
3. **Bước Cập nhật Đa tâm (Barycenter Update Step):** Với mỗi cụm $C_j^{(r)}$, giải bài toán Barycenter ở Mục 4 trên tập các luống cây thuộc cụm đó để tìm tâm mới $(x_{j,t}^{(r)}, y_{j,t}^{(r)})$.
4. **Hội tụ:** Lặp lại Bước 2 và Bước 3 cho đến khi phân hoạch các cụm không đổi (thường hội tụ sau $3 - 10$ vòng lặp). Thu được bộ đa tâm $\{(x_{j,t}^*, y_{j,t}^*)\}_{j=1}^{M_t}$.

### 5.3. Lập lịch Hàng đợi Thủy lực & Bơm bù Vi phân (Pha 3 & Bước 4)
Để tối ưu hóa vận hành cơ khí và tái sử dụng 100% dung dịch nền tồn lưu trong đường ống chính:
1. **Sắp xếp Hàng đợi Thủy lực (Hydraulic Queue Ordering):**
   * Sắp xếp $M_t$ cụm theo thứ tự ưu tiên **từ nhóm cây nhạy cảm với nồng độ loãng đến nhóm cây ưa nồng độ đậm đặc**:
     $$y_{1,t}^* \le y_{2,t}^* \le \dots \le y_{M_t, t}^*$$
   * *(Điều này vừa giúp nhóm cây nhạy cảm nhất với stress nhiệt/cháy rễ vào buổi trưa được cấp nước và dinh dưỡng loãng trước tiên, vừa tạo tiền đề cho nồng độ tăng dần để tái sử dụng dung dịch tồn lưu).*

2. **Tính toán Khoảng cách Vận tải Vi phân & Bơm bổ sung (Sequential Differential Mixing):**
   Khi chuyển từ Kỳ phối trộn $j$ có tâm $(x_{j,t}^*, y_{j,t}^*)$ sang Kỳ phối trộn $j+1$ có tâm $(x_{j+1,t}^*, y_{j+1,t}^*)$:
   * Vector chênh lệch vi phân cần điều chỉnh trên nền dung dịch đang lưu trong đường ống trục chính:
     $$\Delta x_{j \rightarrow j+1} = x_{j+1,t}^* - x_{j,t}^*, \quad \Delta y_{j \rightarrow j+1} = y_{j+1,t}^* - y_{j,t}^*$$
   * **Trường hợp 1 ($\Delta y_{j \rightarrow j+1} \ge 0$ – Chuyển từ loãng sang đặc):**
     * **Bỏ qua hoàn toàn bước xả rửa đường ống bằng nước sạch** (Tiết kiệm 100% nước xả ống).
     * Bơm bổ sung trực tiếp lượng phân đậm đặc tương ứng $\Delta y_{j \rightarrow j+1}$ và dung dịch cân bằng pH (Bazơ nếu $\Delta x > 0$, Acid nếu $\Delta x < 0$) qua các van định lượng (107–110) vào dòng chảy đang dịch chuyển.
   * **Trường hợp 2 ($\Delta y_{j \rightarrow j+1} < 0$ – Dung dịch tồn lưu đặc hơn nhu cầu cụm sau):**
     * Nếu đang ở **Khối 2 (Trưa nắng gắt)** hoặc độ vượt ngưỡng quá giới hạn an toàn: **Bắt buộc kích hoạt chu trình xả nhanh đường ống trục chính** bằng nước sạch từ bể trung gian đã lọc (102) về trạng thái trung tính trước khi pha kỳ tiếp theo.

---

## 6. Bộ Kiểm Chứng Chuẩn (Standard Verification Test Cases)

Module thuật toán trong App bắt buộc phải vượt qua 3 Test Cases chuẩn sau:

### Test Case 1: Kịch bản 1 trong Tài liệu ($N=2$, Khối 1 Sáng sớm ôn hòa)
* **Đầu vào:**
  * Luống 1 (Rau xà lách): $x_1 = 5.8, y_1 = 1.2\text{ mS/cm}$.
  * Luống 2 (Rau cải ngọt): $x_2 = 6.4, y_2 = 1.8\text{ mS/cm}$.
  * Khối giờ $t = 1$ (06h–08h), Thời tiết ôn hòa ($K_{\text{sunny}} = 1.0, K_{\text{rainy}} = 1.0$).
* **Kết quả kỳ vọng:**
  * Chế độ vận hành: **Đơn tâm (Single-Barycenter)** – 1 kỳ phối trộn duy nhất.
  * Nghiệm tối ưu: **$x^* = 6.1$**, **$y^* = 1.2\text{ mS/cm}$**.
  * So sánh: Nếu dùng trung bình cộng ($y_{\text{mean}} = 1.5\text{ mS/cm}$), Luống 1 (Xà lách) bị dư thừa $+0.3\text{ mS/cm}$ dẫn đến phạt lệch trên rất nặng (nguy cơ cháy lá/rễ). Nghiệm $y^* = 1.2\text{ mS/cm}$ giúp rủi ro cháy rễ của Xà lách bằng $0$.

### Test Case 2: Kịch bản 2 trong Tài liệu ($N=2$, Khối 2 Trưa nắng gắt)
* **Đầu vào:**
  * Giữ nguyên 2 luống Xà lách $(5.8, 1.2)$ và Cải ngọt $(6.4, 1.8)$.
  * Khối giờ $t = 2$ (10h–14h), Thời tiết nắng gắt ($K_{\text{sunny}} = 2.0, w_{\text{high},2} \gg w_{\text{low},2}$).
* **Kết quả kỳ vọng:**
  * Chế độ vận hành: Tự động từ chối Đơn tâm $\rightarrow$ Kích hoạt **Đa tâm động ($M_2 = 2$ cụm)**.
  * **Kỳ phối trộn 1 (Cụm 1 – Luống Xà lách):** Tâm $(x_{1,2}^* = 5.8, y_{1,2}^* = 1.2\text{ mS/cm})$. Mở van cấp cho luống Xà lách.
  * **Kỳ phối trộn 2 (Cụm 2 – Luống Cải ngọt):** Tâm $(x_{2,2}^* = 6.4, y_{2,2}^* = 1.8\text{ mS/cm})$.
  * **Hành động đường ống:** Không xả rửa nước sạch (Tiết kiệm 100% nước xả ống). Bơm bổ sung vi phân trực tiếp: $\Delta x = +0.6$ (bơm bazơ nâng pH) và $\Delta y = +0.6\text{ mS/cm}$ (bơm dung dịch phân đặc A/B/C) vào dòng tồn lưu $(5.8, 1.2)$.

### Test Case 3: Kịch bản Ban đêm ($N$ bất kỳ, Khối 4 sau 18h)
* **Đầu vào:** Khối giờ $t = 4$ (Ban đêm).
* **Kết quả kỳ vọng:**
  * $w_{\text{low},4} = 0, w_{\text{high},4} = 0$.
  * Hệ thống trả về trạng thái `NIGHT_SHUTDOWN`: Ngắt toàn bộ van định lượng (107–110), xả sạch đường ống chính để chống ngập úng vùng rễ và nấm bệnh.
