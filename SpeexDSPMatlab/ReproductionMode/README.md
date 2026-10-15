# SpeexDSP ReproductionMode

This is an independent MATLAB reproduction project. It does not modify the
parent `SpeexDSPMatlab` modes.

The project has two deliberately separate outputs:

* `source_faithful`: follows the cloned floating-point SpeexDSP processing
  order, source window, 24-band filterbank, state variables, and `gain2`;
* `quality_tuned`: a separate source-control configuration using the
  SpeexDSP `noise_suppress` control at -25 dB; it is not an unrelated
  post-filter and is not the source-faithful default.

The source-faithful path is the reference for a later CCS C implementation.
The current project is offline and processes a complete signal frame by frame;
its state and fixed dimensions are kept explicit so a streaming wrapper can
be added later.

Plotting and playback are provided by `no_gui/plot_and_listen.m`; they remain
outside the processing core so the same core can later be translated to CCS.

The MATLAB FFT backends are:

* `kiss_fft`: packed real-spectrum convention used by the SpeexDSP
  `USE_KISS_FFT` wrapper;
* `smallft`: a source-compatible packed real-spectrum reference using the
  same real FFT convention. It is a numerical backend reference, not a claim
  that MATLAB reproduces SmallFT's butterfly rounding bit-for-bit.
