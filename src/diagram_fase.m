clear; clc; close all;

%% ======================================================
%% 1. PARAMETER HASIL ESTIMASI
%% ======================================================
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

%% ======================================================
%% PENGATURAN FONT GLOBAL
%% ======================================================
set(groot,'defaultAxesFontSize',18);
set(groot,'defaultTextFontSize',18);
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultLineLineWidth',2);

%% ======================================================
%% 2. SIMULASI UNTUK MENCARI TITIK AKHIR (NUMERIK)
%% ======================================================
tspan = [0 5000];
opts = odeset('RelTol',1e-8,'AbsTol',1e-10);

[~, y_conv] = ode15s(@(t,y) bank_system_ode(t, y, alpha_D, K_D, omega, ...
    alpha_L, K_L, eta, delta, alpha_p, alpha_E, r_A, r_E, ...
    c_D, c_L, c_E, r_L, r_D, rho, lambda), ...
    tspan, [7.6 5.0 0.1], opts);

D_star_num = y_conv(end,1);
L_star_num = y_conv(end,2);
E_star_num = y_conv(end,3);

LDR = L_star_num/D_star_num;
Leverage = E_star_num/(D_star_num+E_star_num);

fprintf('Titik Setimbang Numerik (Hasil Simulasi):\n');
fprintf('D* = %.4f | L* = %.4f | E* = %.4f | LDR = %.4f | Leverage = %.4f\n', ...
    D_star_num, L_star_num, E_star_num, LDR, Leverage);

%% ======================================================
%% 3. VISUALISASI 3D
%% ======================================================
n_traj = 15;

figure('Color','w','Name','Phase Portrait 3D', ...
       'Position',[100 100 900 700]);
hold on;

for i = 1:n_traj

    D0 = D_star_num * (0.2 + 1.6*rand);
    L0 = L_star_num * (0.2 + 1.6*rand);
    E0 = E_star_num * (0.1 + 3.0*rand);

    [~, y] = ode15s(@(t,y) bank_system_ode(t, y, alpha_D, K_D, omega, ...
        alpha_L, K_L, eta, delta, alpha_p, alpha_E, r_A, r_E, ...
        c_D, c_L, c_E, r_L, r_D, rho, lambda), ...
        tspan, [D0 L0 E0], opts);

    plot3(y(:,1), y(:,2), y(:,3), 'LineWidth', 2.5);
end

h_star = plot3(D_star_num, L_star_num, E_star_num, ...
    'ro', 'MarkerFaceColor','r', 'MarkerSize',16);

h_traj = plot3(nan, nan, nan, 'k-', 'LineWidth',2.5);

xlabel('DPK', ...
    'FontSize',22, ...
    'FontWeight','bold');

ylabel('Kredit', ...
    'FontSize',22, ...
    'FontWeight','bold');

zlabel('Ekuitas', ...
    'FontSize',22, ...
    'FontWeight','bold');


set(gca, ...
    'FontSize',18, ...
    'LineWidth',1.5);

grid on;
view(135,30);
axis tight;
axis square;

%% ======================================================
%% 4. PLOT 2D PROYEKSI
%% ======================================================

% ======================================================
% D vs L
% ======================================================
figure('Color','w','Position',[100 100 850 700]);
hold on;

for i = 1:n_traj

    D0 = D_star_num * (0.2 + 1.6*rand);
    L0 = L_star_num * (0.2 + 1.6*rand);

    [~,y] = ode15s(@(t,y) bank_system_ode(t, y, alpha_D, K_D, omega, ...
        alpha_L, K_L, eta, delta, alpha_p, alpha_E, r_A, r_E, ...
        c_D, c_L, c_E, r_L, r_D, rho, lambda), ...
        tspan, [D0 L0 E_star_num], opts);

    plot(y(:,1), y(:,2), 'b', 'LineWidth',2.5);
end

h_star1 = plot(D_star_num, L_star_num, ...
    'ro', 'MarkerFaceColor','r', 'MarkerSize',14);

h_traj1 = plot(nan, nan, 'b-', 'LineWidth',2.5);

legend([h_traj1, h_star1], ...
    {'Trajektori', 'Titik Setimbang'}, ...
    'Location','northwest', ...
    'FontSize',16, ...
    'FontWeight','bold');

xlabel('DPK', 'FontSize',22, 'FontWeight','bold');
ylabel('Kredit', 'FontSize',22, 'FontWeight','bold');

set(gca,'FontSize',18,'LineWidth',1.5);

grid on;
axis square;


% ======================================================
% D vs E
% ======================================================
figure('Color','w','Position',[100 100 850 700]);
hold on;

for i = 1:n_traj

    D0 = D_star_num * (0.2 + 1.6*rand);
    E0 = E_star_num * (0.1 + 3.0*rand);

    [~,y] = ode15s(@(t,y) bank_system_ode(t, y, alpha_D, K_D, omega, ...
        alpha_L, K_L, eta, delta, alpha_p, alpha_E, r_A, r_E, ...
        c_D, c_L, c_E, r_L, r_D, rho, lambda), ...
        tspan, [D0 L_star_num E0], opts);

    plot(y(:,1), y(:,3), ...
        'Color', [0 0.5 0], ...
        'LineWidth',2.5);
end

h_star2 = plot(D_star_num, E_star_num, ...
    'ro', 'MarkerFaceColor','r', 'MarkerSize',14);

h_traj2 = plot(nan, nan, ...
    'Color', [0 0.5 0], ...
    'LineWidth',2.5);

legend([h_traj2, h_star2], ...
    {'Trajektori', 'Titik Setimbang'}, ...
    'Location','northwest', ...
    'FontSize',16, ...
    'FontWeight','bold');

xlabel('DPK', 'FontSize',22, 'FontWeight','bold');
ylabel('Ekuitas', 'FontSize',22, 'FontWeight','bold');


set(gca,'FontSize',18,'LineWidth',1.5);

grid on;
axis square;


% ======================================================
% L vs E
% ======================================================
figure('Color','w','Position',[100 100 850 700]);
hold on;

for i = 1:n_traj

    L0 = L_star_num * (0.2 + 1.6*rand);
    E0 = E_star_num * (0.1 + 3.0*rand);

    [~,y] = ode15s(@(t,y) bank_system_ode(t, y, alpha_D, K_D, omega, ...
        alpha_L, K_L, eta, delta, alpha_p, alpha_E, r_A, r_E, ...
        c_D, c_L, c_E, r_L, r_D, rho, lambda), ...
        tspan, [D_star_num L0 E0], opts);

    plot(y(:,2), y(:,3), 'm', 'LineWidth',2.5);
end

h_star3 = plot(L_star_num, E_star_num, ...
    'ro', 'MarkerFaceColor','r', 'MarkerSize',14);

h_traj3 = plot(nan, nan, 'm-', 'LineWidth',2.5);

legend([h_traj3, h_star3], ...
    {'Trajektori', 'Titik Setimbang'}, ...
    'Location','northwest', ...
    'FontSize',16, ...
    'FontWeight','bold');

xlabel('Kredit', 'FontSize',22, 'FontWeight','bold');
ylabel('Ekuitas', 'FontSize',22, 'FontWeight','bold');


set(gca,'FontSize',18,'LineWidth',1.5);

grid on;
axis square;


%% ======================================================
%% 5. FUNGSI MODEL (SISTEM ODE)
%% ======================================================
function dydt = bank_system_ode(~, y, ...
    aD, KD, om, aL, KL, eta, de, ap, aE, ...
    rA, rE, cD, cL, cE, rL, rD, rho, lambda)

    D = max(y(1), 1e-6);
    L = max(y(2), 1e-6);
    E = max(y(3), 1e-6);

    % Assets
    A = max((1-rho)*D + E - L, 1e-6);

    % Profit (Pi)
    Pi = ((1-eta)*rL - rA - cL)*L + ...
         ((1-rho)*rA + (om-1)*rD - cD)*D + ...
         (rA - rE)*E;

    % Persamaan Differensial
    dDdt = aD*D*(1 - D/KD) - om*D;

    dLdt = aL*A*L*(1 - L/KL) - (eta + de*(1-eta))*L;

    % Regulasi Modal
    ratio = E/(D+E);

    if ratio >= lambda

        dEdt = ap*Pi - eta*L - cE*E;

    else

        l_adj = aE*((lambda*D/(1-lambda)) - E);

        dEdt = ap*Pi - eta*L + l_adj - cE*E;
    end

    dydt = [dDdt; dLdt; dEdt];
end