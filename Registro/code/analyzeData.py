#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun May 13 19:30:36 2018

@author: javier
"""

import igor.igorpy as igor
import numpy as np
import matplotlib.pyplot as plt
import Amperometry as amp

filePackage = '../EGFPv EXP8.pxp'
recording = igor.load(filePackage)
recordingDuration = 100.2 #duration in seconds
dt = 1./len(recording.Data.data)
Fs = 1./dt #1kHz

wave = recording.Data.data/1e-12
datos = wave-wave.mean()
time = np.linspace(0, recordingDuration, len(wave), endpoint=True)

avgPoints = 20
workingData = movingAvg(datos,avgPoints) #smothen the signal with moving average procedure
peakThr = 10
H = getPeaks(workingData,time, peakThr) #get peaks for the filtered signal

index = getIndex(time,H[:,0]) #get the index of the time where peaks occured
baseline = 0
extremos = getExtremes(index,datos,baseline) #get the init and end of a spike event based on the peak occurence


#remove repeated elements
inicio = np.unique(extremos[:,0]) 
final = np.unique(extremos[:,1])
peaks = np.zeros(len(final))

#Correction of the peak occurence. The peak identification was done on a filtered signal, which delayed the peak.
#hence, a correction is made here
for i in range(len(inicio)):
    if(inicio[i]==final[i]):
        peaks[i] = 0
    else:
        peaks[i] = int(np.where(datos==np.max(datos[inicio[i]:final[i]]))[0][0])


finalData = np.zeros((len(inicio),3))
finalData[:,0] = inicio
finalData[:,1] = peaks
finalData[:,2] = final