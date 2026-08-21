# Pemodelan Dinamik Neraca Perbankan dengan Kebijakan Rasio Leverage

[![Mathematical Modeling](https://img.shields.io/badge/Model-Dynamic%20%26%20Stochastic-blue.svg)](#-formulasi-model-matematika)
[![Optimization](https://img.shields.io/badge/Algorithm-PSO%20(MAPE%201.55%25)-green.svg)](#-metodologi--simulasi-numerik)
[![Implementation](https://img.shields.io/badge/Tool-MATLAB-orange.svg)](https://www.mathworks.com/products/matlab.html)

## 📌 Ringkasan Penelitian
Repositori ini memuat formulasi matematika, analisis kestabilan, dan simulasi numerik dari **Model Dinamik Neraca Perbankan**. Penelitian ini menghubungkan tiga variabel utama neraca bank—**Dana Pihak Ketiga (DPK)**, **Kredit**, dan **Ekuitas**—dengan mengintegrasikan **kebijakan rasio leverage** serta **Giro Wajib Minimum (GWM)** sebagai instrumen regulasi makroprudensial.

---

## 📐 Formulasi Model Matematika

### 1. Model Deterministik (Sistem ODE Nonlinier)
Model dirumuskan dalam sistem persamaan diferensial nonlinier yang menggambarkan laju perubahan interaksi antara DPK ($D$), Kredit ($K$), dan Ekuitas ($E$):
- **Laju DPK**: Dipengaruhi oleh penerimaan simpanan, penarikan dana, dan alokasi GWM.
- **Laju Kredit**: Dipengaruhi oleh tingkat penyaluran kredit dari DPK dan rasio kredit macet (*Non-Performing Loan* / NPL).
- **Laju Ekuitas**: Dipengaruhi oleh pendapatan bunga kredit, biaya operasional, bunga DPK, serta pemenuhan kebijakan rasio leverage.

### 2. Model Stokastik (Persamaan Diferensial Stokastik / SDE)
Untuk mengakomodasi ketidakpastian pasar finansial, model dikembangkan ke bentuk stokastik dengan menambahkan fluktuasi acak berbasis **Proses Wiener (Gerak Brown)** pada:
- Laju penarikan DPK oleh nasabah.
- Fluktuasi rasio kredit macet (NPL).

---

## 🔬 Metodologi & Simulasi Numerik

1. **Analisis Kualitatif Sistem Dinamik**:
   - Analisis kepositifan dan keterbatasan solusi (*boundedness*).
   - Penentuan titik kesetimbangan interior (*interior equilibrium point*).
   - Analisis kestabilan lokal menggunakan matriks Jacobian dan kriteria Routh-Hurwitz.

2. **Estimasi Parameter via Particle Swarm Optimization (PSO)**:
   - Parameter model diestimasi menggunakan algoritma PSO berbasis data historis perbankan Indonesia.
   - Hasil estimasi mencapai tingkat akurasi yang sangat tinggi dengan nilai **Mean Absolute Percentage Error (MAPE) = 1.5539%**.

3. **Simulasi Stokastik (Euler-Maruyama & Monte Carlo)**:
   - Solusi numerik dari SDE dihitung menggunakan metode **Euler-Maruyama**.
   - Simulasi *Monte Carlo* digunakan untuk melihat sebaran trayektori variabel terhadap waktu.

4. **Analisis Sensitivitas**:
   - Mengukur dampak variasi GWM dan rasio leverage terhadap ekspansi kredit dan ketahanan ekuitas.
   - Mengukur tingkat kerentanan variabel menggunakan *Coefficient of Variation* (CV).

---

## 📊 Hasil Utama & Implikasi Kebijakan

- **Kestabilan Sistem**: Sistem memiliki titik kesetimbangan yang bersifat **stabil asimtotik lokal**, baik pada kondisi deterministik maupun stokastik.
- **Ketahanan Permodalan**: Penerapan kebijakan rasio leverage yang lebih tinggi secara signifikan meningkatkan daya tahan permodalan (ekuitas) bank dalam menyerap risiko kerugian.
- **Trade-off Penyaluran Kredit**: Peningkatan persentase GWM dan pembatasan rasio leverage dapat menekan laju pertumbuhan penyaluran kredit.
- **Sensitivitas Variabel**: Berdasarkan analisis *Coefficient of Variation*, **Ekuitas** merupakan variabel yang paling sensitif terhadap fluktuasi acak dibandingkan DPK dan Kredit.

---

## 💻 Implementasi Kode

Seluruh simulasi matematika, fungsi estimasi parameter, dan visualisasi grafik diimplementasikan menggunakan **MATLAB**:

```text
├── data/
│   └── Dataku.xlsx              # Data historis perbankan
└── src/
    ├── bank_model.m             # Model ODE neraca perbankan
    ├── cost_function.m          # Fungsi biaya untuk optimasi PSO
    ├── PSO_Main.m               # Skrip utama estimasi parameter PSO
    ├── stokastik.m              # Simulasi SDE (Euler-Maruyama)
    ├── diagram_fase.m           # Visualisasi diagram fase
    ├── sensitivitas_lambda.m    # Analisis sensitivitas parameter lambda
    └── Sensitivitas_rho.m       # Analisis sensitivitas parameter rho
```
