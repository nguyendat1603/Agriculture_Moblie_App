# Cấu hình AI Agent cho Dự án (`.agent/`)

Thư mục `.agent/` chứa toàn bộ **Workspace Rules** và **Workspace Skills** của dự án ứng dụng di động điều phối dinh dưỡng trang trại **AgroOT (Plantix-Inspired Mobile App)**.

Hệ thống kết hợp **2 Skills đặc thù của bài toán Vận tải tối ưu & Giao diện Plantix** với **33 Skills tuyển chọn từ kho lưu trữ [`sickn33/agentic-awesome-skills`](https://github.com/sickn33/agentic-awesome-skills)** được phân thành 4 nhóm chiến lược:
1. **Nhóm Kỹ thuật Đặc thù Dự án (Domain Core):** Toán học Vận tải tối ưu (Optimal Transport) & Giao diện Nông nghiệp Plantix.
2. **Nhóm Thiết kế Giao diện UI/UX (UI/UX Design):** 8 skills chuyên sâu về Mobile UI, Design Systems, Dashboard, Trạng thái giao diện và Accessibility.
3. **Nhóm Phương pháp & Quy trình Làm việc của Agent (Agent Workflows & Engineering Discipline):** 14 skills chuẩn hóa toàn bộ vòng đời làm việc của Agent từ Brainstorming, Lập kế hoạch, TDD, Clean Code, Debugging cho tới Kiểm chứng trước khi hoàn thành.
4. **Nhóm Lập trình Mobile & Flutter Đa nền tảng (Mobile & Flutter Engineering):** 5 skills chuyên biệt cho Flutter 3.x / Dart 3, kiến trúc Mobile, Component Scaffolding và Bảo mật di động.
5. **Nhóm Kiến trúc, Cơ sở dữ liệu Cloud & Kiểm thử Cần thiết (Essential Project Skills):** 6 skills về Clean Architecture, Supabase/Postgres Cloud Sync, Authentication, Data Storytelling và Unit Testing.

---

## 1. Danh mục Workspace Rules (`.agent/rules/`)

| File Rule | Vai trò & Phạm vi áp dụng |
| :--- | :--- |
| **[optimal-transport-nutrition.md](./rules/optimal-transport-nutrition.md)** | Quy tắc bất biến bảo vệ công thức $\mathcal{D}_{\text{bio}}$, ràng buộc $w_{\text{high},t} \ge k_t \cdot w_{\text{low},t}$, chu kỳ 4 khối giờ sinh học ($t=1..4$), chế độ Trọng số Kép ($1/N$ vs Diện tích & Độ nhạy cảm) và định lượng 4 van thủy canh A/B/C/D (`107–110`). |
| **[plantix-mobile-ux-architecture.md](./rules/plantix-mobile-ux-architecture.md)** | Quy tắc kiến trúc **Flutter Clean Architecture 3 lớp** (`lib/domain/`, `lib/data/`, `lib/presentation/`), cơ chế lưu trữ Offline-first + Cloud Sync (Supabase/Firebase) và ngôn ngữ thiết kế **Plantix High-Contrast UI**. |

---

## 2. Danh mục 35 Workspace Skills (`.agent/skills/`)

### A. Nhóm Kỹ Thuật Đặc Thù Dự Án (Project Domain Skills)
1. **[`optimal-transport-nutrition`](./skills/optimal-transport-nutrition/SKILL.md)**: Triển khai và kiểm thử bộ giải **Generalized Wasserstein Barycenter (Đơn tâm)**, **Wasserstein K-Means (Đa tâm động)**, lập lịch hàng đợi thủy lực, bơm bù vi phân $(\Delta x, \Delta y)$ và định lượng $\text{mL}$/giây mở van `107–110`.
2. **[`plantix-mobile-ui`](./skills/plantix-mobile-ui/SKILL.md)**: Xây dựng giao diện Mobile theo phong cách **Plantix** (Thẻ cây trồng 4 giai đoạn sinh trưởng, Thẻ chẩn đoán Bác sĩ Cây trồng, Biểu đồ 2D $(\text{pH}, \text{EC})$ và Sơ đồ Bể phối trộn trung tâm `100`).

### B. Nhóm Thiết Kế UI/UX (Từ `sickn33/agentic-awesome-skills`)
3. **[`ui-ux-pro-max`](./skills/ui-ux-pro-max/SKILL.md)**: Hệ thống tư duy UI/UX nâng cao, bảng màu, cặp font chữ và quy chuẩn thiết kế hiện đại.
4. **[`mobile-design`](./skills/mobile-design/SKILL.md)**: Tư duy thiết kế Mobile-first, vùng chạm ngón cái (thumb-zone), cử chỉ vuốt chạm và hiệu năng cuộn trên iOS/Android.
5. **[`frontend-design`](./skills/frontend-design/SKILL.md)**: Nguyên lý bố cục thị giác, phân cấp thông tin (visual hierarchy) và tránh giao diện chung chung.
6. **[`high-end-visual-design`](./skills/high-end-visual-design/SKILL.md)**: Nâng tầm độ hoàn thiện thị giác, khoảng trắng, đổ bóng, viền và chuyển động tinh tế.
7. **[`kpi-dashboard-design`](./skills/kpi-dashboard-design/SKILL.md)**: Thiết kế Dashboard chỉ số kỹ thuật và biểu đồ ra quyết định (áp dụng cho Hero Card $(x^*, y^*)$ và mặt phẳng tọa độ $(\text{pH}, \text{EC})$).
8. **[`ui-states`](./skills/ui-states/SKILL.md)**: Thiết kế đầy đủ các trạng thái Loading, Empty, Error, Offline và Success có phản hồi rõ ràng.
9. **[`ui-a11y`](./skills/ui-a11y/SKILL.md)**: Đảm bảo chuẩn tương phản màu sắc WCAG (rất quan trọng khi nông dân nhìn màn hình điện thoại ngoài trời nắng), nhãn ngữ nghĩa và kích thước nút bấm.
10. **[`ui-review`](./skills/ui-review/SKILL.md)**: Quy trình đánh giá chất lượng giao diện, tính khả dụng và mức độ khớp với thiết kế sản phẩm.

### C. Nhóm Cách Làm Việc Của Agent (Agent Workflow & Discipline Skills)
11. **[`brainstorming`](./skills/brainstorming/SKILL.md)**: Khám phá yêu cầu, đặt câu hỏi làm rõ thiết kế và thống nhất giải pháp trước khi viết code.
12. **[`concise-planning`](./skills/concise-planning/SKILL.md)**: Lập kế hoạch ngắn gọn, rõ ràng, có checklist kiểm chứng trước khi bắt đầu thực thi.
13. **[`writing-plans`](./skills/writing-plans/SKILL.md)**: Chia nhỏ đặc tả kỹ thuật thành các task nhỏ (bite-sized tasks) kèm tiêu chí nghiệm thu cụ thể.
14. **[`executing-plans`](./skills/executing-plans/SKILL.md)**: Thực thi kế hoạch theo từng bước có điểm dừng kiểm tra (checkpoints).
15. **[`test-driven-development`](./skills/test-driven-development/SKILL.md)**: Phát triển theo chu trình Red-Green-Refactor (viết test kiểm chứng công thức toán học trước rồi viết code).
16. **[`systematic-debugging`](./skills/systematic-debugging/SKILL.md)**: Gỡ lỗi có hệ thống dựa trên bằng chứng và truy vết nguyên nhân gốc rễ (root-cause analysis), tuyệt đối không đoán mò.
17. **[`lint-and-validate`](./skills/lint-and-validate/SKILL.md)**: Tự động chạy trình phân tích tĩnh (`flutter analyze` / linter) và kiểm tra lỗi sau mỗi lần sửa code.
18. **[`verification-before-completion`](./skills/verification-before-completion/SKILL.md)**: Bắt buộc chạy lệnh kiểm tra thực tế và xác nhận kết quả đầu ra trước khi báo cáo hoàn thành.
19. **[`clean-code`](./skills/clean-code/SKILL.md)**: Quy chuẩn viết code sạch, hàm ngắn gọn, đặt tên rõ nghĩa, tuân thủ DRY/KISS/SOLID.
20. **[`code-review-checklist`](./skills/code-review-checklist/SKILL.md)**: Danh sách kiểm tra chất lượng code đa chiều trước khi bàn giao.
21. **[`subagent-driven-development`](./skills/subagent-driven-development/SKILL.md)**: Điều phối các Subagents thực hiện từng task độc lập kèm bước review chéo.
22. **[`dispatching-parallel-agents`](./skills/dispatching-parallel-agents/SKILL.md)**: Phân tách các tác vụ độc lập để chạy song song nhiều Agents hiệu quả.
23. **[`kaizen`](./skills/kaizen/SKILL.md)**: Triết lý cải tiến liên tục theo từng bước nhỏ và cơ chế phòng chống lỗi (Poka-Yoke).
24. **[`effective-agent-skills`](./skills/effective-agent-skills/SKILL.md)**: Chuẩn thiết kế và vận hành hệ thống Skills theo cơ chế Progressive Disclosure.

### D. Nhóm Lập Trình Mobile & Flutter (Mobile Engineering Skills)
25. **[`flutter-expert`](./skills/flutter-expert/SKILL.md)**: Chuyên gia Flutter 3.x & Dart 3: quản lý state, tối ưu cây Widget, `CustomPainter`, điều hướng và đa nền tảng.
26. **[`mobile-developer`](./skills/mobile-developer/SKILL.md)**: Kiến trúc ứng dụng di động, lưu trữ Offline-first, đồng bộ nền và tối ưu bộ nhớ/pin.
27. **[`multi-platform-apps-multi-platform`](./skills/multi-platform-apps-multi-platform/SKILL.md)**: Xây dựng ứng dụng thích ứng mượt mà trên cả Mobile (Android/iOS), Tablet, Web và Desktop.
28. **[`frontend-mobile-development-component-scaffold`](./skills/frontend-mobile-development-component-scaffold/SKILL.md)**: Quy chuẩn dựng khung Component tái sử dụng cho ứng dụng di động.
29. **[`mobile-security-coder`](./skills/mobile-security-coder/SKILL.md)**: Bảo mật dữ liệu cục bộ trên thiết bị di động, quản lý khóa API và xác thực an toàn.

### E. Nhóm Kiến Trúc, Cloud Sync & Kiểm Thử Cần Thiết (Essential Project Skills)
30. **[`architecture-patterns`](./skills/architecture-patterns/SKILL.md)**: Triển khai Clean Architecture, Domain-Driven Design (DDD) và tách biệt ranh giới giữa Lõi Toán học (`domain`) và Giao diện (`presentation`).
31. **[`supabase-automation`](./skills/supabase-automation/SKILL.md)**: Tích hợp và tự động hóa cơ sở dữ liệu đám mây Supabase (lưu trữ cấu hình trang trại $N$ luống cây và lịch phối trộn `118`).
32. **[`postgres-best-practices`](./skills/postgres-best-practices/SKILL.md)**: Thiết kế bảng dữ liệu Postgres/Supabase chuẩn, tối ưu truy vấn và bảo mật Row-Level Security (RLS).
33. **[`auth-implementation-patterns`](./skills/auth-implementation-patterns/SKILL.md)**: Thiết kế luồng Đăng nhập / Đăng ký tài khoản trang trại và quản lý phiên làm việc kết hợp chế độ Offline/Guest.
34. **[`data-storytelling`](./skills/data-storytelling/SKILL.md)**: Chuyển hóa các kết quả toán học phức tạp ($\mathcal{D}_{\text{bio}}, \tau_t, w_{\text{high}}, w_{\text{low}}$) thành câu chuyện trực quan và lời khuyên nông học dễ hiểu.
35. **[`testing-patterns`](./skills/testing-patterns/SKILL.md)**: Thiết kế bộ Unit Tests và Widget Tests cô lập, kiểm chứng chính xác các kịch bản biên của thuật toán.
