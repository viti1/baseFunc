function [SNR, Pulse] = CalcSNR_Pulse(S,Fs)
    noiseTh = 5; % Hz
    [ FFT , f] = abs_fft(S,Fs);

    Noise = mean(FFT(f > noiseTh));

    pulthMinTh = 0.3;
    cutSpectrum = FFT(f > pulthMinTh);
    cut_f = f(f > pulthMinTh);
    [ Signal, max_idx ] = max(cutSpectrum);
    Pulse = cut_f(max_idx);

    SNR = Signal/Noise;


    
