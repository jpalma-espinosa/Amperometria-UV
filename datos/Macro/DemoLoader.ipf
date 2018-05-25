#pragma rtGlobals=1

//Igor Pro 4.0A

#pragma IgorVersion=4.00

Menu "Example Experiments"
	SubMenu "Imaging"
		"\M0FITS Loader Demo", ExamplesExperimentLoader(":Examples:Imaging:FITS Loader Demo.pxp")
		"\M0Image MagPhase Demo", ExamplesExperimentLoader(":Examples:Imaging:Image MagPhase Demo.pxp")
		"\M0Image Processing Demo", ExamplesExperimentLoader(":Examples:Imaging:Image Processing Demo.pxp")
		"\M0Image Strip FIFO Demo", ExamplesExperimentLoader(":Examples:Imaging:Image Strip FIFO Demo.pxp")
		"\M0MDInterpolator Demo", ExamplesExperimentLoader(":Examples:Imaging:MDInterpolator Demo.pxp")
	end
	SubMenu "Visualization"
		"\M0Surface Plotter Demo", ExamplesExperimentLoader(":Examples:Visualization:Surface Plotter Demo.pxp")
		"\M0Graphical Slicer Demo", ExamplesExperimentLoader(":Examples:Visualization:Graphical Slicer Demo.pxp")
		"\M0Surface Movie Demo", ExamplesExperimentLoader(":Examples:Visualization:Surface Movie Demo.pxp")
	end
	SubMenu "Testing & Misc"
		"\M0benchmark 2.01", ExamplesExperimentLoader(":Examples:Testing & Misc:benchmark 2.01.pxp")
		"\M0Live Update Testing", ExamplesExperimentLoader(":Examples:Testing & Misc:Live Update Testing.pxp")
		"\M0Notebook Operations Test", ExamplesExperimentLoader(":Examples:Testing & Misc:Notebook Operations Test.pxp")
		"\M0Tick Mark Tests", ExamplesExperimentLoader(":Examples:Testing & Misc:Tick Mark Tests.pxp")
		"\M0User Menu Tests", ExamplesExperimentLoader(":Examples:Testing & Misc:User Menu Tests.pxp")
		"\M0Graph Grid Demo", ExamplesExperimentLoader(":Examples:Testing & Misc:Graph Grid Demo.pxp")
		"\M0Printer Test", ExamplesExperimentLoader(":Examples:Testing & Misc:Printer Test.pxp")
		"\M0ColorsMarkersLinesPatterns", ExamplesExperimentLoader(":Examples:Testing & Misc:ColorsMarkersLinesPatterns.pxp")
		"\M0Slider Labels", ExamplesExperimentLoader(":Examples:Testing & Misc:Slider Labels.pxp")
		"\M0ListBox Demo", ExamplesExperimentLoader(":Examples:Testing & Misc:ListBox Demo.pxp")
		"\M0MatrixOps Tests", ExamplesExperimentLoader(":Examples:Testing & Misc:MatrixOps Tests.pxp")
		"\M0ColorScale Demo", ExamplesExperimentLoader(":Examples:Testing & Misc:ColorScale Demo.pxp")
		"\M0Map Projections Demo", ExamplesExperimentLoader(":Examples:Testing & Misc:Map Projections Demo.pxp")
		"\M0Resize Panel and List Demo", ExamplesExperimentLoader(":Examples:Testing & Misc:Resize Panel and List Demo.pxp")
		"\M0sequenceSearchDemo", ExamplesExperimentLoader(":Examples:Testing & Misc:sequenceSearchDemo.pxp")
		"\M0Notebook Picture Tests", ExamplesExperimentLoader(":Examples:Testing & Misc:Notebook Picture Tests.pxp")
		"\M0GenerateDemoLoader", ExamplesExperimentLoader(":Examples:Testing & Misc:GenerateDemoLoader.pxp")
	end
	SubMenu "Techniques"
		"\M0Cross Hair Demo", ExamplesExperimentLoader(":Examples:Techniques:Cross Hair Demo.pxp")
		"\M0Delete Points from Wave", ExamplesExperimentLoader(":Examples:Techniques:Delete Points from Wave.pxp")
		"\M0Load Row Data", ExamplesExperimentLoader(":Examples:Techniques:Load Row Data.pxp")
		"\M0Points in Poly Demo", ExamplesExperimentLoader(":Examples:Techniques:Points in Poly Demo.pxp")
		"\M0Split Axes", ExamplesExperimentLoader(":Examples:Techniques:Split Axes.pxp")
		"\M0Tags as Markers Demo", ExamplesExperimentLoader(":Examples:Techniques:Tags as Markers Demo.pxp")
		"\M0Trace Graph", ExamplesExperimentLoader(":Examples:Techniques:Trace Graph.pxp")
	end
	SubMenu "Sample Graphs"
		"\M0Demo Experiment #1", ExamplesExperimentLoader(":Examples:Sample Graphs:Demo Experiment #1.pxp")
		"\M0Monster Graph", ExamplesExperimentLoader(":Examples:Sample Graphs:Monster Graph.pxp")
		"\M0Exotic Functions", ExamplesExperimentLoader(":Examples:Sample Graphs:Exotic Functions.pxp")
		"\M0Demo Experiment #2", ExamplesExperimentLoader(":Examples:Sample Graphs:Demo Experiment #2.pxp")
		"\M0Layout Demo", ExamplesExperimentLoader(":Examples:Sample Graphs:Layout Demo.pxp")
		"\M0Contour Demo", ExamplesExperimentLoader(":Examples:Sample Graphs:Contour Demo.pxp")
	end
	SubMenu "Programming"
		"\M0AutoGraph", ExamplesExperimentLoader(":Examples:Programming:AutoGraph.pxp")
		"\M0FIFO File Parse", ExamplesExperimentLoader(":Examples:Programming:FIFO File Parse.pxp")
		"\M0gradient arrows", ExamplesExperimentLoader(":Examples:Programming:gradient arrows.pxp")
		"\M0HDF Demos", ExamplesExperimentLoader(":Examples:Programming:HDF Demos.pxp")
		"\M0Hook Peak Place", ExamplesExperimentLoader(":Examples:Programming:Hook Peak Place.pxp")
		"\M0read write test", ExamplesExperimentLoader(":Examples:Programming:read write test.pxp")
		"\M0DDE Snippets", ExamplesExperimentLoader(":Examples:Programming:DDE Snippets.pxp")
		"\M0Load File Demo", ExamplesExperimentLoader(":Examples:Programming:Load File Demo.pxp")
	end
	SubMenu "Movies & Audio"
		SubMenu "Sound Input"
			"\M0Fake Acquisition (fifo)", ExamplesExperimentLoader(":Examples:Movies & Audio:Sound Input:Fake Acquisition (fifo).pxp")
			"\M0Fake Acquisition (sound)", ExamplesExperimentLoader(":Examples:Movies & Audio:Sound Input:Fake Acquisition (sound).pxp")
			"\M0Realtime Sonagram", ExamplesExperimentLoader(":Examples:Movies & Audio:Sound Input:Realtime Sonagram.pxp")
			"\M0Sound Chart Demo", ExamplesExperimentLoader(":Examples:Movies & Audio:Sound Input:Sound Chart Demo.pxp")
			"\M0Sound System Eval", ExamplesExperimentLoader(":Examples:Movies & Audio:Sound Input:Sound System Eval.pxp")
		end
		"\M0FM Modulation Movie", ExamplesExperimentLoader(":Examples:Movies & Audio:FM Modulation Movie.pxp")
	end
	SubMenu "Graphing Techniques"
		SubMenu "Obsolete"
			"\M0Polar Graphs Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Obsolete:Polar Graphs Demo.pxp")
		end
		"\M0Drawing Axes Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Drawing Axes Demo.pxp")
		"\M0Probability Graph Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Probability Graph Demo.pxp")
		"\M0Scatter Plot Matrix Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Scatter Plot Matrix Demo.pxp")
		"\M0Arrow Plot", ExamplesExperimentLoader(":Examples:Graphing Techniques:Arrow Plot.pxp")
		"\M0New Polar Graph Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:New Polar Graph Demo.pxp")
		"\M0Colorize Traces Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Colorize Traces Demo.pxp")
		"\M0Transform Axis Demo", ExamplesExperimentLoader(":Examples:Graphing Techniques:Transform Axis Demo.pxp")
	end
	SubMenu "Feature Demos"
		"\M0Smoothing Control Panel", ExamplesExperimentLoader(":Examples:Feature Demos:Smoothing Control Panel.pxp")
		"\M0FIFO Chart Demo FM", ExamplesExperimentLoader(":Examples:Feature Demos:FIFO Chart Demo FM.pxp")
		"\M0FIFO Chart Overhead", ExamplesExperimentLoader(":Examples:Feature Demos:FIFO Chart Overhead.pxp")
		"\M0Live mode", ExamplesExperimentLoader(":Examples:Feature Demos:Live mode.pxp")
		"\M0Live Textbox Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Live Textbox Demo.pxp")
		"\M0Make Sample Data Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Make Sample Data Demo.pxp")
		"\M0Marquee Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Marquee Demo.pxp")
		"\M0Notebook Demo #1", ExamplesExperimentLoader(":Examples:Feature Demos:Notebook Demo #1.pxp")
		"\M0Quick Append", ExamplesExperimentLoader(":Examples:Feature Demos:Quick Append.pxp")
		"\M0Smooth Curve Through Noise", ExamplesExperimentLoader(":Examples:Feature Demos:Smooth Curve Through Noise.pxp")
		"\M0Spline Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Spline Demo.pxp")
		"\M0ValDisplay Demo", ExamplesExperimentLoader(":Examples:Feature Demos:ValDisplay Demo.pxp")
		"\M0Wave Review Chart Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Wave Review Chart Demo.pxp")
		"\M0Web Page Demo", ExamplesExperimentLoader(":Examples:Feature Demos:Web Page Demo.pxp")
	end
	SubMenu "Curve Fitting"
		"\M0Fit Line Between Cursors", ExamplesExperimentLoader(":Examples:Curve Fitting:Fit Line Between Cursors.pxp")
		"\M0Global Fit Demo", ExamplesExperimentLoader(":Examples:Curve Fitting:Global Fit Demo.pxp")
		"\M0Multi-peak fit", ExamplesExperimentLoader(":Examples:Curve Fitting:Multi-peak fit.pxp")
		"\M0Multi-variate Fit Demo", ExamplesExperimentLoader(":Examples:Curve Fitting:Multi-variate Fit Demo.pxp")
		"\M0Constraint Demo", ExamplesExperimentLoader(":Examples:Curve Fitting:Constraint Demo.pxp")
	end
	SubMenu "Analysis"
		"\M0BiVariate Histogram Demo", ExamplesExperimentLoader(":Examples:Analysis:BiVariate Histogram Demo.pxp")
		"\M0Integrating Histogram", ExamplesExperimentLoader(":Examples:Analysis:Integrating Histogram.pxp")
		"\M0MagPhase Demo", ExamplesExperimentLoader(":Examples:Analysis:MagPhase Demo.pxp")
		"\M0Neural Net Demo", ExamplesExperimentLoader(":Examples:Analysis:Neural Net Demo.pxp")
		"\M0SpecialFuncs Demo", ExamplesExperimentLoader(":Examples:Analysis:SpecialFuncs Demo.pxp")
		"\M0Ave, Box Plot, Percentile", ExamplesExperimentLoader(":Examples:Analysis:Ave, Box Plot, Percentile.pxp")
		"\M0Wavelet Demo", ExamplesExperimentLoader(":Examples:Analysis:Wavelet Demo.pxp")
		"\M0Wave Arithmetic Panel Demo", ExamplesExperimentLoader(":Examples:Analysis:Wave Arithmetic Panel Demo.pxp")
		"\M0Smooth Operation Responses", ExamplesExperimentLoader(":Examples:Analysis:Smooth Operation Responses.pxp")
		"\M0Gaussian Filtering", ExamplesExperimentLoader(":Examples:Analysis:Gaussian Filtering.pxp")
		"\M0Differential Equation Demo", ExamplesExperimentLoader(":Examples:Analysis:Differential Equation Demo.pxp")
	end
	SubMenu "Tutorials"
		SubMenu "IP Tutorial"
			"\M0IP Tutorial", ExamplesExperimentLoader(":Learning Aids:Tutorials:IP Tutorial:IP Tutorial.pxp")
		end
		"\M0X Scaling Tutorial", ExamplesExperimentLoader(":Learning Aids:Tutorials:X Scaling Tutorial.pxp")
		"\M0Data Folder Tutorial", ExamplesExperimentLoader(":Learning Aids:Tutorials:Data Folder Tutorial.pxp")
		"\M0User Fit Tutorial", ExamplesExperimentLoader(":Learning Aids:Tutorials:User Fit Tutorial.pxp")
	end
	SubMenu "Sample Data"
		"\M0ImageSample", ExamplesExperimentLoader(":Learning Aids:Sample Data:ImageSample.pxp")
	end
		"-"
		"Removing This Menu...", DoAlert 0, "To remove this menu from Igor, drag the file DemoLoader.ipf out of the Igor Procedures folder, which is in your Igor Pro folder."
	end
end

Function ExamplesExperimentLoader(ExperimentFilePath)
	String ExperimentFilePath

	Execute/P "LOADFILE "+ExperimentFilePath
end
