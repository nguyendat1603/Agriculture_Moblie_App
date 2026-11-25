---
name: optimal-transport-nutrition
description: >-
  Implements, verifies, and extends the Optimal Transport (Generalized Wasserstein Barycenter)
  and Multi-Barycenter Dynamic Tuning (Wasserstein K-Means + Sequential Differential Mixing)
  algorithm for calculating the overall nutrition metric (pH x*, EC y*) across N crop beds
  adapted to 4 biological time blocks and micro-climate conditions. Use whenever writing or
  testing mathematical solver code, clustering logic, or hydraulic pipeline scheduling.
---

# Optimal Transport Adaptive Nutrition Algorithm Skill

Use this skill when implementing or modifying the core mathematical engine of the application based on both [Description of Độ đo tổng thể..docx](file:///d:/App_trong_cay/Agriculture_App/Description%20of%20%C4%90%E1%BB%99%20%C4%91o%20t%E1%BB%95ng%20th%E1%BB%83..docx) and [Tài liệu gửi sinh viên.docx](file:///d:/App_trong_cay/Agriculture_App/T%C3%A0i%20li%E1%BB%87u%20g%E1%BB%ADi%20sinh%20vi%C3%AAn.docx).

## Step 1: Implement the Asymmetric Biological Distance ($\mathcal{D}_{\text{bio}}$) & 5-Resource Cost Savings

Given a candidate solution $(x, y)$ and bed $i$'s target $(x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})$ at time block $t \in \{1, 2, 3\}$ (or daily cycle):

1. **pH Loss ($\mathcal{L}_{x,i,t}$) with Expert Nutrient-Lockout Penalty ("Bó rễ"):**
   $$\mathcal{L}_{x,i,t}(x, x_{i,t}^{\text{target}}) = \alpha_t \cdot (x - x_{i,t}^{\text{target}})^2 + \begin{cases} w_{\text{low},i,t}^{(x)} \cdot (x_{i,t}^{\text{target}} - x) & \text{if } x \le x_{i,t}^{\text{target}} \\ w_{\text{high},i,t}^{(x)} \cdot (x - x_{i,t}^{\text{target}}) & \text{if } x > x_{i,t}^{\text{target}} \text{ (nutrient lockout / bó rễ)} \end{cases}$$
   *(Note: In standard patent mode $w_{\text{low},i,t}^{(x)} = w_{\text{high},i,t}^{(x)} = 0$; in expert asymmetric pH mode from the problem statement, $w_{\text{high},i,t}^{(x)} > w_{\text{low},i,t}^{(x)} \ge 0$ configured per crop and growth stage).*
2. **Asymmetric EC Loss ($\mathcal{L}_{y,i,t}$) with Expert Root-Burn Penalty ("Cháy rễ"):**
   $$\mathcal{L}_{y,i,t}(y, y_{i,t}^{\text{target}}) = \begin{cases} w_{\text{low},i,t} \cdot (y_{i,t}^{\text{target}} - y) & \text{if } y \le y_{i,t}^{\text{target}} \\ w_{\text{high},i,t} \cdot (y - y_{i,t}^{\text{target}}) & \text{if } y > y_{i,t}^{\text{target}} \text{ (root burn / cháy rễ)} \end{cases}$$
3. **Total Biological Cost & Solvers (Optimal Transport & Nelder-Mead Simplex):**
   $$\mathcal{D}_{\text{bio}}((x, y) \rightarrow (x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}})) = \mathcal{L}_{x,i,t} + \mathcal{L}_{y,i,t}$$
   * Support both the **Exact Quantile / OT Barycenter Solver** and the **2D Nelder-Mead Simplex Search Solver** (recording simplex vertices at each iteration to render the search trajectory on the 2D chart), plus quantify the **5 control cost savings (Electricity, Water, Nutrients, Acid, Base)** compared to $4 \times N$ daily mixing cycles.

## Step 2: Apply Tier-1 Climate-Driven Adaptive Weights

Before solving for $(x^*, y^*)$:
* Check if $t == 4$ (Night Block, after 18:00): set $w_{\text{low},4} = 0, w_{\text{high},4} = 0$ and immediately return `NIGHT_SHUTDOWN`.
* For $t \in \{1, 2, 3\}$:
  * Apply sunny multiplier ($K_{\text{sunny}} \ge 1.0$): $w_{\text{high},t} \leftarrow K_{\text{sunny}} \cdot w_{\text{high},t}^{\text{base}}$.
  * Apply rainy multiplier ($K_{\text{rainy}} \ge 1.0$): $w_{\text{low},t} \leftarrow K_{\text{rainy}} \cdot w_{\text{low},t}^{\text{base}}$.
  * Enforce mandatory safety bound: $w_{\text{high},t} = \max(w_{\text{high},t}, k_t \cdot w_{\text{low},t})$.

## Step 3: Solve the Single-Barycenter $(x^*, y^*)$

For any non-empty subset of beds $S \subseteq \{1, \dots, N\}$ (with optional area/flow weights $p_i > 0, \sum_{i \in S} p_i = 1$; default $p_i = 1/|S|$):
1. **Optimal pH ($x^*$):**
   $$x^* = \sum_{i \in S} p_i \cdot x_{i,t}^{\text{target}}$$
2. **Optimal EC ($y^*$) via Quantile / Pinball Loss Minimization:**
   * Compute safety quantile ratio:
     $$\tau_t = \frac{w_{\text{low},t}}{w_{\text{low},t} + w_{\text{high},t}}$$
   * Sort beds in $S$ by ascending $y_{i,t}^{\text{target}}$: $y_{(1)} \le y_{(2)} \le \dots \le y_{(|S|)}$.
   * Find the first index $m$ where cumulative weight $\sum_{r=1}^m p_{(r)} \ge \tau_t$, and set $y^* = y_{(m)}$.
   * *(Optional numerical mode)*: Also provide a Nelder-Mead / smoothed Sinkhorn solver option to visualize iterative convergence trajectories on the UI.

## Step 4: Tier-2 Multi-Barycenter Dynamic Clustering (Wasserstein K-Means)

1. **Divergence Check:**
   Evaluate whether Single-Barycenter $(x^*, y^*)$ causes excessive biological divergence:
   * Condition A: $\max_i y_{i,t}^{\text{target}} - \min_i y_{i,t}^{\text{target}} > \Theta_{\text{spread}, t}$ (especially strict in Block 2 where $\Theta_{\text{spread}, 2} = 0.4\text{ mS/cm}$).
   * Condition B: Average or maximum per-bed biological loss $\mathcal{D}_{\text{bio}}$ exceeds $\Theta_{\text{loss}, t}$.
2. **Wasserstein K-Means Execution:**
   * Choose cluster count $M_t \in \{2, 3\}$ ($M_t \le N$).
   * Initialize $M_t$ centroids along the quantiles of $\{y_{i,t}^{\text{target}}\}$.
   * Iterate until convergence:
     * **Assign** each bed $i$ to cluster $j = \arg\min_{j \in \{1..M_t\}} \mathcal{D}_{\text{bio}}((x_{j,t}^*, y_{j,t}^*) \rightarrow (x_{i,t}^{\text{target}}, y_{i,t}^{\text{target}}))$.
     * **Update** each cluster's centroid $(x_{j,t}^*, y_{j,t}^*)$ using the Single-Barycenter solver in Step 3.
3. **Hydraulic Queue, Sequential Differential Mixing & Hydroponic Valve Dosing (107–110):**
   * Sort the $M_t$ clusters in ascending order of optimal EC: $y_{1,t}^* \le y_{2,t}^* \le \dots \le y_{M_t,t}^*$.
   * Period 1 mixes $(x_{1,t}^*, y_{1,t}^*)$ from filtered water tank `102` (default neutral baseline $x_{\text{base}} = 7.0$, $y_{\text{base}} = 0.1\text{ mS/cm}$).
   * For Period $j \rightarrow j+1$:
     * Compute differential transport vector: $\Delta x = x_{j+1,t}^* - x_{j,t}^*$, $\Delta y = y_{j+1,t}^* - y_{j,t}^*$.
     * If $\Delta y \ge 0$: **Skip pipeline flushing (100% flush water saved)** and inject differential nutrients $\Delta y$ and acid/base $\Delta x$ directly into the residual main pipeline flow.
     * If $\Delta y < 0$: Trigger **Rapid Pipeline Flush** from tank `102` before mixing Period $j+1$.
   * **Valve Dosing Calculation (`107–110`):**
     * **Valves `107` (Tank A `103`) & `108` (Tank B `104`):** Nutrient stock A & B (increase EC when $\Delta y > 0$): $V_A = V_B = \max(0, \Delta y) \cdot V_{\text{tank}} \cdot C_{AB}\text{ (mL)}$, $t_{\text{open}} = V_A / Q_{\text{valve}}\text{ (s)}$.
     * **Valve `109` (Tank C `105` - Acid / pH Down):** Active when $\Delta x < 0$: $V_C = |\Delta x| \cdot V_{\text{tank}} \cdot C_{\text{acid}}\text{ (mL)}$, $t_{\text{open}} = V_C / Q_{\text{valve}}\text{ (s)}$.
     * **Valve `110` (Tank D `106` - Base / pH Up):** Active when $\Delta x > 0$: $V_D = \Delta x \cdot V_{\text{tank}} \cdot C_{\text{base}}\text{ (mL)}$, $t_{\text{open}} = V_D / Q_{\text{valve}}\text{ (s)}$.

## Step 5: Mandatory Verification Checks

Always run and verify these two benchmark scenarios from the patent specification:
1. **Scenario 1 ($N=2$, Lettuce $(5.8, 1.2)$ & Sweet Cabbage $(6.4, 1.8)$, Block $t=1$ Mild Morning):**
   * Must output Single-Barycenter: $x^* = 6.1$, $y^* = 1.2\text{ mS/cm}$.
2. **Scenario 2 ($N=2$, Lettuce $(5.8, 1.2)$ & Sweet Cabbage $(6.4, 1.8)$, Block $t=2$ Sunny Midday):**
   * Must trigger Multi-Barycenter ($M_2 = 2$ clusters):
     * Period 1 (Lettuce `117_1`): $(x_{1,2}^* = 5.8, y_{1,2}^* = 1.2\text{ mS/cm})$.
     * Period 2 (Sweet Cabbage `117_2`): Differential injection $(\Delta x = +0.6, \Delta y = +0.6\text{ mS/cm}) \rightarrow (x_{2,2}^* = 6.4, y_{2,2}^* = 1.8\text{ mS/cm})$ with `0%` flush water wasted.
