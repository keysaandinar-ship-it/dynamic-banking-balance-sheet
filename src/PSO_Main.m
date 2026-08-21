clear; clc; close all;
rng(1);

%% =============================
%% 1. LOAD DATA (DARI EXCEL)
%% =============================
filename = 'Dataku.xlsx'; 
if ~exist(filename, 'file')
    error('File %s tidak ditemukan! Pastikan file ada di folder yang sama.', filename);
end

try
    % Membaca data: DPK Kolom 4(D), Kredit Kolom 5(E), Ekuitas Kolom 6(F)
    data_raw = readmatrix(filename);
    D_raw = data_raw(1:45, 4); 
    L_raw = data_raw(1:45, 5); 
    E_raw = data_raw(1:45, 6); 
    
    % Skala jutaan agar ODE stabil (6.198.197 -> 6.19)
    Ddata = D_raw/1e6;
    Ldata = L_raw/1e6;
    Edata = E_raw/1e6;
    tdata = (0:length(Ddata)-1)';
catch ME
    error('Gagal membaca data: %s. Pastikan Kolom F (Ekuitas) sudah terisi!', ME.message);
end
%% =============================
%% 2. PARAMETER TETAP (FIXED)
%% =============================
r_L    = 0.09141389373;
r_D    = 0.01955164208;
lambda = 0.03;
rho    = 0.075;
eta    = 0.0254; 

%% =============================
%% 3. SETTING PSO
%% =============================
nPop    = 300; 
MaxIter = 430; 
w       = 0.7; 
c1      = 1.5; 
c2      = 2.0; 
nVar    = 13; 

%Urutan: [alpha_D, K_D, omega, alpha_L, K_L, delta, alpha_p, alpha_E, r_A, r_E, c_D, c_L, c_E]
VarMin = [0.00000001, max(Ddata), 0.001, 0.00000001, max(Ldata), 0.001, 0.05, 0.0030, 0.001, 0.0001, 0.0001, 0.0001, 0.002];
VarMax = [0.50, 2*max(Ddata), 0.04005, 0.05, 2*max(Ldata), 0.9, 0.5, 0.4, 0.09, 0.0500, 0.04, 0.04, 0.09];


% Inisialisasi Partikel
particle = struct('Position',[],'Velocity',[],'Cost',[],'Best',struct('Position',[],'Cost',[]));
for i = 1:nPop
    particle(i).Position = VarMin + rand(1,nVar).*(VarMax-VarMin);
    particle(i).Velocity = zeros(1,nVar);
    particle(i).Cost = cost_function(particle(i).Position, tdata, Ddata, Ldata, Edata, r_L, r_D, eta);
    particle(i).Best.Position = particle(i).Position;
    particle(i).Best.Cost = particle(i).Cost;
end

[~,idx] = min([particle.Cost]);
GlobalBest = particle(idx).Best;

%% =============================
%% 4. PROSES ITERASI PSO
%% =============================
for it = 1:MaxIter
    for i = 1:nPop
        particle(i).Velocity = w*particle(i).Velocity ...
            + c1*rand(1,nVar).*(particle(i).Best.Position - particle(i).Position) ...
            + c2*rand(1,nVar).*(GlobalBest.Position - particle(i).Position);
        
        particle(i).Position = particle(i).Position + particle(i).Velocity;
        particle(i).Position = max(min(particle(i).Position, VarMax), VarMin);
        
        particle(i).Cost = cost_function(particle(i).Position, tdata, Ddata, Ldata, Edata, r_L, r_D, eta);
        
        if particle(i).Cost < particle(i).Best.Cost
            particle(i).Best.Position = particle(i).Position;
            particle(i).Best.Cost = particle(i).Cost;
        end
        if particle(i).Best.Cost < GlobalBest.Cost
            GlobalBest = particle(i).Best;
        end
    end
    fprintf('Iterasi %d | Best Cost (MAPE) = %.4f %%\n', it, GlobalBest.Cost);
end

%% =============================
%% 5. PENYAJIAN HASIL AKHIR
%% =============================
BP = GlobalBest.Position;
aD=BP(1); KD=BP(2); om=BP(3); aL=BP(4); KL=BP(5); de=BP(6); 
ap=BP(7); aE=BP(8); rA=BP(9); rE=BP(10); cD=BP(11); cL=BP(12); cE =BP (13);

% Simulasi Final untuk Grafik
y0 = [Ddata(1) Ldata(1) Edata(1)];
[t, y] = ode15s(@(t,y) bank_model(t,y,aD,KD,om,aL,KL,eta,de,ap,aE,rA,rE,cD,cL,cE, r_L,r_D,rho,lambda), tdata, y0);

Dsim = y(:,1); Lsim = y(:,2); Esim = y(:,3);
MAPE_D = mean(abs((Ddata - Dsim)./max(Ddata, 1e-6)))*100;
MAPE_L = mean(abs((Ldata - Lsim)./max(Ldata, 1e-6)))*100;
MAPE_E = mean(abs((Edata - Esim)./max(Edata, 1e-6)))*100;

clc;
disp('======================================================');
disp('            HASIL ESTIMASI PARAMETER FINAL           ');
disp('======================================================');
fprintf('alpha_D  = %.7f;\n', aD);
fprintf('K_D      = %.7f;\n', KD);
fprintf('omega    = %.7f;\n', om);
fprintf('alpha_L  = %.7f;\n', aL);
fprintf('K_L      = %.7f;\n', KL);
fprintf('delta    = %.7f;\n', de);
fprintf('alpha_p  = %.7f;\n', ap);
fprintf('alpha_E  = %.7f;\n', aE);
fprintf('r_A      = %.7f;\n', rA);
fprintf('r_E      = %.7f;\n', rE);
fprintf('c_D      = %.7f;\n', cD);
fprintf('c_L      = %.7f;\n', cL);
fprintf('c_E = %.7f;\n', cE); 
fprintf('eta      = %.4f;\n', eta);
disp('======================================================');
disp('               EVALUASI AKURASI (MAPE)               ');
disp('======================================================');
fprintf('MAPE Deposito (D) = %.4f %%\n', MAPE_D);
fprintf('MAPE Kredit (L)   = %.4f %%\n', MAPE_L);
fprintf('MAPE Ekuitas (E)  = %.4f %%\n', MAPE_E);
fprintf('Rata-rata Error   = %.4f %%\n', GlobalBest.Cost);
disp('======================================================');

%% =============================
%% 6. VISUALISASI GRAFIK (DIPISAH)
%% =============================

fontAxis   = 14;   % ukuran angka sumbu
fontLabel  = 16;   % ukuran xlabel & ylabel
fontTitle  = 18;   % ukuran judul
fontLegend = 14;   % ukuran legend

% --- Grafik 1: Deposito ---
figure('Color', [1 1 1], 'Name', 'Simulasi Deposito');

plot(tdata, Ddata, 'ro', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize', 7); 
hold on;

plot(t, Dsim, 'b-', 'LineWidth', 2.5);

xlabel('Periode (Bulan)', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

ylabel('DPK', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

legend('Data Aktual', 'Model PSO', ...
    'Location', 'northwest', ...
    'FontSize', fontLegend);

set(gca, ...
    'FontSize', fontAxis, ...
    'LineWidth', 1.2);

grid on;
axis square;

% --- Grafik 2: Kredit ---
figure('Color', [1 1 1], 'Name', 'Simulasi Kredit');

plot(tdata, Ldata, 'go', ...
    'MarkerFaceColor', 'g', ...
    'MarkerSize', 7); 
hold on;

plot(t, Lsim, 'k-', 'LineWidth', 2.5);

xlabel('Periode (Bulan)', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

ylabel('Kredit', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

legend('Data Aktual', 'Model PSO', ...
    'Location', 'northwest', ...
    'FontSize', fontLegend);

set(gca, ...
    'FontSize', fontAxis, ...
    'LineWidth', 1.2);

grid on;
axis square;

% --- Grafik 3: Ekuitas ---
figure('Color', [1 1 1], 'Name', 'Simulasi Ekuitas');

plot(tdata, Edata, 'bo', ...
    'MarkerFaceColor', 'b', ...
    'MarkerSize', 7); 
hold on;

plot(t, Esim, 'm-', 'LineWidth', 2.5);

xlabel('Periode (Bulan)', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

ylabel('Ekuitas', ...
    'FontSize', fontLabel, ...
    'FontWeight', 'bold');

legend('Data Aktual', 'Model PSO', ...
    'Location', 'northwest', ...
    'FontSize', fontLegend);

set(gca, ...
    'FontSize', fontAxis, ...
    'LineWidth', 1.2);

grid on;
axis square;
%% =============================
%% 7. ANALISIS TITIK KESETIMBANGAN & EIGEN (UPDATED)
%% =============================

% --- 1. Definisi Konstanta Chi (Berdasarkan Persamaan Anda) ---
% chi_L = (1-eta)*r_L - r_A - c_L
% chi_D = (1-rho)*r_A + (omega-1)*r_D - c_D
% chi_E = r_A - r_E
chi_L = (1-eta)*r_L - rA - cL;
chi_D = (1-rho)*rA + (om-1)*r_D - cD;
chi_E = rA - rE;

% --- 2. Menentukan Kasus Berdasarkan Rasio Leverage ---
% Cek kondisi leverage akhir: E/(D+E)
current_ratio = Esim(end) / (Dsim(end)+ Esim(end));

if current_ratio >= lambda
    % KASUS I
    tau_D = (ap * chi_D) / ( cE-ap * chi_E);
    tau_L = (ap * chi_L-eta) / (cE-ap * chi_E);
    case_label = 'KASUS I (Leverage >= lambda)';
else
    % KASUS II
    term_lambda = (aE * lambda) / (1 - lambda);
    tau_D = (ap * chi_D + term_lambda) / (aE - ap * chi_E-cE);
    tau_L = (ap * chi_L - eta) / (aE - ap * chi_E-cE);
    case_label = 'KASUS II (Leverage < lambda)';
end

% --- 3. Menghitung Titik Kesetimbangan Interior (D*, L*, E*) ---
% Titik Kesetimbangan DPK
D_star = KD * (1 - om/aD);

% Titik Kesetimbangan Kredit (Solusi Non-Trivial)
B_val = (tau_L - 1) * KL - (1 - rho + tau_D) * D_star;
Delta_val = B_val^2 - 4 * (tau_L - 1) * ((eta + de*(1-eta))/aL - (1 - rho + tau_D)*D_star) * KL;

if Delta_val >= 0
    % Mengambil solusi L* yang realistik (biasanya dengan tanda +)
    L_star = (B_val + sqrt(Delta_val)) / (2 * (tau_L - 1));
else
    warning('Diskriminan Delta < 0. Titik kesetimbangan non-trivial tidak riil.');
    L_star = Lsim(end); 
end

% Titik Kesetimbangan Ekuitas
E_star = tau_D * D_star + tau_L * L_star;

% --- 4. Matriks Jacobian (Evaluasi pada D*, L*, E*) ---
% Gunakan rumus yang sudah kita buktikan negatif tadi
J11 = aD*(1-(2*D_star/KD))-om; 
J12 = 0;
J13 = 0;

% Baris 2 (Pastikan J22 juga dihitung dengan parameter terbaru)
term_L_KL = L_star/KL;
J21 = aL * L_star * (1-rho) * (1 - term_L_KL);
J22 = aL * ((1-rho)*D_star + E_star - 2*L_star + (3*L_star - 2*(1-rho)*D_star - 2*E_star)*term_L_KL) - (eta + de*(1-eta));
J23 = aL * L_star * (1 - term_L_KL);

% Baris 3
if current_ratio >= lambda
    J31 = ap * chi_D;
    J32 = ap * chi_L - eta;
    J33 = ap * chi_E - cE; % Tambahkan -aE jika ada peluruhan ekuitas
else
    J31 = ap * chi_D + (aE * lambda) / (1 - lambda);
    J32 = ap * chi_L - eta;
    J33 = ap * chi_E - aE-cE;
end

% SUSUN ULANG MATRIKSNYA
Jacobian_Mat = [J11 J12 J13; 
                J21 J22 J23; 
                J31 J32 J33];

% HITUNG ULANG EIGEN
eigen_vals = eig(Jacobian_Mat);

% --- 5. Tampilkan Hasil Analisis ---
fprintf('\n======================================================\n');
fprintf('           ANALISIS STABILITAS & EKUILIBRIUM         \n');
fprintf('======================================================\n');
fprintf('Kondisi Sistem : %s\n', case_label);
fprintf('D* (Interior)  : %.4f\n', D_star);
fprintf('L* (Interior)  : %.4f\n', L_star);
fprintf('E* (Interior)  : %.4f\n', E_star);
disp('------------------------------------------------------');
fprintf('Nilai Eigen 1  : %.6f\n', real(eigen_vals(1)));
fprintf('Nilai Eigen 2  : %.6f\n', real(eigen_vals(2)));
fprintf('Nilai Eigen 3  : %.6f\n', real(eigen_vals(3)));

if all(real(eigen_vals) < 0)
    fprintf('Status         : STABIL ASIMTOTIK\n');
else
    fprintf('Status         : TIDAK STABIL / SADEL\n');
end
disp('======================================================');

%% =============================
%% 8. VISUALISASI GRAFIK (AXIS SQUARE)
%% =============================
vars_data = {Ddata, Ldata, Edata};
vars_sim = {Dsim, Lsim, Esim};
vars_star = [D_star, L_star, E_star];
var_names = {'Deposito (D)', 'Kredit (L)', 'Ekuitas (E)'};
colors = {'r', 'g', 'b'};
line_styles = {'b-', 'k-', 'm-'};

for i = 1:3
    figure('Color', [1 1 1], 'Name', ['Analisis ' var_names{i}]);
    plot(tdata, vars_data{i}, [colors{i} 'o'], 'MarkerFaceColor', colors{i}); hold on;
    plot(t, vars_sim{i}, line_styles{i}, 'LineWidth', 2);
    yline(vars_star(i), '--', 'Equilibrium', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5);
    
    title(['Simulasi ' var_names{i}]);
    xlabel('Bulan'); ylabel('Juta Miliar');
    grid on; 
    axis square; % Membuat sumbu proporsional kotak
    legend('Data Aktual', 'Model PSO', 'Titik Setimbang', 'Location', 'best');
end