clear
close all
clc

%% UCA Parametreleri
N = 8; % Anten eleman sayısı
r = 0.1; % Daire yarıçapı (metre)

% Anten pozisyonları
theta = linspace(0, 2*pi, N+1);
theta = theta(1:end-1); % 0'dan 2*pi'ye kadar N eşit aralık
x = r * cos(theta);
y = r * sin(theta);

% Plot Anten Dizisi
figure('Position', [100, 800, 500, 400]);
plot(x, y, 'bo');
hold on;
plot([x, x(1)], [y, y(1)], 'b-');
xlabel('X (m)');
ylabel('Y (m)');
title('UCA Antenna Array');
grid on;
axis equal;

%% OAM Modları
L = 2; % Topolojik yük (OAM modu)
lambda = 0.03; % Dalga boyu (metre)
k = 2 * pi / lambda; % Dalga sayısı

% OAM Faz Profili
oam_phase = exp(1i * L * theta);

% OAM Faz Profilini 3D olarak plot edelim
figure('Position', [600, 800, 500, 400]);
scatter3(x, y, angle(oam_phase), 'filled');
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Phase Angle (radians)');
title(['OAM Mode Phase Profile (3D) (L = ' num2str(L) ')']);
grid on;

%% OAM Sinyalini AWGN Kanalından Geçirme
snr = 6; % SNR değeri (dB cinsinden)
oam_signal = oam_phase;

% AWGN kanalı üzerinden geçirme
oam_signal_noisy = awgn(oam_signal, snr, 'measured');

% Bozulan Faz Açısını Hesapla ve Plot Et
figure('Position', [1100, 800, 650, 400]);
scatter3(x, y, angle(oam_signal), 20, 'b', 'filled'); % Orijinal veriyi küçük boyutta mavi olarak plot et
hold on;
scatter3(x, y, angle(oam_signal_noisy), 50, 'r', 'filled'); % Bozulmuş datayı büyük boyutta kırmızı olarak plot et
xlabel('X (m)');
ylabel('Y (m)');
zlabel('Phase Angle (radians)');
title(['OAM Mode Phase Profile After AWGN Channel (3D) (L = ' num2str(L) ')']);
grid on;
legend('Original', 'Distorted');
hold off;

%% Faz Açısındaki Bozulma
phase_error = angle(oam_signal_noisy) - angle(oam_signal);
phase_error = wrapToPi(phase_error); % Faz hatasını [-pi, pi] aralığına getir

% Faz Bozulmasını Plot Et
figure('Position', [1750, 800, 500, 400]);
plot(theta, phase_error, 'r-o');
xlabel('Theta (radians)');
ylabel('Phase Error (radians)');
title('Phase Distortion in OAM Phase Angle');
grid on;

%% Kanal Matrisini Hesapla
d = pdist([x' y']);
d = squareform(d); % Antenler arası mesafeler matrisi

% OAM sinyali faz profilini kanala entegre et
H = exp(-1i * k * d) .* (oam_signal.' * conj(oam_signal)); % Basit kanal modeli (Line of Sight) ve OAM faz profili ile

% AWGN kanalı etkisini ekle
snr = 10; % SNR değeri (dB cinsinden)
H_noisy = awgn(H, snr, 'measured'); % Kanal matrisine AWGN ekle

% Plot Kanal Matrisinin Gerçek ve İmajiner Kısımları
figure('Position', [100, 300, 1000, 400]);
subplot(1, 2, 1);
imagesc(real(H_noisy));
colorbar;
title('Real Part of Channel Matrix with AWGN');
xlabel('Antenna Element');
ylabel('Antenna Element');

subplot(1, 2, 2);
imagesc(imag(H_noisy));
colorbar;
title('Imaginary Part of Channel Matrix with AWGN');
xlabel('Antenna Element');
ylabel('Antenna Element');

% Renk skalasını belirleyelim
clim_lim_real = [-1, 1] * max(max(abs(real(H_noisy))));
clim_lim_imag = [-1, 1] * max(max(abs(imag(H_noisy))));


%% LMS Kanal Tahmin Algoritması Parametreleri
mu = 0.01; % Öğrenme oranı
H_est = zeros(N, N); % Başlangıç kanal matrisi tahmini

% LMS Algoritması
for iter = 1:1000
    % Hataya dayalı güncelleme
    e = H_noisy - H_est; % Hata matrisi
    H_est = H_est + mu * e; % LMS güncellemesi
end

% Tahmin Edilen Kanal Matrisini Plot
figure('Position', [1100, 300, 1000, 400]);
subplot(1, 2, 1);
imagesc(real(H_est));
colorbar;
title('Estimated Real Part of Channel Matrix with AWGN');
xlabel('Antenna Element');
ylabel('Antenna Element');
clim(clim_lim_real);

subplot(1, 2, 2);
imagesc(imag(H_est));
colorbar;
title('Estimated Imaginary Part of Channel Matrix with AWGN');
xlabel('Antenna Element');
ylabel('Antenna Element');
clim(clim_lim_imag);

%% Hata Matrisi Hesapla
error_matrix = abs(H_noisy - H_est);

% Ortalama Hata
mean_error = mean(error_matrix(:));

disp(['Mean Error with AWGN: ' num2str(mean_error)]);

%% Hata Matrisi Hesapla
error_matrix = abs(H - H_est);

% Ortalama Hata
mean_error = mean(error_matrix(:));

disp(['Mean Error: ' num2str(mean_error)]);
