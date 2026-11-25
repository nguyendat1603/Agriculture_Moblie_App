# Khung Cấu Trúc Dự Án Flutter Đa Nền Tảng (Project Skeleton)

Dự án **AgroOT Mobile App** được tổ chức theo kiến trúc **Clean Architecture 3 Lớp (`domain`, `data`, `presentation`) + `core`**, tuân thủ chặt chẽ đặc tả trong thư mục [MVP/](./MVP/README.md) và bộ quy tắc trong [.agent/](./.agent/README.md).

> **Trạng thái hiện tại:** Đã khởi tạo khung cây thư mục chuẩn (Project Skeleton), **chưa chứa file mã nguồn (`.dart`)** để sẵn sàng triển khai từng module theo lộ trình Vertical Slices.

---

## Sơ Đồ Cây Thư Mục (`Directory Tree`)

```text
Agriculture_App/
├── .agent/                                     # Cấu hình AI Agent (2 Rules + 35 Skills)
├── MVP/                                        # Bộ tài liệu đặc tả MVP (5 tài liệu chi tiết)
├── lib/                                        # Thư mục gốc chứa mã nguồn Flutter (sẽ thêm code sau)
│   ├── core/                                   # Tầng dùng chung toàn ứng dụng
│   │   ├── constants/                          # Hằng số nông học, cấu hình 4 khối giờ, hệ số quy đổi van 107-110
│   │   ├── theme/                              # Bảng màu Plantix High-Contrast Outdoor Palette & Typography
│   │   ├── utils/                              # Hàm tiện ích định dạng pH, EC (mS/cm), mL, giây, Wh
│   │   └── errors/                             # Xử lý ngoại lệ toán học & trạng thái mất kết nối Cloud
│   │
│   ├── domain/                                 # Tầng Lõi Toán học & Nghiệp vụ (Độc lập 100% với UI)
│   │   ├── entities/                           # Thực thể: CropBed, TimeBlockConfig, OptimizationResult, ValveDosingCommand...
│   │   ├── algorithms/                         # Các bộ giải toán học từ Đề bài & Sáng chế:
│   │   │   ├── bio_loss/                       # Hàm tổn thất sinh học bất đối xứng D_bio (L_x chống bó rễ, L_y chống cháy rễ)
│   │   │   ├── barycenter/                     # Bộ giải Đơn tâm Generalized Wasserstein Barycenter & Phân vị mẫu tau_t
│   │   │   ├── nelder_mead/                    # Thuật toán tìm cực tiểu Nelder-Mead Simplex 2D & lưu vết quỹ đạo quét
│   │   │   ├── wasserstein_kmeans/             # Bộ giải Đa tâm động Tầng 2 Wasserstein K-Means (M_t = 2..4 cụm)
│   │   │   └── hydraulic_scheduler/            # Hàng đợi thủy lực, bơm bù vi phân (Δx, Δy), định lượng 4 van A/B/C/D & tính tiết kiệm 5 chi phí (điện, nước, phân, acid, bazơ)
│   │   ├── repositories/                       # Hợp đồng giao tiếp dữ liệu (Repository Interfaces)
│   │   └── usecases/                           # Các ca sử dụng điều phối nghiệp vụ
│   │
│   ├── data/                                   # Tầng Dữ liệu (Hybrid Offline-First + Cloud Sync)
│   │   ├── models/                             # Models chuyển đổi JSON / Database
│   │   ├── datasources/
│   │   │   ├── local/                          # Lưu trữ cục bộ Offline-first trên thiết bị
│   │   │   ├── remote/                         # Đồng bộ Cloud Database (Supabase / Firebase - Giải pháp đám mây 114)
│   │   │   └── presets/                        # Thư viện cây trồng Plantix Crop Library (4 giai đoạn sinh trưởng) & Kịch bản mẫu
│   │   └── repositories/                       # Hiện thực hóa các Repositories
│   │
│   └── presentation/                           # Tầng Giao diện Người dùng (Plantix-Inspired Mobile UI)
│       ├── state/                              # Quản lý trạng thái ứng dụng (State Controllers / Providers)
│       ├── navigation/                         # Điều hướng Bottom Navigation 4 tab chính
│       ├── screens/
│       │   ├── dashboard/                      # Màn hình 1: Trạm Điều Phối, Đồng hồ Sinh học 4 Khối giờ & Thẻ Độ đo (x*, y*)
│       │   ├── crop_beds/                      # Màn hình 2: Quản lý N Luống Cây (117_1..117_N) & Thư viện 4 Giai đoạn Sinh trưởng
│       │   ├── ot_visualizer/                  # Màn hình 3: Biểu đồ 2D (pH, EC), Quỹ đạo Nelder-Mead & Đối chiếu Euclidean/DTW/TTW/OT
│       │   ├── hydraulic_iot/                  # Màn hình 4: Hàng đợi Thủy lực, Định lượng Van 107-110, Sơ đồ Bể 100 & Tiết kiệm 5 Chi phí
│       │   └── auth_sync/                      # Màn hình Đăng nhập Tài khoản Trang trại & Đồng bộ Cloud 114
│       └── widgets/
│           ├── cards/                          # Thẻ Crop Card, Bác sĩ Chẩn đoán Rễ, Hero Metric Card, Thẻ Tiết kiệm 5 Chi phí
│           ├── charts/                         # CustomPainter vẽ mặt phẳng tọa độ 2D (pH, EC) & Đơn hình Nelder-Mead
│           └── schematics/                     # CustomPainter vẽ sơ đồ Bể phối trộn trung tâm 100, Bể A/B/C/D (103-106) & Van (107-113)
│
├── test/                                       # Thư mục Kiểm thử Tự động (TDD)
│   ├── domain/algorithms/                      # Unit tests kiểm chứng Kịch bản 1 (6.1, 1.2), Kịch bản 2 (+0.6, +0.6), Nelder-Mead
│   ├── data/                                   # Unit tests cho dữ liệu & thư viện cây trồng
│   └── presentation/                           # Widget tests cho giao diện Mobile
│
├── assets/                                     # Tài nguyên tĩnh (Hình minh họa cây trồng, sơ đồ Fig.1 & Fig.2, icons, presets)
│   ├── images/crops/
│   ├── images/schematics/
│   ├── icons/
│   └── presets/
│
└── [android/ | ios/ | web/ | windows/]         # Thư mục khung đích biên dịch đa nền tảng
```
