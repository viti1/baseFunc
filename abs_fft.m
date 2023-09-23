function [ P1 , P2 ] = abs_fft(S,Fs)

T = 1/Fs;             % Sampling period       
L = length(S);             % Length of signal
t = (0:L-1)*T;        % Time vector

figure; 
% Plot the noisy signal in the time domain. It is difficult to identify the frequency components by looking at the signal X(t). 
subplot(2,1,1)
plot(t,S)
title('Original Signal')
xlabel('t[s]')
ylabel('S(t)')

% Compute the Fourier transform of the signal. 
Y = fft(S);

% Compute the two-sided spectrum P2. Then compute the single-sided spectrum P1 based on P2 and the even-valued signal length L.
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% Define the frequency domain f and plot the single-sided amplitude spectrum P1. The amplitudes are not exactly at 0.7 and 1, as expected, because of the added noise. On average, longer signals produce better frequency approximations.
f = Fs*(0:(L/2))/L;
subplot(2,1,2)

plot(f,P1(1:end)) 
title('Single-Sided Amplitude Spectrum of S(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

