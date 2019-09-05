# Applying Spectral Subtraction to Urban Sounds

This repository contains the script used for filtering and testing multiple urban sounds. An ideal audio clip is taken, then recorded again in a noisy environment. The recorded clip is filtered to see how closely the filtered clip matches the original clean audio clip.

urban_sounds_filter_compare.m takes the filters the audio clips with magnitude-squared coherence and compares them to the original using the method of coherence.
