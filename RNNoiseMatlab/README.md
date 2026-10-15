# RNNoiseMatlab

Independent MATLAB preparation and evaluation project for the official
RNNoise reference. Previous projects are not imported or modified.

## Run the non-GUI experiment

```matlab
cd('C:\Users\Mhamed\Documents\sys835\project\RNNoiseMatlab\no_gui')
main_rnnoise_matlab
```

The default experiment uses the professor data as **8,000 Hz**, creates a
10 dB controlled mixture, optionally prepends 0.25 seconds of noise-only
audio, resamples it to 48 kHz with the local six-phase FIR, and invokes the
official RNNoise executable through WSL.

## Run tests

```matlab
cd('C:\Users\Mhamed\Documents\sys835\project\RNNoiseMatlab\tests')
run_tests
```

## Run the GUI

```matlab
cd('C:\Users\Mhamed\Documents\sys835\project\RNNoiseMatlab\gui')
rnnoise_gui
```

The GUI calls the same functions in `core`; it does not implement a second
denoiser.

The non-GUI experiment plays, in order, the original speech, the selected
noise, the noisy speech, and the RNNoise-enhanced speech when
`config.PlayAudio` is `true`. The GUI provides separate buttons for the same
four signals after an experiment has completed.

## Layout

- `core`: reusable preparation, FIR, PCM, RNNoise, metrics, and plotting code.
- `no_gui`: reproducible experiment entry point.
- `gui`: thin interactive front end.
- `tests`: focused validation.
- `generated`: PCM, figures, MATLAB results, and CCS vectors.
- `documentation`: design and porting details.
- `rnnoise`: local official runtime copied for independent execution.

The FIR coefficient matrix is exported in
`generated\ccs_vectors\fir_coefficients.mat`; each row is one interpolation
phase and can be converted directly into a C constant table.

The test suite and main experiment call `validate_fir_resampler`. If the
Signal Processing Toolbox is installed, it compares the local FIR against
MATLAB `resample` after bounded delay alignment. MATLAB `resample` is never
used by the production path. If it is unavailable, the validation report
records that fact and the tests use deterministic DC and sinusoidal checks.

The same run also exports little-endian float32 frame files:

- `input_frames_480_float32.dat`;
- `clean_frames_480_float32.dat`;
- `enhanced_frames_480_float32.dat`.
