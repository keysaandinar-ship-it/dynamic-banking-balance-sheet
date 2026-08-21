clc; clear; close all;

%% =============================
%% PENGATURAN FONT GLOBAL
%% =============================
set(groot,'defaultAxesFontSize',20);
set(groot,'defaultTextFontSize',20);
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultLineLineWidth',2.5);

%% =============================
%% LOAD DATA
%% =============================
data = readmatrix('Dataku.xlsx','Sheet','Sheet1');

% Normalisasi ke satuan juta
D_data = data(1:45,4)/1e6;   
L_data = data(1:45,5)/1e6;   
E_data = data(1:45,6)/1e6;   

T = length(L_data);

t_data = linspace(0,(T-1)/12,T);      
tspan  = linspace(0,(T-1)/12,1000);   

%% =============================
%% PARAMETER MODEL
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

%% =============================
%% KONDISI AWAL
%% =============================
L0 = L_data(1);
E0 = E_data(1);

%% =============================
%% INTERPOLASI DATA
%% =============================
D_interp = @(t) interp1(t_data,D_data,t,'spline','extrap');

E_interp = @(t) interp1(t_data,E_data,t,'spline','extrap');

L_interp = @(t) interp1(t_data,L_data,t,'pchip','extrap');

%% =============================
%% VARIASI PARAMETER λ
%% =============================

% Untuk grafik Loans
lambda_vals_L = [0.01 0.03 0.05 0.07];

% Untuk grafik Equity
lambda_vals_E = [0.01 0.19 0.22 0.24];

%% =============================
%% SIMULASI LOANS
%% =============================
figure('Color','w','Position',[100 100 950 750]);
hold on

colors_L = lines(length(lambda_vals_L));

for i = 1:length(lambda_vals_L)

    lambda = lambda_vals_L(i);

    ode_L = @(t,L) loan_model(t,L,...
        D_interp(t),E_interp(t),...
        alpha_L,K_L,eta,delta,rho,lambda);

    options = odeset('RelTol',1e-8,'AbsTol',1e-10);

    [t_sim,L_sim] = ode45(ode_L,tspan,L0,options);

    plot(t_sim,L_sim,...
        'LineWidth',3,...
        'Color',colors_L(i,:),...
        'DisplayName',sprintf('\\lambda = %.2f',lambda));

end

xlabel('Waktu (tahun)',...
    'FontSize',24,...
    'FontWeight','bold');

ylabel('Kredit',...
    'FontSize',24,...
    'FontWeight','bold');

title('Sensitivitas \lambda pada Kredit',...
    'FontSize',26,...
    'FontWeight','bold');

legend('show',...
    'Location','northwest',...
    'FontSize',18,...
    'FontWeight','bold');

set(gca,...
    'FontSize',20,...
    'LineWidth',1.8);

grid on
box on
axis square

%% =============================
%% SIMULASI EQUITY
%% =============================
figure('Color','w','Position',[100 100 950 750]);
hold on

E_all = [];

colors_E = lines(length(lambda_vals_E));

for i = 1:length(lambda_vals_E)

    lambda = lambda_vals_E(i);

    ode_E = @(t,E) equity_model(t,E,...
        D_interp(t),L_interp(t),...
        alpha_p,alpha_E,...
        r_A,r_E,...
        c_D,c_L,c_E,...
        r_L,r_D,...
        rho,omega,eta,lambda);

    [t_sim,E_sim] = ode45(ode_E,tspan,E0);

    E_all(:,i) = E_sim;

    plot(t_sim,E_sim,...
        'LineWidth',3,...
        'Color',colors_E(i,:),...
        'DisplayName',sprintf('\\lambda = %.2f',lambda));

end

xlabel('Waktu (tahun)',...
    'FontSize',24,...
    'FontWeight','bold');

ylabel('Ekuitas',...
    'FontSize',24,...
    'FontWeight','bold');

title('Sensitivitas \lambda pada Ekuitas',...
    'FontSize',26,...
    'FontWeight','bold');

legend('show',...
    'Location','northwest',...
    'FontSize',18,...
    'FontWeight','bold');

set(gca,...
    'FontSize',20,...
    'LineWidth',1.8);

grid on
box on
axis square

%% =============================
%% FUNCTION MODEL LOANS
%% =============================
function dLdt = loan_model(~,L,D,E,...
    alpha_L,K_L,eta,delta,rho,lambda)

A = max((1-rho)*D + E - L,1e-6);

dLdt = alpha_L*A*L*(1 - L/K_L) ...
       - (eta + delta*(1-eta))*L ...
       - lambda*L;

end

%% =============================
%% FUNCTION MODEL EQUITY
%% =============================
function dEdt = equity_model(~,E,D,L,...
    alpha_p,alpha_E,...
    r_A,r_E,...
    c_D,c_L,c_E,...
    r_L,r_D,...
    rho,omega,eta,lambda)

Pi = ((1-eta)*r_L-r_A-c_L)*L + ...
     ((1-rho)*r_A+(omega-1)*r_D-c_D)*D + ...
     (r_A-r_E)*E;

if E/(D+E) >= lambda
    l = 0;
else
    l = alpha_E*((lambda*D)/(1-lambda)-E);
end

dEdt = alpha_p*Pi - eta*L + l - c_E*E;

end