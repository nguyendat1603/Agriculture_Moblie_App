---
name: plantix-mobile-ui
description: >-
  Guides the design and implementation of the Plantix-inspired cross-platform Mobile App UI
  for farm nutrition management across N crops. Use when creating or styling mobile screens,
  crop cards, biological clock & agri-weather banners, root safety diagnostic cards, 2D (pH, EC)
  coordinate charts, or the central mixing tank (100) and IoT valve (107-113) schematic.
---

# Plantix-Inspired Mobile UI Skill

Use this skill when building or refining the user interface of the mobile application. Reference the detailed design specifications in [03_Features_and_UX_UI_Design_Spec.md](../../MVP/03_Features_and_UX_UI_Design_Spec.md).

## Core UI Components Checklist

### 1. Agri-Weather & 4-Block Bio-Clock Banner
* Place at the top of the Home Dashboard.
* Provide 4 tactile selector pills for the Biological Time Blocks:
  * **Khối 1 (06h–08h):** Sáng sớm – Kích hoạt rễ
  * **Khối 2 (10h–14h):** Trưa nắng gắt – Chống cháy rễ
  * **Khối 3 (15h–17h):** Chiều mát – Tích lũy khoáng
  * **Khối 4 (Sau 18h):** Ban đêm – Ngắt & Xả ống
* Provide 3 quick micro-climate toggles: **Ôn hòa** ($K=1.0$), **Nắng gắt** ($K_{\text{sunny}} > 1$), **Mưa lớn** ($K_{\text{rainy}} > 1$).

### 2. Hero Overall Nutrition Metric Card $(x^*, y^*)$
* Display the active optimization mode badge: `ĐƠN TÂM TOÀN CỤC`, `ĐA TÂM ĐỘNG (M CỤM)`, or `NGẮT VẬN HÀNH BAN ĐÊM`.
* Show large, high-contrast readouts for **$x^*$ (Độ pH tổng thể)** and **$y^*$ (Nồng độ EC tổng thể - $\text{mS/cm}$)**.
* Include a direct side-by-side comparison badge against the **Euclidean Mean $(\bar{x}, \bar{y})$**, highlighting how much biological loss $\mathcal{D}_{\text{bio}}$ is reduced and how many sensitive crop beds are saved from root burn.

### 3. Plantix "Crop Doctor" Diagnostic Advisory Card
* Translate mathematical weights $(w_{\text{low},t}, w_{\text{high},t}, \tau_t)$ into clear, actionable agronomic advice in Vietnamese.
* Color-code the banner:
  * Green (`#2E7D32` on `#E8F5E9`): All $N$ beds are protected from root burn.
  * Amber (`#F57F17` on `#FFF8E1`): High crop divergence detected; Multi-Barycenter sequential mixing activated.
  * Purple (`#4527A0` on `#EDE7F6`): Night mode active; valves closed to prevent root rot.

### 4. Visual Crop Cards & 4-Stage Plantix Crop Library (`117_1` .. `117_N`)
* Support adding, editing, and deleting any number of beds $N$, plus 1-tap preset buttons:
  * **"Mẫu Sáng Chế ($N=2$: Xà lách & Cải ngọt)"**
  * **"Trang Trại Đa Canh ($N=6$ loại cây)"**
* Integrate the **Plantix Crop Library with 4 Growth Stages** (`1. Cây con / Kiến thiết`, `2. Sinh trưởng thân lá`, `3. Ra hoa`, `4. Nuôi quả / Thu hoạch`) so selecting a crop and its growth stage automatically populates recommended $(x_i^{\text{target}}, y_i^{\text{target}})$ and sensitivity factor $s_i$.
* Provide a toggle for **Dual Weighting Mode**: Default Equal Weights ($1/N$) vs. Area ($\text{m}^2$) & Sensitivity ($s_i$) Weights.
* Each card shows: Crop emoji/illustration, Bed ID (`117_i`), Growth stage selector, Target $(x_i^{\text{target}}, y_i^{\text{target}})$, Area ($\text{m}^2$), Assigned cluster, and a real-time Root Safety Indicator bar under the current $(x^*, y^*)$.

### 5. Interactive 2D $(\text{pH}, \text{EC})$ Coordinate Map, Valve Dosing & Cloud Sync
* **2D Chart (`CustomPainter` in Flutter):** Plot all $N$ beds on the $(\text{pH}, \text{EC})$ plane, mark the Euclidean mean $(\bar{x}, \bar{y})$ vs. the Optimal Transport Barycenter $(x^*, y^*)$ (or cluster centroids $(x_{j,t}^*, y_{j,t}^*)$ connected by differential vectors $(\Delta x, \Delta y)$).
* **Hydroponic Valve Dosing & IoT Schematic (Fig. 1 & Fig. 2):** Visually represent Water Tanks (`101`, `102`), Nutrient Stock Tanks A & B (`103`, `104`), Acid Tank C (`105`), Base Tank D (`106`), Dosing Valves (`107–110`) with exact $\text{mL}$ and valve opening time (seconds), Central Mixing Tank (`100`), Sensor (`119`), IoT Controller (`112`), Cloud (`114`), Distribution Valves (`113`), and Crop Beds (`117`).
* **Farm Account Login & Hybrid Offline + Cloud Sync:** Provide a clean Farm Account Login / Cloud Sync drawer (Supabase/Firebase integration + Local Offline persistence) with instant 1-tap Guest/Demo access.
