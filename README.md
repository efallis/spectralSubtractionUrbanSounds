# spectralSubtractionUrbanSounds

This repository contains the scripts used for filtering and testing multiple urban sounds. An ideal audio clip is taken, then recorded again in a noisy environment. The recorded clip is filtered to see how closely the filtered clip matches the original clean audio clip.
urban_sounds_filter.m takes in recorded audio clips and outputs filtered clips based on the spectral subtraction algorithm selected.

urban_sounds_filter_compare.m takes the filtered audio clips and compares them to the original using the method of coherence.
