#pragma rtGlobals=1		// Use modern global access method.

// Quick access to select packages in WaveMetrics Procedures folder...

Menu "Load Waves"
	Submenu "Packages"
		"Load FITS",Execute/P "INSERTINCLUDE  <FITS Loader>";Execute/P "COMPILEPROCEDURES ";Execute/P "CreateFITSLoader()"
	End
End
Menu "Analysis"
	Submenu "Packages"
		"Multipeak Fitting",Execute/P "INSERTINCLUDE  <Multi-peak fitting 1.3>";Execute/P "INSERTINCLUDE  <Peak Functions>";Execute/P "COMPILEPROCEDURES ";Execute/P "CreateFitSetupPanel()"
		"Global Fitting",Execute/P "INSERTINCLUDE  <Global Fit>";Execute/P "COMPILEPROCEDURES ";Execute/P "InitGlobalFitPanel()"
		"Wave Arithmetic",Execute/P "INSERTINCLUDE  <Wave Arithmetic Panel>";Execute/P "COMPILEPROCEDURES ";Execute/P "InitWaveArith()"
		"Waves Average", Execute/P "INSERTINCLUDE <Waves Average>";Execute/P "COMPILEPROCEDURES ";Execute/P "MakeWavesAveragePanel()"
		"Percentiles", Execute/P "INSERTINCLUDE <Percentile and Box Plot>";Execute/P "COMPILEPROCEDURES ";Execute/P "MakeWavePercentilePanel(1)"
		"Image Processing",Execute/P "INSERTINCLUDE  <All IP Procedures>";Execute/P "COMPILEPROCEDURES "
		"Int Diff XY",Execute/P "INSERTINCLUDE  <IntDiffXYPanel>";Execute/P "COMPILEPROCEDURES ";Execute/P "IntDiffXY()"
		"ANOVA",Execute/P "INSERTINCLUDE <ANOVA>";Execute/P "COMPILEPROCEDURES ";
	End
End
Menu "Graph"
	Submenu "Packages"
		"Colorize Traces",Execute/P "INSERTINCLUDE <KBColorizeTraces>";Execute/P "COMPILEPROCEDURES ";Execute/P "ShowKBColorizePanel()"
		"Split Axes",Execute/P "INSERTINCLUDE  <Split Axis>";Execute/P "COMPILEPROCEDURES "
		"Autosize Images",Execute/P "INSERTINCLUDE  <Autosize Images>";Execute/P "COMPILEPROCEDURES ";Execute/P "AutoSizeImage()"
		"Modify Waterfall",Execute/P "INSERTINCLUDE <Waterfall>";Execute/P "COMPILEPROCEDURES ";Execute/P "WM_fNewWaterfallPanel(1)"
		"Transform Axes",Execute/P "INSERTINCLUDE  <TransformAxis>";Execute/P "COMPILEPROCEDURES ";Execute/P "DoTransformAxisPanel(0)"
		"Append Calibrator",Execute/P "INSERTINCLUDE  <Append Calibrator>";Execute/P "COMPILEPROCEDURES ";Execute/P "Calibrator()"
		"Copy Image Subset",Execute/P "INSERTINCLUDE  <CopyImageSubset>";Execute/P "COMPILEPROCEDURES "
		"Save Graph",Execute/P "INSERTINCLUDE  <SaveGraph>";Execute/P "COMPILEPROCEDURES ";Execute/P "DoSaveGraphToFile()"
	End
End

Menu "New"
	Submenu "Packages"
		"Probability Graph",Execute/P "INSERTINCLUDE  <TransformAxis>";Execute/P "COMPILEPROCEDURES ";Execute/P "DoProcessProbabilityDataPanel()"
		"New Waterfall",Execute/P "INSERTINCLUDE <Waterfall>";Execute/P "COMPILEPROCEDURES ";Execute/P "WM_fNewWaterfallPanel(0)"
		"Polar Graph",Execute/P "INSERTINCLUDE  <New Polar Graphs>";Execute/P "COMPILEPROCEDURES ";Execute/P "WMPolarGraphs(0)"
		"Box Plot", Execute/P "INSERTINCLUDE <Percentile and Box Plot>";Execute/P "COMPILEPROCEDURES ";Execute/P "MakeWavePercentilePanel(0)"
	End
End
