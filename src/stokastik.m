close all force
clc
clear
%% =============================
%% PENGATURAN FONT GLOBAL
%% =============================
set(groot,'defaultAxesFontSize',20);
set(groot,'defaultTextFontSize',20);
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultLineLineWidth',2.5);

%% =============================
%% 1. LOAD DATA ASLI
%% =============================
% Pastikan file Dataku.xlsx ada di folder yang sama
data_riil = readmatrix('Dataku.xlsx','Sheet','Sheet1');

% Penyesuaian Satuan
scale_factor = 1e6;

D0 = data_riil(1,4)/scale_factor;   
L0 = data_riil(1,5)/scale_factor;   
E0 = data_riil(1,6)/scale_factor;   

%% =============================
%% 2. PARAMETER MODEL
%% =============================
alpha_D  = 0.0157418;
K_D      = 11.0122763;
omega    = 0.0010901;

alpha_L  = 0.0253571;
K_L      = 13.7465828;
delta    = 0.0010000;

alpha_p  = 0.4791832;
alpha_E  = 0.0030004;

r_A      = 0.0177721;
r_E      = 0.0166156;

c_D      = 0.0005957;
c_L      = 0.0001000;
c_E      = 0.0170452;

r_L      = 0.09141389373;
r_D      = 0.01955164208;

rho      = 0.075;
eta      = 0.0254;
lambda   = 0.03;

%% =============================
%% INTENSITAS NOISE
%% =============================
sigma_omega = 0.011410209; 
sigma_eta   = 0.0032;

%% =============================
%% 3. KONFIGURASI SIMULASI
%% =============================
dt = 1;

T = 12*30;

N = floor(T/dt);

t = (0:N-1)/12;

num_sim = 1000;

D_all = zeros(num_sim, N);
L_all = zeros(num_sim, N);
E_all = zeros(num_sim, N);

%% =============================
%% 4. SIMULASI MONTE CARLO
%% EULER-MARUYAMA
%% =============================
for s = 1:num_sim

    D_all(s,1) = D0;
    L_all(s,1) = L0;
    E_all(s,1) = E0;

    for i = 1:N-1

        % Random shock
        dW_omega = randn * sqrt(dt);
        dW_eta   = randn * sqrt(dt);

        % Fungsi injeksi modal
        if E_all(s,i)/(D_all(s,i) + E_all(s,i)) < lambda

            ell = alpha_E * ...
                ((lambda * D_all(s,i)) / (1 - lambda) ...
                - E_all(s,i));

        else

            ell = 0;

        end

        % Fungsi profit
        Pi = ((1-eta)*r_L - r_A - c_L) ...
             * L_all(s,i) ...
           + ((1-rho)*r_A + (omega-1)*r_D - c_D) ...
             * D_all(s,i) ...
           + (r_A - r_E) ...
             * E_all(s,i);

        %% =====================
        %% UPDATE STOKASTIK
        %% =====================

        % Deposits
        D_all(s,i+1) = D_all(s,i) ...
            + (alpha_D*D_all(s,i) ...
            * (1 - D_all(s,i)/K_D) ...
            - omega*D_all(s,i))*dt ...
            - sigma_omega ...
            * D_all(s,i) ...
            * dW_omega;

        % Loans
        drift_L = (alpha_L ...
                  *((1-rho)*D_all(s,i) ...
                  + E_all(s,i) ...
                  - L_all(s,i)) ...
                  *(1 - L_all(s,i)/K_L) ...
                  - (1-delta)*eta ...
                  - delta) ...
                  * L_all(s,i);

        L_all(s,i+1) = L_all(s,i) ...
            + drift_L*dt ...
            - (1-delta) ...
            * sigma_eta ...
            * L_all(s,i) ...
            * dW_eta;

        % Equity
        E_all(s,i+1) = E_all(s,i) ...
            + (alpha_p*Pi ...
            - eta*L_all(s,i) ...
            - c_E*E_all(s,i) ...
            + ell)*dt ...
            - sigma_eta ...
            * L_all(s,i) ...
            * dW_eta*(alpha_p*r_L+1)...
            + alpha_p*sigma_omega*r_D*D_all(s,i)*dW_omega;

    end
end

%% =============================
%% SOLUSI DETERMINISTIK
%% =============================

D_det = zeros(1,N);
L_det = zeros(1,N);
E_det = zeros(1,N);

D_det(1) = D0;
L_det(1) = L0;
E_det(1) = E0;

for i = 1:N-1

    % Fungsi injeksi modal
    if E_det(i)/(D_det(i)+E_det(i)) < lambda

        ell = alpha_E * ...
            ((lambda * D_det(i))/(1-lambda) ...
            - E_det(i));

    else

        ell = 0;

    end

    % Profit
    Pi = ((1-eta)*r_L - r_A - c_L) ...
         * L_det(i) ...
       + ((1-rho)*r_A + (omega-1)*r_D - c_D) ...
         * D_det(i) ...
       + (r_A-r_E) ...
         * E_det(i);

    % Deterministik
    D_det(i+1) = D_det(i) ...
        + (alpha_D*D_det(i) ...
        * (1 - D_det(i)/K_D) ...
        - omega*D_det(i))*dt;

    drift_L = (alpha_L ...
              *((1-rho)*D_det(i) ...
              + E_det(i) ...
              - L_det(i)) ...
              *(1 - L_det(i)/K_L) ...
              - (eta + delta*(1-eta))) ...
              * L_det(i);

    L_det(i+1) = L_det(i) ...
        + drift_L*dt;

    E_det(i+1) = E_det(i) ...
        + (alpha_p*Pi ...
        - eta*L_det(i) ...
        - c_E*E_det(i) ...
        + ell)*dt;

end

D_meanMC = mean(D_all,1);
L_meanMC = mean(L_all,1);
E_meanMC = mean(E_all,1);

%% =============================
%% 5. VISUALISASI (STOKASTIK + DET + MEAN MC)
%% =============================

titles = {'DPK', ...
          'Kredit', ...
          'Ekuitas'};

data_cell = {D_all, L_all, E_all};
det_cell  = {D_det, L_det, E_det};

% solusi rata-rata Monte Carlo
meanMC_cell = {mean(D_all,1), ...
               mean(L_all,1), ...
               mean(E_all,1)};

for k = 1:3

    figure('Color','w',...
           'Name',titles{k},...
           'Position',[100 100 1000 800]);

    % =============================
    % lintasan stokastik (beberapa sampel saja)
    % =============================
    p1 = plot(t, data_cell{k}(1:50,:)', ...
        'Color',[0.7 0.7 0.7 0.2], ...
        'LineWidth',0.8);
    hold on;

    % =============================
    % mean Monte Carlo
    % =============================
    p2 = plot(t, meanMC_cell{k}, ...
        'b', ...
        'LineWidth',3.5);

    % =============================
    % deterministik
    % =============================
    p3 = plot(t, det_cell{k}, ...
        'r--', ...
        'LineWidth',3.5);

    title(titles{k},...
        'FontSize',28,...
        'FontWeight','bold');

    xlabel('Waktu (Tahun)',...
        'FontSize',24,...
        'FontWeight','bold');

    ylabel('Nilai',...
        'FontSize',24,...
        'FontWeight','bold');

    set(gca,...
        'FontSize',22,...
        'LineWidth',1.8);

    axis square
    grid on
    box on

    legend([p1(1), p2, p3],...
        {'Lintasan Stokastik','Solusi Rata-Rata','Deterministik'},...
        'Location','northwest',...
        'FontSize',18,...
        'FontWeight','bold');

end

%% =============================
%% 6. ANALISIS CV
%% =============================
D_mean = mean(D_all);
L_mean = mean(L_all);
E_mean = mean(E_all);
cv_data = {(std(D_all)./D_mean)*100,...
           (std(L_all)./L_mean)*100,...
           (std(E_all)./E_mean)*100};

cv_titles = {'CV DPK',...
             'CV Kredit',...
             'CV Ekuitas'};

cv_colors = {'b','g','m'};

for m = 1:3

    figure('Color','w',...
           'Name',cv_titles{m},...
           'Position',[100 100 1000 800]);

    plot(t,...
         cv_data{m},...
         cv_colors{m},...
         'LineWidth',3.5);

    title(cv_titles{m},...
        'FontSize',28,...
        'FontWeight','bold');

    xlabel('Waktu (Tahun)',...
        'FontSize',24,...
        'FontWeight','bold');

    ylabel('CV (%)',...
        'FontSize',24,...
        'FontWeight','bold');

    set(gca,...
        'FontSize',22,...
        'LineWidth',1.8);

    axis square
    grid on
    box on

    % Label nilai akhir
    text(t(end),...
        cv_data{m}(end),...
        sprintf(' %.2f%%',cv_data{m}(end)),...
        'FontWeight','bold',...
        'FontSize',20,...
        'VerticalAlignment','bottom');

end