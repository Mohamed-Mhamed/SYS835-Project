# SpeexDSPMatlab

This independent project contains two distinct MATLAB implementations:

* `professor_mode`: 8 kHz, 256-sample adjacent blocks, 256-point FFT, no
  overlap, matching the SYS835 assignment.
* `reference_mode`: 8 kHz, 160-sample frames, 160-sample hop, 320-sample
  analysis, windowing and overlap-add, approximating the practical SpeexDSP
  processing style.

The reference core also provides `portable_config`, which selects explicit
fixed-size loops for the floating-point SpeexDSP packed real-FFT convention.
This MATLAB path is intended to be the numerical reference for a later CCS C
port; file loading, plotting, playback, and experiment orchestration remain
outside the core.

The official Xiph source is cloned in `speexdsp`. The MATLAB code is an
independent readable reimplementation of the relevant noise-suppression
roles, not a claim of bit-exact source equivalence.
