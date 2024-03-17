function [SNR,  spectrum , freq, pulseFreq, pulseBPM] = CalcSNR_Pulse(S,Fs)
% S - sinal in time. Fs - Frame rate (Hz)
  [ spectrum , freq] = abs_fft(S,Fs);

   maxDCfreq = 0.7;
   maxExpectedPulseFreq = 5;
   
   % ignore DC
   spectrum(freq < maxDCfreq ) = [];
   freq(freq < maxDCfreq ) = [];
   
   [ Signal , maxIdx ] = max(spectrum);
   if maxIdx == 1 
       error('Maximum FFT value found in unexpected frequency %g Hz', freq(maxIdx))
   end
       
   if freq(maxIdx) >  maxExpectedPulseFreq  
       error('Maximum FFT value found in unexpected frequency %g Hz', freq(maxIdx))
   end
   
   pulseFreq = freq(maxIdx);
   pulseBPM   = round(1/pulseFreq*60,1);
   
   Noise = mean( spectrum( freq > maxExpectedPulseFreq ) );
   SNR = Signal/Noise;

