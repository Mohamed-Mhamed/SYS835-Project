# SpeexDSP ReproductionMode: Complete Technical Documentation

## 1. Purpose and scope

`ReproductionMode` is an independent MATLAB project for reproducing the
floating-point noise-suppression path of the cloned Xiph SpeexDSP source.
It is separate from the assignment-compatible `professor_mode` and from the
earlier experimental `reference_mode`.

The project has two outputs:

1. **Source-faithful output**: follows the SpeexDSP processing order and
   equations as closely as this MATLAB implementation currently can.
2. **Selected quality output**: uses the same source equations with a stronger
   `noise_suppress` control for listening experiments.

The quality output must not be used as the numerical reference for a future
CCS implementation.

The implementation is based on the cloned repository:

* `speexdsp/libspeexdsp/preprocess.c`;
* `speexdsp/libspeexdsp/filterbank.c`;
* `speexdsp/libspeexdsp/filterbank.h`;
* `speexdsp/libspeexdsp/fftwrap.c`;
* `speexdsp/libspeexdsp/kiss_fftr.c`;
* `speexdsp/libspeexdsp/kiss_fft.c`;
* `speexdsp/include/speex/speex_preprocess.h`;
* `speexdsp/COPYING`.

The source is BSD-licensed. Any future C reuse must preserve the copyright and
license notices.

## 2. Relationship to the professor assignment

The professor-compatible experiment requires 8 kHz, 256-sample blocks,
256-point FFT, hop size 256, and no overlap. That behavior remains in the
parent project's `professor_mode`.

This reproduction uses different dimensions because it follows the active
SpeexDSP initialization in `preprocess.c`:

```text
frame_size = 160 samples
ps_size    = frame_size = 160
analysis   = 2 * ps_size = 320 samples
N3         = 2 * N - frame_size = 160 samples
N4         = frame_size - N3 = 0
```

The relevant source definitions are in
`speexdsp/libspeexdsp/preprocess.c`, inside
`speex_preprocess_state_init()` around the `ps_size`, `N3`, and `N4`
assignments.

Therefore:

* `professor_mode` satisfies the professor's required protocol;
* `ReproductionMode` is an additional source-reproduction study;
* `ReproductionMode` must not be presented as the 256-sample assignment mode.

## 3. Directory and script map

### 3.1 `core/reproduction_config.m`

This function defines all algorithm dimensions and controls:

```matlab
Fs              = 8000
FrameSize       = 160
HopSize         = 160
AnalysisSize    = 320
FFTSize         = 160
NumBands        = 24
NoiseSuppressDb = -15
GainFloor       = exp(0.2302585 * NoiseSuppressDb)
```

The values are selected as follows.

### Sampling rate: 8 kHz

The professor's files are 8 kHz, and SpeexDSP accepts arbitrary sampling
rates but derives its filterbank from the supplied sampling rate. Keeping
8 kHz makes the reproduction directly comparable with the course data.

### Frame size: 160 samples

At 8 kHz, 160 samples correspond to 20 ms. More importantly, this is the
`frame_size` used by the reproduction and matches the active SpeexDSP source
geometry described in `preprocess.c`.

### Analysis size: 320 samples

The source allocates `frame`, `window`, and `ft` for `2*N` values. With
`N = ps_size = 160`, the analysis transform length is 320.

### 24 Bark bands

The source defines `NB_BANDS` and creates the filterbank with
`filterbank_new(M, sampling_rate, N, 1)`. The MATLAB implementation uses
24 bands to match the cloned source configuration.

### `NoiseSuppressDb = -15`

This is the source-faithful baseline used by the project. In SpeexDSP,
`noise_suppress` controls the noise gain floor. The floating-point source
computes:

```c
noise_floor = exp(.2302585f * noise_suppress);
```

This is in `compute_gain_floor()` in `preprocess.c`.

The selected quality path uses `-35 dB` only as a separate listening
configuration. It is not the source-faithful baseline.

### `GainFloor`

The configuration stores a scalar lower bound for numerical safety. The
actual source-style floor is frequency-dependent and is recomputed inside
`source_faithful_process.m` from Bark-band noise power. The scalar value is
only a final guard and should not be confused with the full source formula.

## 4. `core/source_window.m`

This function reproduces the floating-point branch of `conj_window()` in
`preprocess.c`.

The source creates a special conjugate window rather than simply calling a
generic Hann-window function. It uses:

```text
x       = 4*i/len
piecewise reflection of x
x       = 1.271903*x
tmp     = (0.5 - 0.5*cos(pi*x))^2
window  = sqrt(tmp)
```

The piecewise reflection makes the window symmetric in the same way as the
source implementation. The `1.271903` constant is taken directly from the
floating-point `conj_window()` code in `preprocess.c`.

This choice is important because analysis and synthesis windows affect:

* spectral leakage;
* overlap-add amplitude;
* transient behavior;
* output level;
* comparison against C output.

Using MATLAB's generic Hann window here would be convenient but would not
match the source's window construction.

## 5. `core/packed_real_fft.m`

This function exposes the packed real-spectrum contract used by SpeexDSP.
The output layout is:

```text
packed[0]       = DC
packed[1]       = Re(X1)
packed[2]       = Im(X1)
packed[3]       = Re(X2)
packed[4]       = Im(X2)
...
packed[N-1]     = Nyquist
```

This layout is visible in `kiss_fftr.c`, especially the assignments to:

```c
freqdata[0]
freqdata[2*k-1]
freqdata[2*k]
freqdata[2*ncfft-1]
```

The MATLAB reference computes the same mathematical transform with explicit
cosine and sine sums:

\[
X[k] = \frac{1}{N}\sum_{n=0}^{N-1}x[n]
       e^{-j2\pi kn/N}.
\]

The `1/N` factor is required because the floating-point `USE_KISS_FFT` branch
of `fftwrap.c` scales the forward transform by `1./t->N`.

The explicit transform is intentionally easy to inspect and translate, but it
is not an optimized real-time FFT. Its operation order differs from Kiss FFT's
radix butterflies, so it is mathematically source-compatible rather than
bit-for-bit equivalent.

The `backend` argument accepts `kiss_fft` and `smallft` so an optimized
backend-specific implementation can later replace this function without
changing the denoising code.

## 6. `core/packed_real_ifft.m`

This function reconstructs a real signal from the packed spectrum.

For each time sample it evaluates the conjugate-symmetric inverse:

\[
x[n] = X[0] + X[N/2](-1)^n +
2\sum_{k=1}^{N/2-1}
\left(\Re(X[k])\cos(\theta)-\Im(X[k])\sin(\theta)\right).
\]

The corresponding source layout and inverse path are implemented in
`kiss_fftr.c` through `kiss_fftri2()`. The source wrapper calls the inverse
FFT after applying the packed gains.

The inverse is kept explicit for three reasons:

1. it makes the packed format visible;
2. it provides a simple MATLAB oracle for later C tests;
3. it avoids hiding the source scaling inside MATLAB `ifft`.

For production CCS, this function must be replaced by the selected fixed
320-point DSP inverse FFT.

## 7. `core/hypergeom_gain.m`

SpeexDSP does not evaluate the complete special function at runtime. The
floating-point branch in `preprocess.c` uses a 21-entry lookup table:

```c
0.82157, 1.02017, 1.20461, 1.37534, 1.53363, 1.68092,
1.81865, 1.94811, 2.07038, 2.18638, 2.29688, 2.40255,
2.50391, 2.60144, 2.69551, 2.78647, 2.87458, 2.96015,
3.04333, 3.12431, 3.20326
```

The values are copied numerically from the non-fixed-point
`hypergeom_gain()` table in `preprocess.c`.

For `x < 10`, the MATLAB function linearly interpolates between adjacent
table entries using `floor(2*x)`. For larger values it uses the source
asymptotic branch:

\[
G(x) = 1 + \frac{0.1296}{x}.
\]

The approximation is used because it is the actual source strategy and is
also practical for CCS. A runtime Bessel or hypergeometric library would be
more expensive and would no longer describe the SpeexDSP implementation.

## 8. `core/design_bank.m`

This function implements the Bark mapping used by `filterbank.c`.

The source Bark conversion is:

\[
B(f) =
13.1\arctan(0.00074f)
+2.24\arctan(1.85\times10^{-8}f^2)
+10^{-4}f.
\]

The MATLAB code evaluates the Bark coordinate for every positive-spectrum bin,
computes the Bark value at Nyquist, divides that range into 24 equal
intervals, and stores the two neighboring bands and interpolation weights.

The choice of precomputing:

```text
Left
Right
LeftWeight
RightWeight
```

is deliberate. The source filterbank computes equivalent mappings, while a
CCS implementation benefits from calculating these constants once during
initialization instead of inside every frame.

## 9. `core/bank_forward.m` and `core/bank_inverse.m`

### Forward mapping

`bank_forward.m` maps a linear-frequency vector into 24 Bark bands:

\[
P_b = \sum_k
\left(w_{L,k,b} + w_{R,k,b}\right)P_k.
\]

Each FFT bin contributes to at most two adjacent bands. This corresponds to
the accumulation behavior in `filterbank_compute_bank32()` in
`filterbank.c`.

### Inverse mapping

`bank_inverse.m` interpolates a 24-band vector back to linear bins:

\[
G_k = (1-\alpha_k)G_{L,k}+\alpha_kG_{R,k}.
\]

This corresponds to the interpolation behavior in
`filterbank_compute_psd16()` in `filterbank.c`.

These functions use explicit loops instead of implicit matrix operations
because each loop maps directly to a fixed C loop.

## 10. `core/source_faithful_process.m`

This is the central algorithm. It is an offline wrapper around fixed-size
frame processing.

### 10.1 Preallocation and dimensions

The function preallocates the padded input, output, overlap normalization, and
diagnostic arrays. This keeps allocation outside the frame loop and exposes
the memory required for a future C implementation.

The MATLAB wrapper processes a complete signal, but the algorithmic state is
explicit:

```text
S, Smin, Stmp
Noise, OldPower
Prior, Post, Zeta
Gain, GainFloor
UpdateProb
FrameIndex, MinCount, NbAdapt
```

These names correspond to fields in `SpeexPreprocessState` in `preprocess.c`.

### 10.2 Analysis frame

Each frame extracts 320 samples, applies the source window, and computes the
packed spectrum. The first 160 packed positive-frequency values are converted
to complex values only for readable MATLAB power computation:

\[
P_k = |\mathit{FFT}_k|^2.
\]

The C source stores the packed spectrum in `ft` and computes the power
spectrum in `ps` inside `preprocess_analysis()`.

### 10.3 Smoothed spectrum and minimum statistics

The source updates `S` using:

\[
S_i = 0.8S_i+
0.05P_{i-1}+0.10P_i+0.05P_{i+1}.
\]

The endpoints use the source's 0.8/0.2 rule. `Smin` and `Stmp` track minima
over the source adaptation interval, and `UpdateProb` decides where noise
updates are allowed.

This is based on `update_noise_prob()` in `preprocess.c`. The rationale is to
avoid updating the noise model aggressively during speech-dominant frames.

### 10.4 Initial and adaptive noise estimation

The MATLAB experiment provides a noise-only prefix. The first eight frames are
averaged to initialize the noise power:

\[
\lambda_d^{(t)}
= \frac{(t-1)\lambda_d^{(t-1)}+P^{(t)}}{t}.
\]

After initialization, the source-style update uses:

\[
\beta=\max(0.03,1/\text{nb\_adapt}),
\]

and updates only bins permitted by `UpdateProb` or bins whose current power is
below the noise estimate.

The prefix is an experiment-level aid for stable initialization. The
denoising core receives only the noisy mixture; it does not receive the
separate noise vector.

### 10.5 A-posteriori SNR

The implementation uses:

\[
\gamma_k = \frac{P_k}{\lambda_{d,k}},
\qquad
\text{post}_k=\gamma_k-1.
\]

The source uses the same relationship in `preprocess.c`:

```c
post = ps / total_noise - 1
```

The value is limited to 100 to match the practical source bound.

### 10.6 Decision-directed a-priori SNR

The update is:

\[
u_k =
0.1+0.89
\left(\frac{P_{x,k}^{old}}
{P_{x,k}^{old}+\lambda_{d,k}}\right)^2,
\]

\[
\xi_k =
u_k\max(0,\text{post}_k)
(1-u_k)\frac{P_{x,k}^{old}}{\lambda_{d,k}}.
\]

This uses the previous clean-spectrum power estimate, stored as `OldPower`.
That state is essential: without it, the method is not a decision-directed
estimator.

The constants 0.1 and 0.89 are taken from the source update in
`preprocess.c`; they provide a conservative combination of instantaneous and
previous spectral information.

### 10.7 Zeta smoothing

The source smooths `zeta` as:

\[
\zeta_i =
0.7\zeta_i+0.15\xi_i
0.075\xi_{i-1}+0.075\xi_{i+1}.
\]

Endpoints use the 0.7/0.3 form. This reduces frame-to-frame speech-presence
flicker and is implemented in the source before frame speech probability.

### 10.8 Frame speech probability

The corrected implementation first maps `zeta` to Bark bands, averages the
band values, and then applies:

\[
qcurve(z)=\frac{1}{1+0.15/z},
\]

\[
P_\text{frame}=0.1+0.899qcurve(\operatorname{mean}(\zeta_b)).
\]

This order matters. Averaging `qcurve` values is not equivalent to applying
`qcurve` after averaging. The implementation was corrected after diagnostics
showed an excessively high speech-presence estimate.

The per-band speech-presence value is:

\[
P_{1,b}=0.199+0.8qcurve(\zeta_b).
\]

The constants and `qcurve` definition come from `preprocess.c`.

### 10.9 Bark-band gain

For each Bark band:

\[
r_b=\frac{\xi_b}{1+\xi_b},
\]

\[
\theta_b=r_b(1+\text{post}_b),
\]

\[
G_b=\min\left(1,r_b\,\text{hypergeom\_gain}(\theta_b)\right).
\]

This is the source's hypergeometric MMSE amplitude-gain path. The gain is
bounded by one to avoid amplification.

### 10.10 `gain2`

The source computes:

\[
q_b=1-P_\text{frame}P_{1,b},
\]

\[
G_{2,b}
=\frac{1}
{1+\frac{q_b}{1-q_b}(1+\xi_b)e^{-\theta_b}}.
\]

`gain2` expresses speech-presence uncertainty and is later interpolated to
linear frequency. It is not simply another noise gain; it controls how strongly
the gain is mixed with the gain floor.

### 10.11 Linear-frequency gain recomputation

The source first interpolates the Bark gain, but then recomputes the
Ephraim-Malah hypergeometric gain at each linear-frequency bin. The MATLAB
implementation follows this corrected order:

1. compute Bark gain;
2. interpolate the Bark gain;
3. compute linear-bin prior ratio and `theta`;
4. compute linear-bin hypergeometric gain;
5. constrain it using the interpolated Bark gain;
6. apply the gain floor;
7. apply the `gain2` loudness-domain mixture.

This correction materially improved suppression over the earlier version.

### 10.12 Source gain-floor calculation

The floating-point source computes:

\[
\text{noise\_floor}
=e^{0.2302585\,\text{noise\_suppress}},
\]

\[
G_{\text{floor},b}
=\sqrt{
\frac{\text{noise\_floor}\,N_b}
{1+N_b}
}.
\]

Here \(N_b\) is the estimated Bark-band noise power. The MATLAB code computes
this floor in Bark bands and interpolates it back to linear frequency.

This is superior to using one scalar floor because noise energy is frequency
dependent.

### 10.13 Loudness-domain mixture

The source applies:

\[
G_\text{final}
=
\left[
G_2\sqrt{G}
(1-G_2)\sqrt{G_\text{floor}}
\right]^2.
\]

The square-root mixture is deliberate. It mixes amplitude-loudness terms
before returning to power/amplitude gain, following the source comment in
`preprocess.c`.

### 10.14 Synthesis

The final gain is applied to the packed real spectrum, the inverse transform
is performed, the source window is applied again, and adjacent frames are
added. The MATLAB wrapper divides by accumulated window power to compensate
for overlap normalization.

The C source instead maintains explicit `outbuf` state and writes the
overlap-add samples directly. This is one of the remaining structural
differences that must be addressed for bit-exact validation.

## 11. `core/quality_tuned_process.m`

This function runs the same source equations but sets:

```matlab
QualityMode = true
NoiseSuppressDb = -35
GainFloor = exp(0.2302585 * -35)
QualityExponent = 1.0
```

The purpose is to provide a listening output with a lower SpeexDSP gain floor.
It is not an unrelated spectral-subtraction or neural post-filter.

The source-faithful output remains at `-15 dB`; the selected output is a
separate engineering configuration. Because stronger suppression can remove
speech energy, the quality output must be judged using both SNR and listening.

## 12. `core/load_sigd.m`

This is an experiment-layer helper. It loads the professor MAT files and
requires a finite variable named `sigd`.

It is intentionally outside the processing algorithm. A CCS implementation
must replace it with a sample input interface or test-vector reader.

## 13. `no_gui/main_reproduction_mode.m`

This is the complete experiment harness.

### Inputs

```matlab
main_reproduction_mode(cleanFile, noiseFile, backend, ...
                       qualityMode, showPlots, playAudio)
```

Example:

```matlab
results = main_reproduction_mode( ...
    '1z88153a8.mat', 'white8.mat', 'smallft', true, true, true);
```

### Mixture generation

The noise is repeated and trimmed to the speech-plus-prefix length, centered,
and scaled to the target 10 dB speech-region SNR:

\[
a=
\sqrt{
\frac{E_s}
{10^{SNR/10}E_n}
}.
\]

The clean signal is zero during the prefix. The denoiser sees:

```text
noise-only prefix + noisy speech
```

The clean and separate noise signals are retained only by the harness for
controlled generation, metrics, plotting, and playback.

### Metrics

Metrics exclude the artificial prefix:

\[
SNR_\text{in}
=10\log_{10}
\frac{\sum s^2}{\sum(y_\text{noisy}-s)^2},
\]

\[
SNR_\text{out}
=10\log_{10}
\frac{\sum s^2}{\sum(y_\text{enhanced}-s)^2}.
\]

The improvement is:

\[
\Delta SNR=SNR_\text{out}-SNR_\text{in}.
\]

Excluding the prefix is the scientifically meaningful speech-region metric;
including it would penalize the mixture with noise energy where clean speech
is intentionally zero.

## 14. `no_gui/plot_and_listen.m`

This function is deliberately outside the core. It creates common-scale
spectrograms for:

1. clean;
2. noise;
3. noisy;
4. source-faithful;
5. selected output.

Using one dB color range prevents each plot from independently hiding
residual noise. It can also play the same five signals using `soundsc`.

The function is for analysis only and must not be copied into CCS runtime
code.

## 15. `tests/run_tests.m`

The tests cover:

* packed FFT/IFFT round-trip for `kiss_fft`;
* packed FFT/IFFT round-trip for `smallft`;
* filterbank dimensions and valid band indices;
* finite source output;
* finite gain diagnostics;
* expected frame count and state progression.

The tests prove numerical stability and interface consistency. They do not
prove bit-exact SpeexDSP behavior. That requires a compiled C reference and
frame-by-frame comparison.

## 16. Current validation results

Using speech `1z88153a8.mat`, 10 dB input SNR, and the current implementation:

```text
Noise   Source-faithful SNR   Selected quality SNR
white       12.907 dB              12.862 dB
pink        12.653 dB              12.550 dB
Volvo       14.158 dB              14.174 dB
```

The source-faithful output is the correct numerical reference. The selected
quality output is for listening and uses the lower `-35 dB` floor.

These results are positive improvements, not guarantees of transparent or
RNNoise-level speech. RNNoise includes a trained recurrent model and should
normally provide better perceptual separation for difficult nonstationary
noise.

## 17. Exactness limitations

The current MATLAB implementation is source-derived, not bit-exact. Known
differences are:

1. The FFT uses direct trigonometric summation rather than Kiss FFT radix
   butterflies.
2. MATLAB uses double precision; the source uses C floating-point types.
3. MATLAB processes an offline padded signal; the source maintains streaming
   `inbuf` and `outbuf`.
4. MATLAB stores most spectral state as `N` arrays and computes Bark arrays
   temporarily; the source stores combined `N+M` arrays.
5. MATLAB normalizes overlap-add using an accumulated window-power vector;
   the source performs explicit output-buffer overlap.
6. The current `smallft` label shares the packed mathematical reference
   implementation and is not a separate SmallFT butterfly implementation.

These limitations must be reported rather than hidden.

## 18. CCS translation plan

The fixed dimensions make a C6713 implementation practical:

```c
#define FRAME_SIZE 160
#define ANALYSIS_SIZE 320
#define FFT_BINS 160
#define NUM_BANDS 24
```

The C state should contain fixed arrays for:

```text
S, Smin, Stmp
noise, old_power
prior, post, zeta
gain, gain_floor
inbuf, outbuf
frame, packed_spectrum
```

The CCS port should replace:

* `packed_real_fft` with a validated fixed 320-point DSP FFT;
* `packed_real_ifft` with its matching inverse;
* `load_sigd` with test-vector input;
* MATLAB structures with C structs;
* diagnostic matrices with one-frame diagnostic records;
* offline padding with explicit `inbuf` and `outbuf`.

The correct validation sequence is:

1. export one analysis frame from MATLAB;
2. compare packed FFT values;
3. compare power spectrum;
4. compare noise state;
5. compare prior/post SNR;
6. compare Bark-band gains;
7. compare linear gains;
8. compare inverse-FFT frame;
9. compare overlap-add output;
10. compare complete audio and SNR.

## 19. Source references

Primary references used for implementation:

* Xiph SpeexDSP repository:
  `https://github.com/xiph/speexdsp`
* Local source:
  `speexdsp/libspeexdsp/preprocess.c`
* Local source:
  `speexdsp/libspeexdsp/filterbank.c`
* Local source:
  `speexdsp/libspeexdsp/fftwrap.c`
* Local source:
  `speexdsp/libspeexdsp/kiss_fftr.c`
* Local source:
  `speexdsp/libspeexdsp/kiss_fft.c`
* Public API:
  `speexdsp/include/speex/speex_preprocess.h`
* License:
  `speexdsp/COPYING`

The statistical background for the SNR and MMSE interpretation is:

* Y. Ephraim and D. Malah, “Speech Enhancement Using a Minimum Mean-Square
  Error Short-Time Spectral Amplitude Estimator,” IEEE TASSP, 1984,
  DOI: 10.1109/TASSP.1984.1164453.
* I. Cohen and B. Berdugo, “Speech enhancement for non-stationary noise
  environments,” Signal Processing, 2001.

The equations used in the actual reproduction path are taken primarily from
the SpeexDSP source, not copied from a separate MATLAB package.
