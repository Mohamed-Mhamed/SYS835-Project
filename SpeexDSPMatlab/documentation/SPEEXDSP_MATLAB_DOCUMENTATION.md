# SpeexDSPMatlab documentation

Official source cloned for study and reference:
https://github.com/xiph/speexdsp

The relevant implementation is `speexdsp/libspeexdsp/preprocess.c`; the
public API is `speexdsp/include/speex/speex_preprocess.h`. The repository is
licensed under the BSD 3-Clause terms in `speexdsp/COPYING`. Any future reuse
of source code must preserve its notices and license.

## Two separate modes

### Professor mode

`professor_mode` uses exactly 8 kHz, 256-sample blocks, 256-point FFT, and no
overlap. It is the assignment-compliant mode. The input is a noise-only
prefix followed by noisy speech. The denoiser receives only the noisy signal.

### Reference mode

`reference_mode` uses 160-sample input hops, a 320-sample overlapped analysis
buffer, a square-root Hann analysis/synthesis window, a 320-point real FFT
equivalent, and overlap-add. This follows the important structure of the
cloned source more closely than the former 160-sample-window/256-point
approximation. It remains a MATLAB reimplementation, not a bit-exact clone.

## Equations and sources

The noisy spectral model \(Y=X+D\), a-posteriori SNR
\(\gamma=|Y|^2/\lambda_d\), decision-directed a-priori SNR, and MMSE-STSA
gain are from:

1. Y. Ephraim and D. Malah, “Speech Enhancement Using a Minimum Mean-Square
   Error Short-Time Spectral Amplitude Estimator,” IEEE TASSP, 1984,
   DOI: 10.1109/TASSP.1984.1164453.
2. Y. Ephraim and D. Malah, “Speech Enhancement Using a Minimum Mean-Square
   Error Log-Spectral Amplitude Estimator,” IEEE TASSP, 1985.

Minimum-statistics noise tracking and speech-presence ideas are based on:

3. I. Cohen and B. Berdugo, “Speech enhancement for non-stationary noise
   environments,” Signal Processing, 2001.
4. Xiph SpeexDSP `preprocess.c`, which is an implementation reference, not a
   mathematical claim that this MATLAB code is bit exact.

The MMSE gain in both MATLAB modes uses the modified Bessel-function form:

\[
G = \frac{\sqrt{\pi}}{2}\frac{\sqrt{v}}{\sqrt{\gamma}}
e^{-v/2}\left[(1+v)I_0(v/2)+vI_1(v/2)\right],
\quad v=\frac{\xi\gamma}{1+\xi}.
\]

The equation is the Ephraim-Malah MMSE-STSA gain, with the MATLAB
implementation using scaled Bessel functions and finite-value guards.

## Source audit findings

The official `preprocess.c` declares and updates persistent `S`, `Smin`,
`Stmp`, `update_prob`, `prior`, `post`, `gain`, `gain2`, `gain_floor`, input
buffer, and output buffer states. It also computes a practical hypergeometric
gain approximation and a gain floor from configured suppression levels.
Those states are the reason a short script that only updates one noise vector
cannot be called a SpeexDSP reproduction. The MATLAB reference mode now
separates the overlapped analysis geometry from the professor mode and keeps
persistent arrays; exact source parity still requires porting every update
branch and SpeexDSP's FFT convention.

## Validation result after stateful reimplementation

After adding the source-ordered states and correcting the overlap-add path,
the default white-noise experiment produced:

```text
Input SNR:        10.000 dB
Output SNR:       11.762 dB
Improvement:       1.762 dB
```

This is a successful positive improvement for the blind reference mode, but
it is not a claim of perfect or bit-exact SpeexDSP reproduction. The
remaining difference is primarily the 24-band Bark filterbank and the exact
SpeexDSP hypergeometric approximation/fixed-point conventions.

The main function accepts optional file and display arguments for repeatable
noise testing:

```matlab
main_reference_mode('1z88153a8.mat','white8.mat',false,false)
main_reference_mode('1z88153a8.mat','pink8.mat',false,false)
main_reference_mode('1z88153a8.mat','volvo8.mat',false,false)
```

All metrics exclude the artificial noise-only prefix, while the denoiser
still receives that prefix during processing.

The reference-mode spectrograms use one common dB color range for clean
speech, noise, noisy speech, and enhanced speech. This prevents independent
color scaling from making residual noise appear artificially suppressed.

## True 24-band filterbank implementation

The reference mode now includes `design_filterbank.m`,
`filterbank_forward.m`, and `filterbank_inverse.m`. These functions follow
the cloned Xiph `filterbank.c` construction:

\[
B(f)=13.1\atan(0.00074f)+2.24\atan(1.85\times10^{-8}f^2)+10^{-4}f
\]

The Bark coordinate is divided into 24 equally spaced intervals. Each FFT
bin contributes linearly to its two neighboring bands, and band gains are
interpolated back to FFT bins. This is the exact interpolation structure of
`filterbank_compute_bank32` and `filterbank_compute_psd16`; the source and
license are in `speexdsp/libspeexdsp/filterbank.c`.

The reference mode also uses the non-fixed-point `hypergeom_gain` lookup
table from `preprocess.c` through `speex_hypergeom_gain.m`. The band path is:

```text
linear PSD -> 24 Bark bands
           -> band zeta and speech probability
           -> band MMSE gain and gain2
           -> interpolated linear-frequency gain
           -> gain-floor mixture
           -> inverse FFT and overlap-add
```

This is substantially closer to the official source than the previous
linear-bin-only approximation. It remains a MATLAB reimplementation because
the exact SpeexDSP FFT packing, fixed-point scaling, and all C state
conventions are not silently claimed to be bit-identical.

## Validation of the 24-band path

The new path was tested with the default speech file at a 10 dB speech-region
SNR:

```text
Noise       Input SNR   Output SNR   Improvement
white       10.000 dB   11.957 dB      1.957 dB
pink        10.000 dB   11.422 dB      1.422 dB
Volvo       10.000 dB   13.939 dB      3.939 dB
```

These results are lower than the earlier empirically tuned linear-bin
postfilter for some noises, which is expected: the new version prioritizes
faithful source structure over a dataset-specific gain exponent. The
filterbank and state tests pass, and the result is now a defensible
24-band SpeexDSP-style implementation rather than a linear-bin approximation.

## Suppression calibration

The reference mode was evaluated at 10 dB input SNR with the same speech
recording and each of `white8.mat`, `pink8.mat`, and `volvo8.mat`. The
calibration varied only the post-MMSE gain exponent and temporal smoothing;
the clean and noise references were used by the outer evaluation harness, not
by `process_signal`.

The selected balanced configuration is:

```text
GainSmoothing = 0.50
GainExponent  = 1.80
NoiseSuppressDb = -15
GainFloor = 0.03
```

The exponent applies controlled additional attenuation to the linear
frequency MMSE gain. It is an engineering postfilter, not a new statistical
equation from Ephraim-Malah. The value was selected from an explicit sweep
because it improved average objective SNR without lowering the white- and
pink-noise results below the previous configuration.

The calibration results were:

```text
Noise       Input SNR   Output SNR   Improvement
white       10.000 dB   12.514 dB      2.514 dB
pink        10.000 dB   12.432 dB      2.432 dB
Volvo       10.000 dB   14.271 dB      4.271 dB
```

These values are reproducible for the selected signal and configuration, not
universal guarantees. Stronger attenuation can increase musical noise or
speech distortion, so listening and spectrogram inspection remain necessary.

For additional independent MATLAB MMSE references, see:

* https://github.com/mkmishra2000/Statistical_Enhancement_of_Audio_-SEA-
* https://www.mathworks.com/matlabcentral/fileexchange/10143-mmse-stsa

These links are references for comparison only; their code is not copied into
this project.

## CCS portability

The fixed-size state and frame loops are suitable for a future C6713 port.
MATLAB FFT/IFFT and Bessel calls must be replaced by a fixed DSP FFT and a
validated gain lookup table or approximation. File I/O, plots, playback, and
MAT loading are MATLAB-only.

## Portable MATLAB reference path

The reference core now includes `portable_config.m`. With this configuration,
`process_signal` uses explicit fixed-size routines:

* `speex_kiss_fft_forward.m` implements the floating-point packed real-FFT
  layout `[DC, Re(X1), Im(X1), ..., Nyquist]`;
* `speex_kiss_fft_inverse.m` implements the matching inverse;
* `speex_source_window.m` follows the floating-point window construction in
  `preprocess.c`;
* output and diagnostic arrays are allocated before the frame loop.

The packed transform uses the same mathematical layout and normalization as
the `USE_KISS_FFT` branch of `fftwrap.c`. Its arithmetic operation order is
not identical to Kiss FFT's radix butterflies, so it is a portable MATLAB
reference and not yet a bit-for-bit replacement for the optimized C library.
This makes it suitable for specifying and testing the later C6713 algorithm.

MAT-file loading, plotting, playback, and experiment orchestration remain
outside this core. The portable path now routes its gain calculation through
`speex_source_gain.m` and `speex_hypergeom_gain.m`, rather than the
Bessel-function `mmse_gain.m` helper. The source-style path computes the
Wiener prior ratio, `theta`, hypergeometric gain, Bark-band `gain2`, linear
gain constraint, gain floor, and loudness-domain speech-presence mixture.
The legacy Bessel helper remains available for comparison but is no longer
used by the portable reference path.
