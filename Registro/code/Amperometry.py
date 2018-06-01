#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun May 13 19:39:02 2018

@author: javier
"""

import igor.igorpy as igor
import numpy as np
import matplotlib.pyplot as plt

def getPeaks(voltage,tiempo, threshold):
    """Calculates the peaks of a signal, using the second derivative method. 
    It first obtain the positive derivative, then it converts the signal to a 
    discretized format, where the positive derivates will be 1, the negatives
    will be 0.Then, the second derivative is calculated, and the zero crossing
    points are obtained.
    Finally, the points which are greater than threshold are selected and returned.
    Input:
    ----------
    voltage : array
        Voltage trace in which will the peaks will be obtained.
    tiempo: array
        time vector
    threshold: float
        value that will define the peaks bigger that threshold
    Output:
    ---------
    Y: array
         time and the amplitude of each peak"""
    
    dv=np.diff(voltage)
    c=(np.abs(dv>0)).nonzero()[0] #get the positive derivative, ie, the positive slope

    signal = np.ones(len(voltage)) 
    signal[c] = 0  #reconstruct the signal with the positive slopes. 1 if is positive, 0 if not
    b = np.diff(signal)*0.5 #get the changes from positive to negative, ie, peak detection
    peak = [np.where(b==0.5)][0]
    times = tiempo[peak]#[0]
    value = voltage[peak]#[0]
    #t = tiempo[np.where(voltage[peak]>threshold)[0]]
    #v = voltage[np.where(voltage[peak]>threshold)[0]]
    #position = np.where(voltage[[np.where(np.diff(signal)*0.5==0.5)][0]]>threshold)[0]
    v = value[np.where(value>threshold)[0]]
    t = times[np.where(value>threshold)[0]]
    #position = np.where(np.isin(time,t)*1)
    Y = np.column_stack((t,v)) #stores the time and the amplitude of each peak
    return Y

def getIndex(vector,comparision):
    """Search the occurence of 'comparision' in 'vector', elementwise.
    ----------
    Vector : array
        Mother array where the elements of comparision will be searched.
    comparision: array
        child array which contains the elements to be found in 'Vector'.
    Output:
    ---------
    index: array
         the index of occurence of 'comparision' in 'Vector'"""
    mask = np.isin(vector,comparision)*1
    index = np.where(mask==1)
    return index[0]

def getExtremes(index, vector, baseline):
    """Gets the begining and end of spikes in Amperometry experiments.
    The search algorithm is based on Mosharov and Sulzer (Nature,2005).
    The idea is to find the points T_bkg1 and T_bkg2. To do this, starting
    from T_peak (calculated previously), the point T_bkg1 is the first point
    which is lower than baseline, going backwards in 'vector'.
    On the other hand, T_bkg2 is the first point to be lower than the baseline, 
    but going forward in 'vector'.
    ----------
    Index : array
        array that contains the index where 'vector' has its peaks, previously
        filtered by a certain threshold (see function getPeaks)
    Vector : array
        Voltage trace in which will the peaks was obtained.
    baseline: float
        value of the baseline to find points T_bkg1 and T_bkg2.
    Output:
    ---------
    extremes: 2D-array
         2xN array which contains the index of the pair (T_bkg1,T_bkg2) 
         for the N entries of index"""
    inicio_pie = []
    for i in range(len(index)):
        j = index[i]
        foot = vector[j]
        while(foot>baseline):
            foot = vector[j]
            j = j-1
        inicio_pie.append(j)

    fin_pie = []
    for i in range(len(index)):
        j = index[i]
        foot = vector[j]
        while(foot>=baseline):
            foot = vector[j]
            j = j+1
        fin_pie.append(j)
    extremes = np.column_stack((inicio_pie,fin_pie))
    return extremes

def integrate(init,end,function,dt):
    #return value
    def_integral = 0
    i=init
    while(i<=end):
        def_integral+=np.abs(function[i])
        i+=1
    return def_integral/(dt*(end-init))
    
def movingAvg(data, window):
    cumsum, moving_aves = [0], []
    N = window
    for i, x in enumerate(data, 1):
        cumsum.append(cumsum[i-1] + x)
        if i>=N:
            moving_ave = (cumsum[i] - cumsum[i-N])/N
            #can do stuff with moving_ave here
            moving_aves.append(moving_ave)
    return np.array(moving_aves)

def footEnd(waveSample, time):
    a = np.where(np.diff(waveSample,n=2)==np.max(np.diff(waveSample,n=2)))[0] 
    foot = waveSample[a][0]
    subtime = time[inicio[i]:final[i]]
    t_foot = subtime[a]
    return t_foot

def getThalf(index, vector, thrs):
    """Gets the points where current = 0.5*Imax in Amperometry experiments.
    The search algorithm is based on Mosharov and Sulzer (Nature,2005).
    The idea is to find the points T_bkg1 and T_bkg2. To do this, starting
    from T_peak (calculated previously), the point T_bkg1 is the first point
    which is lower than baseline, going backwards in 'vector'.
    On the other hand, T_bkg2 is the first point to be lower than the baseline, 
    but going forward in 'vector'.
    ----------
    Index : array
        array that contains the index where 'vector' has its peaks, previously
        filtered by a certain threshold (see function getPeaks)
    Vector : array
        Voltage trace in which will the peaks was obtained.
    baseline: float
        value of the baseline to find points T_bkg1 and T_bkg2.
    Output:
    ---------
    extremes: 2D-array
         2xN array which contains the index of the pair (T_bkg1,T_bkg2) 
         for the N entries of index"""
    inicio_pie = []
    for i in range(len(index)):
        j = index[i]
        foot = vector[j]
        baseline = thrs[i]
        while(foot>baseline):
            foot = vector[j]
            j = j-1
        inicio_pie.append(j)

    fin_pie = []
    for i in range(len(index)):
        j = index[i]
        foot = vector[j]
        baseline = thrs[i]
        while(foot>=baseline):
            foot = vector[j]
            j = j+1
        fin_pie.append(j)
    extremes = np.column_stack((inicio_pie,fin_pie))
    return extremes





