//////////////////////////////////////////////////////////////////////////////////////////////////
// This version is the same as 3.2 but now tau (TauUp) ant tau' (TauDown)
// are calculated.
// TauUp = time from X_Peak until time where Y is equal to Imax - Imax/e.
// TauDown = time from X_Peak until time where Y is equal to Imax/e.
// The functions Parameters_Of_Spikes and Calculate_Parameters_Spike has been 
// modified. 
// New functions added: Calculate_Tau, Show_Tau.
// The following functions have been too modified: Creating_Objects_Check, Load_Waves_Exp,
// F_Bu_Save_Exp, F_Bu_Remove_Between, F_Bu_Undo_Last_Erased_Spike, F_Bu_Remove_Spike, 
// F_Bu_Add_Spike, F_Bu_Modify_Spike, Update_Graph_Spike, Show_Parameteres, 
// Erase_Parameters, Gallery_Table, Creating_Objects_Gallery, F_Check_AllSpkCell, F_Check_RandomSpk, 
// Calculate_Statistic, Create_Cell_SubGallery, Create_Random_SubGallery, F_Check_Cell, F_Bu_Load_Exp_Gallery,
// Make_Histograms, F_Bu_Remove_Spike_Gallery, F_Bu_Show_Spike_Display, F_Bu_Close_All_Gallery_Graphs, 
// F_Bu_Close_Gallery_Histograms, F_Bu_Show_Gallery_Histograms, Layout_Gallery_Graph, Table_Mean_Cell, 
// Table_Median_Cell, Table_StdDev_Cell, 
////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma rtGlobals=1
Menu "Macros"
   "* Spike analysis */1", Spike_Analysis()
   "* Spike view */2",   Spike_View()
   "* Galleries */3",   Galleries()
End

/////////////////////////////////////////////////////////////////////////////////////////////////////
///////  FIRST  PART:  AUTOMATIC  ANALYSIS   OF  EXPERIMENTS
///////                        SEARCHING SPIKES
/////////////////////////////////////////////////////////////////////////////////////////////////////
// This function makes the main panel where data will be chosen.
Function Spike_Analysis()
   // Locals
   String Wave_Name
   Variable Go_To_Save = 0
   PauseUpdate; Silent 1
    // Making_Spike_View is created to indicate that you need to save the spikes checked with the Second Part of program.
   If ( Exists( "Making_Spike_View"))
      // results from check spikes (second option from Macros menu).
      DoAlert 2, "Not all result files are saved, save them now?"
      If ( V_Flag == 1)
         Go_To_Save = 1
         F_Bu_Show_Save_Panel(" ")
      Else
         If (V_Flag == 3)
            Go_To_Save = 1
         EndIf
      EndIf
   EndIf
   If ( ! Go_To_Save )
      KillVariables /Z Making_Spike_View
      Kill_Windows_Analyse()  // If windows are already shown, they are killed.
      Kill_Windows_Check()    // If windows of check option are shown, they are killed.
      Kill_Windows_Gallery()   // If windows of check option are shown, they are killed.
      Creating_Objects_Analyse()
      Execute "Data_Table()"      // Table where selected data are shown.
      Execute "Main_Panel_Analysis()"      // Main panel to select data and parameters.
      // The file Panel_Config will keep the parameters used in main panel the last run. So, next run
      // will load parameters from file Panel_Config, then the main panel will have the parameteres of
      // the previous run.
      // The file Panel_Config is saved in built-in path called Igor. If the file does not exist, it will be created.
      PopUpMenu PopUpChooseFiles mode=1
      PathInfo Igor      // In built-in path Igor 
      If ( ! Find_File("Panel_Config", S_Path) )  // File "Panel_Config" has been found in path Igor.
         Wave_Name = Loading_File(S_Path, "Panel_Config")  // It returns the wave name loaded.
         If ( StrLen( Wave_Name))  // Loads file without error.
            Updating_Panel($Wave_Name)  // It updates the main panel with values in wave loaded previously,
                                 // called "Panel_Config".
            KillWaves /Z $Wave_Name
         EndIf
      EndIf
   EndIf
End

// This function creates the global objects (strings, variables and waves) which are needed.
Function Creating_Objects_Analyse()
   PauseUpdate; Silent 1
   // Kill all objetcts used in others options of Macros menu.
   // KillVariables /A /Z   // All windows (panels, tables, etc.) must be killed for avoiding "Igor program error".
   // KillStrings /A /Z
   KillWaves /A /Z
   // Variables for process information panel.
   Variable /G Dis_Id, Dis_Total_N, Dis_Spk_N, Dis_Spk_Total
   String   /G Dis_Name
   // These waves save folders where data are and names of data files.
   Make /O /T /N=0 Data_Folders
   Make /O /T /N=0 Data_Names
   Make /O /T /N=0 Data_Comments
   // These variables are shown in main panel and they can be modified.
   String /G File_Folder = Current_Path()
          // To get the current path used in igor to know the format of a igor path.
   String /G Result_Folder = File_Folder
      // For indicating folder where data are and folder where results will be saved.
   String  /G FilesInFileFolder= "All files;" + FindWavesInFolder(File_Folder)
   String /G ItemSelected = "All files"
   Variable /G File_Number = -1   // When data are in numbered files, this variable will be used to make
                        // the full name of the data file. It helps to select the data files in a quick way.
   String   /G File_Name_Beginning = "Exp"
      // These two variables will be used to make the full file name.
   String /G Comment = ""  // Comment used with each data file. It is used to create the folder where
                      // results will be saved.
   Variable   /G Scale_pAV=100   // Global variable to save the scale of conversion from V to pA.
   Variable   /G Smooth_Factor = 5
      // Variable used for smooth filtering.
   Variable   /G Slope_Threshold=5
      // Variable used for defining noise in the first derivative of the signal: what is not noise, it will be spike.
   Variable   /G Smooth_Differentiate=15
      // Variables used for smoothing first derivative and data signals.
   String /G Coef_Wave_Folder = File_Folder 
          // Folder and file name of the wave that saves the coeficients for custom smoothing.
   Variable   /G Filter_Test_File = 0   // It is used to select the id# file which will be filtered.
   Variable   /G Threshold_Test_File = 0
            // It is used to select the id# file which will be used to display threshold.
End

//This function returns the list of waves (IGBW), separated by semicolon, found in the folder.
Function /T FindWavesInFolder(Folder)
   String Folder
   String FilesFound = ""
   PauseUpdate; Silent 1
   NewPath /Z /Q /O PathFolder Folder
   PathInfo PathFolder
   If (V_Flag)
      FilesFound = IndexedFile(PathFolder, -1, "IGBW")
   EndIf
   KillPath /Z PathFolder
   Return(FilesFound)
End

// This function updates variables of main panel with values in Config_Wave, loaded from file "Panel_Config", 
Function Updating_Panel(Config_Wave)
   Wave /T Config_Wave
   // Globals
   NVar Scale_pAV = Scale_pAV
   NVar Smooth_Factor = Smooth_Factor
   NVar Slope_Threshold = Slope_Threshold
   NVar Smooth_Differentiate = Smooth_Differentiate
   PauseUpdate; Silent 1
   Scale_pAV = Str2Num( Config_Wave[ 1])
   CheckBox Check_FIR1, value = Str2Num( Config_Wave[ 2])
   If (Str2Num( Config_Wave[ 2]))
      PathInfo Igor
      If (Find_File("FIR1", S_Path) == 1)
         CheckBox Check_FIR1, value=0
      EndIf
   EndIf   
   CheckBox Check_FIR2, value = Str2Num( Config_Wave[ 3])
   If (Str2Num( Config_Wave[ 3]))
      PathInfo Igor
      If (Find_File("FIR2", S_Path) == 1)
         CheckBox Check_FIR2, value=0
      EndIf
   EndIf   
   CheckBox Check_Smooth, value = Str2Num( Config_Wave[ 4])
   Smooth_Factor = Str2Num( Config_Wave[ 5])
   F_Check_Smooth(" ", Str2Num( Config_Wave[ 4]))
   CheckBox Check_Others_Filters, value = Str2Num( Config_Wave[ 6])
   F_Check_Others_Filters(" ", Str2Num( Config_Wave[ 6]))
   If ( Str2Num( Config_Wave[ 6]) )
      CheckBox Check_Smooth_Custom, value = Str2Num( Config_Wave[ 7])
      F_Check_Smooth_Custom(" ", Str2Num( Config_Wave[ 7]))
   EndIf
   Slope_Threshold = Str2Num( Config_Wave[ 8])
   Smooth_Differentiate = Str2Num( Config_Wave[ 9])
End

// This function saves the values of variables in main panel in a file called "Panel_Config" in path "Igor".
Function Saving_Panel_Config()
   String Folder
   // Globals
   NVar Scale_pAV = Scale_pAV
   NVar Smooth_Factor = Smooth_Factor
   NVar Slope_Threshold = Slope_Threshold
   NVar Smooth_Differentiate = Smooth_Differentiate
   Wave /T Panel_Config = Panel_Config
   PauseUpdate; Silent 1
   Make /T /O /N=10 Panel_Config
   //First component ( Panel_Config[0]) is without use.
   Panel_Config[ 1] = Num2Str(Scale_pAV)
   ControlInfo /W=Main_Panel_Analysis  Check_FIR1
   Panel_Config[ 2] = Num2Str(V_Value)
   ControlInfo /W=Main_Panel_Analysis  Check_FIR2
   Panel_Config[ 3] = Num2Str(V_Value)
   ControlInfo /W=Main_Panel_Analysis  Check_Smooth
   Panel_Config[ 4] = Num2Str(V_Value)
   Panel_Config[ 5] = Num2Str(Smooth_Factor)
   ControlInfo /W=Main_Panel_Analysis  Check_Others_Filters
   Panel_Config[ 6] = Num2Str(V_Value)
   ControlInfo /W=Main_Panel_Analysis  Check_Smooth_Custom
   Panel_Config[ 7] = Num2Str(V_Value)
   Panel_Config[ 8] = Num2Str( Slope_Threshold)
   Panel_Config[ 9] = Num2Str( Smooth_Differentiate)
   Save /O /P=Igor Panel_Config as "Panel_Config"
End

// Table where selected data are shown.
Window Data_Table() : Table
   PauseUpdate; Silent 1      // building window...
   Edit/W=(318,43,612,332) Data_Folders,Data_Names,Data_Comments as "Data to be processed"
   ModifyTable font="Arial",size=12,width(Point)=20,title(Point)="Id#",alignment(Data_Folders)=0
   ModifyTable width(Data_Folders)=104,title(Data_Folders)="Folder",style(Data_Names)=1
   ModifyTable alignment(Data_Names)=0,width(Data_Names)=94,title(Data_Names)="Name"
   ModifyTable alignment(Data_Comments)=0,width(Data_Comments)=60,title(Data_Comments)="Comment"
EndMacro

//This function displays a graph including the First_Derivative wave and the threshold set with options in panel.
Function F_Bu_Test_Threshold(CtrlName)
   String CtrlName
   // Globals
   NVar Threshold_Test_File = Threshold_Test_File   
   NVar Smooth_Differentiate = Smooth_Differentiate
   NVar Slope_Threshold = Slope_Threshold
   NVar Scale_pAV = Scale_pAV
   Wave /T Data_Names = Data_Names
   Wave /T Data_Folders = Data_Folders
   PauseUpdate; Silent 1
   If ( Threshold_Test_File < NumPnts( Data_Names) )
      DoAlert 1, "Ready to display 1st. derivative of file with Id#  " + Num2Str(Threshold_Test_File) + ", called  "+ Data_Names(Threshold_Test_File) +" ?"
      If ( V_Flag == 1)         
         CtrlName = Loading_File( Data_Folders(Threshold_Test_File), Data_Names(Threshold_Test_File))
         If ( StrLen( CtrlName))  // Loads file without error.
            // It is obtained the wave name loaded in CtrlName. This procedure is run
            // expecting that data are in a wave named "Data", then we have to rename data wave as "Data".
            Renaming_Data( CtrlName) 
            Wave Data = Data //In this moment the Data wave exists.                        
            Data   *=  Scale_pAV   *  1e-12
            WaveStats /Q Data
            SetScale y V_Min, V_Max, "A", Data
            Filtering()
            Differentiating(Smooth_Differentiate)
            Wave First_Derivative = First_Derivative  //This wave is returned by this function.
            If (F_Noise_Data())
               Wave Noise_Data = Noise_Data  //This wave is returned by this function.
               Make /O /N=2 Threshold_Line = Noise_Data[3] * Slope_Threshold
               SetScale /I x 0,(RightX(First_Derivative)),"s", Threshold_Line
               DoWindow /K Threshold_Graph
               Execute "Threshold_Graph()"  // It shows first_derivative and threshold.
            Else
               DoAlert 0, "Period of noise not found..."
            EndIf
         Else
            DoAlert 0, "Error loading the file Id#..."
         EndIf
      EndIf
   Else
      If ( NumPnts(Data_Names) )
         DoAlert 0, "Error!  Id# must be between 0 and " + Num2Str(NumPnts(Data_Names)-1) + "."
      Else
         DoAlert 0, "Error!  No file added."
      EndIf
   EndIf
End

// This function filters with chosen options the wave selected with the variable 
// Filter_Test_File of main panel, which corresponds to Id# in "Data to be processed" table.
Function F_Bu_Test_Filter(CtrlName)
   String CtrlName
   // Globals
   NVar Filter_Test_File = Filter_Test_File
   Wave /T Data_Names = Data_Names
   Wave /T Data_Folders = Data_Folders
   PauseUpdate; Silent 1
   If ( Filter_Test_File < NumPnts( Data_Names) )
      DoAlert 1, "Ready to filter file with Id#  " + Num2Str(Filter_Test_File) + ", called  "+ Data_Names(Filter_Test_File) +" ?"
      If ( V_Flag == 1)
         CtrlName = Loading_File( Data_Folders(Filter_Test_File), Data_Names(Filter_Test_File))
         If ( StrLen( CtrlName))  // Loads file without error.
            // It is obtained the wave name loaded in CtrlName. This procedure is run
            // expecting that data are in a wave named "Data", then we have to rename data wave as "Data".
            Renaming_Data( CtrlName)
            Wave Data = Data  //This wave is returned by this function.
            // Before filtering, data are kept in wave Original_Data.
            Duplicate /O Data Original_Data
            Filtering()
            DoWindow /K Data_Graph
            Execute "Data_Graph()"  // It shows original data and filtered data.
         Else
            DoAlert 0, "Error loading the file Id#..."
         EndIf
      EndIf
   Else
      If ( NumPnts(Data_Names) )
         DoAlert 0, "Error!  Id# must be between 0 and " + Num2Str(NumPnts(Data_Names)-1) + "."
      Else
         DoAlert 0, "Error!  No file added."
      EndIf
   EndIf
End

// This macro displays one original data file and its filtered data.
Window Data_Graph() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(189.75,149,471,323.75) Original_Data, Data as "Data and filtered data"
   ModifyGraph rgb(Original_Data)=(65280,0,0)
   ModifyGraph rgb(Data)=(0,0,65280)
   Button Close_Graph,pos={71,2},size={40,20},proc=F_Bu_Close_Filter_Graph,title="Close"
   SetDrawLayer UserFront
   SetDrawEnv fsize= 10,textrgb= (65280,0,0)
   DrawText 0.7,0.01,"Data"
   SetDrawEnv fsize= 10,textrgb= (0,0,65280)
   DrawText 0.82,0.01,"Data filtered"
EndMacro

// This macro displays the first_derivative wave and the threshold used for finding spikes.
Window Threshold_Graph() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(149,106,609,391) First_Derivative,Threshold_Line as "1st.Derivative and Threshold"
   ModifyGraph rgb(First_Derivative)=(65280,0,0),rgb(Threshold_Line)=(0,0,65280)
   Button Close_Graph,pos={71,2},size={40,20},proc=F_Bu_Close_Threshold_Graph,title="Close"
   SetDrawLayer UserFront
   SetDrawEnv fsize= 10,textrgb= (1,3,39321)
   DrawText 0.449608355091384,0.0142735042735043,"Threshold"
   SetDrawEnv fsize= 10,textrgb= (65535,0,0)
   DrawText 0.621671018276762,0.0142735042735043,"First Derivative"
EndMacro

// If button Close of Threshold_Graph window is clicked, that windows is killed.
Function F_Bu_Close_Threshold_Graph(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Threshold_Graph
   KillWaves /Z Threshold_Line, First_Derivative, Data
End

// If button Close of Data_Graph window is clicked, that windows is killed.
Function F_Bu_Close_Filter_Graph(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Data_Graph
   KillWaves /Z Original_Data, Data
End

// This function load in memory the file indicated in argument file_number.
// It returns the name of wave loaded. You must run previously the function Find_File to be sure
// that file to be loaded exists in that folder.
Function /T Loading_File( Folder, Name )
   String Folder, Name
   // Locals
   String Wave_Name = ""
   PauseUpdate; Silent 1
   If ( StrLen( Folder) )
      KillPath /Z Folder_Path
      NewPath /Z /O  /Q  Folder_Path  Folder
      PathInfo Folder_Path
      If ( V_Flag )
         LoadWave /Q /O /H /P=Folder_Path  Name
         Wave_Name = S_WaveNames[0, StrLen(S_WaveNames) - 2]  // Wave name without the last ";".
      EndIf
      KillPath /Z Folder_Path
   EndIf
   Return ( Wave_Name)
End

// If data file has not the name "Data", this function renames it as "Data" because this procedure uses that name.
// A loadwave sentence have to be executed previously, so in string S_WaveNames we obtain the name of wave
// loaded.
Function Renaming_Data( Wave_Name)
   String Wave_Name
   PauseUpdate; Silent 1
   If ( CmpStr(Wave_Name, "Data")) // If wave name is not "Data", wave is renamed.
      Duplicate /O $Wave_Name Data
      Print "Wave  " + Wave_Name + "  renamed as  Data"
      KillWaves /Z $Wave_Name
   EndIf
End

// It filters with chosen options in main panel.
Function Filtering()
   Variable Check_Filter_1
   Variable Check_Filter_2
   // Globals
   SVar  Coef_Wave_Folder = Coef_Wave_Folder
   Wave Data = Data
   NVar Smooth_Factor = Smooth_Factor
   PauseUpdate; Silent 1
   ControlInfo /W=Main_Panel_Analysis  Check_FIR1
   Check_Filter_1 = V_Value
   If ( Check_Filter_1 )
      PathInfo Igor
      If (! Find_File("FIR1", S_Path))
         LoadWave /Q /O /H /P=Igor  "FIR1"
         SmoothCustom Coeffs_FIR1, Data
      Else
         Print "Filter Coefficients are not located in Igor folder. The experiment has not been filtered..."
      EndIf
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_FIR2
   Check_Filter_1 = V_Value
   If ( Check_Filter_1 )
      PathInfo Igor
      If (! Find_File("FIR2", S_Path))
         LoadWave /Q /O /H /P=Igor  "FIR2"
         SmoothCustom Coeffs_FIR2, Data
      Else
         Print "Filter Coefficients are not located in Igor folder. The experiment has not been filtered..."
      EndIf
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_Smooth
   Check_Filter_1 = V_Value
   If ( Check_Filter_1 )
      If ( Smooth_Factor)  // It it is 0, function Smooth would return error.
         Smooth  Smooth_Factor, Data
      EndIf
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_Others_Filters
   Check_Filter_1 = V_Value
   If ( Check_Filter_1 )
      ControlInfo /W=Main_Panel_Analysis  Check_Smooth_Custom
      Check_Filter_2 = V_Value
      If ( Check_Filter_2 )
         If ( Load_Coef_Wave(Coef_Wave_Folder) == -1)  
                    // Find and load wave where coeficients for custom smoothing are.
                    // When it is loaded, it is called Coef_Wave.
            Print "Wave with coeficientes for Custom Smooth filter has not been found..."
         Else
            SmoothCustom Coef_Wave, Data
                  // Coef_Wave was loaded in memory when button Run was clicked.
         EndIf
      EndIf
   EndIf
End

// This function runs when 'Kill' button of main panel is clicked and it substracts one data file 
// previously selected.
Function F_Bu_Kill(CtrlName) : ButtonControl
   String CtrlName      // Used to save the name of the file.
   Variable Counter      // To save the number of files already selected.
   Variable NFile
   Variable File_Not_Found
   Variable NumberOfFiles
   // Globals
   String FileName
   SVar ItemSelected = ItemSelected
   SVar FilesInFileFolder = FilesInFileFolder
   SVar File_Folder = File_Folder
   Wave /T Data_Folders = Data_Folders
   Wave /T Data_Names = Data_Names
   Wave /T Data_Comments = Data_Comments
   PauseUpdate; Silent 1
   // If the typed folder does not have a character colon at the end, we add it.
   If ( StrLen( File_Folder))
      If ( CmpStr( File_Folder[StrLen(File_Folder) - 1], ":" ) )
         File_Folder = File_Folder + ":"
      EndIf
   EndIf
   NewPath /Z /Q /O PathFileFolder File_Folder
   PathInfo PathFileFolder
   If (V_Flag == 0)
      DoAlert 0, "Error!\rData folder does not exist..."
   Else
      Make /O /T /N=0 FileNames
      If (CmpStr("All files", ItemSelected) == 0)
         ItemSelected = FilesInFileFolder[10, StrLen(FilesInFileFolder)-1]
         CreateFileNames(ItemSelected)
      Else
         InsertPoints 0, 1, FileNames
         FileNames[0] = ItemSelected
      EndIf
      NumberOfFiles = NumPnts(FileNames)
      If (NumberOfFiles > 0)
         Sort FileNames FileNames
         NFile = 0
         Do
            // Checking if data file is already added.
               Counter = Previously_Added(FileNames[NFile ], File_Folder)
               If (( Counter == -1) %& (NumberOfFiles == 1))
                  DoAlert 0, "Error!  Data file in that data folder has not previously added..."
               Else 
                  DeletePoints Counter, 1, Data_Folders
                  DeletePoints Counter, 1, Data_Names
                  DeletePoints Counter, 1, Data_Comments
               EndIf
               NFile += 1
         While (NFile < NumberOfFiles)
      EndIf
   EndIf
   KillPath /Z PathFileFolder
   KillWaves /Z FileNames
   ItemSelected = "All files"
   PopUpMenu PopUpChooseFiles mode=1
   ControlUpdate /A
End

//This function saves in FileNames wave the names of files to be added.
//FileList is the list of names separated by semicolon.
Function CreateFileNames(FileList)
   String FileList
   Variable Counter, Total, Initial
   Wave /T FileNames = FileNames
   PauseUpdate; Silent 1
   Total = StrLen(FileList)
   If (Total > 0)
      Counter = 0
      Initial = 0
      Do
         If (CmpStr(FileList[Counter], ";") == 0)
            InsertPoints NumPnts(FileNames), 1, FileNames
            FileNames[NumPnts(FileNames)-1] = FileList[Initial, Counter-1]
            Initial = Counter+1
         EndIf
         Counter += 1
      While (Counter < Total)
   EndIf
End

// This function runs when 'Add' button is clicked and it adds one data file
// and its folder to be processed later.
Function F_Bu_Add(CtrlName) : ButtonControl
   String CtrlName      // Used to save the name of the file.
   Variable Counter      // To save the number of files already selected.
   Variable NFile
   Variable File_Not_Found
   Variable NumberOfFiles
   // Globals
   SVar ItemSelected = ItemSelected
   SVar FilesInFileFolder = FilesInFileFolder
   SVar File_Folder = File_Folder
   SVar Comment = Comment
   String FileName
   Wave /T Data_Folders = Data_Folders
   Wave /T Data_Names = Data_Names
   Wave /T Data_Comments = Data_Comments
   PauseUpdate; Silent 1
   // If the typed folder does not have a character colon at the end, we add it.
   If ( StrLen( File_Folder))
      If ( CmpStr( File_Folder[StrLen(File_Folder) - 1], ":" ) )
         File_Folder = File_Folder + ":"
      EndIf
   EndIf
   NewPath /Z /Q /O PathFileFolder File_Folder
   PathInfo PathFileFolder
   If (V_Flag == 0)
      DoAlert 0, "Error!\rData folder does not exist..."
   Else
      Make /O /T /N=0 FileNames
      If (CmpStr("All files", ItemSelected) == 0)
         ItemSelected = FilesInFileFolder[10, StrLen(FilesInFileFolder)-1]
         CreateFileNames(ItemSelected)
      Else
         InsertPoints 0, 1, FileNames
         FileNames[0] = ItemSelected
      EndIf
      NumberOfFiles = NumPnts(FileNames)
      If (NumberOfFiles > 0)
         Sort FileNames FileNames
         NFile = 0
         Do
            File_Not_Found = Find_File(FileNames[NFile], File_Folder)
            If  ( ! File_Not_Found)   // File and folder are right.
            // Checking if data file is already added.
               Counter = Previously_Added(FileNames[NFile ], File_Folder)
               If ( Counter == -1)
                  Counter = NumPnts(Data_Names)
                  InsertPoints Counter, 1, Data_Folders, Data_Names, Data_Comments
                  Data_Names[Counter]    = FileNames[NFile]
                  Data_Folders[Counter] = File_Folder
                  Data_Comments[Counter] = Comment
               Else
                  If (NumberOfFiles == 1)
                     DoAlert 0, "Error!  Data file previously added in Id#  " + Num2Str(Counter)
                  EndIf
               EndIf
            Else
               If (File_Not_Found == 1)
                  DoAlert 0, "Error!  Data file does not exist in data folder..."
               Else
                  DoAlert 0, "Error!  Data folder does not exist..."
               Endif
            EndIf
            NFile += 1
         While (NFile < NumberOfFiles)
      EndIf
   EndIf
   KillPath /Z PathFileFolder
   KillWaves /Z FileNames
   ItemSelected = "All files"
   PopUpMenu PopUpChooseFiles mode=1
   ControlUpdate /A
End

// This function checks if data file name is in the Data_Names wave and its folder matchs.
// It returns the index (row) of the Data_Names wave where the named wave has been found, 
// or -1 when it has not been found.
Function Previously_Added(Name, Folder)
   String Name, Folder
   Variable Pointer, Found = 0
   // Globals
   Wave /T Data_Folders = Data_Folders
   Wave /T Data_Names = Data_Names
   PauseUpdate; Silent 1
   Pointer = NumPnts(Data_Names) - 1
   If (Pointer >= 0)
      Do
         If (! CmpStr((Name), Data_Names[Pointer]))
            If  (! CmpStr(Folder, Data_Folders[Pointer]))
               Found = 1
            EndIf
         EndIf
         If ( ! Found )
            Pointer -= 1
         EndIf
      While ( ( Pointer >= 0 )  %& (! Found) )
   EndIf
   Return ( Pointer )
End

// Function that looks for the file with the name File_Name, in the Folder.
// It returns 0 when the file has been found; 1 when it has not been found; 2 when the 
// folder does not exist.
Function Find_File( File_Name, Folder)
   String File_Name
   String Folder
   Variable Aux = 2
   PauseUpdate; Silent 1
   If ( StrLen(Folder) )
      KillPath /Z Folder_Path
      NewPath  /O /Z /Q  Folder_Path  Folder
      // Checking if the folder exists in hard disk.
      PathInfo Folder_Path
      If ( V_Flag )  // Folder exists
         // Checking if file exists in the selected folder, in hard disk
         Open /Z /T="IGBW" /R /P=Folder_Path  Aux  As  File_Name
         If ( V_Flag == 0 )
            Close Aux
            Aux = 0
         Else
            Aux = 1
         EndIf
      EndIf
      KillPath /Z Folder_Path
   EndIf
   Return (Aux)
End

//This function finds a period of noise in the First_Derivative wave. Two thresholds are set, 
// up and down of the basal line, because derivative signal includes negative points in spikes.
//All variables are expressed in points, so this funtions is independent of the scale of the signal.
Function F_Noise_Data()
   // Locals
   Variable Noise_Threshold_Up
   Variable Noise_Threshold_Down
   Variable Limit_Threshold_Up
   Variable Limit_Threshold_Down
   Variable Noise_Threshold_Increase  //To increase the threshold until the noise period is found.
   Variable Period_Found = 0  // To indicate when a period of noise has been located.
   Variable Beginning_T = 5*4000 //20000 first points are skipped (5 seconds of our signals)
   Variable Final_T
   Variable Period_Size = 3*4000  //Initially, it finds a period with 12000 points (3 seconds of our signals).
   Variable Period_Decrease = 4000  //  1 second of our signals.
   Variable Shift = 2000  //2000 points are 0.5 seconds of our signals
   Variable Right_X
   Variable Left_X
   // Globals
   Wave Data = Data
   Wave First_Derivative = First_Derivative
   PauseUpdate; Silent 1
   Make /O /N=4 Noise_Data  //Wave where noise data will be saved.
   Right_X  = NumPnts(First_Derivative)
   Left_X    = 0
   If ( ( Right_X - Left_X ) > (8*4000) )   // If wave is too short, it is not found a period of noise.
                           //Value 8*4000, because of 5*4000  first points (5 seconds in our signals)
                           //is not considered and the first period size is 3*4000 points (3 seconds).
      //Initial threshold for finding noise period is setted to moda of full first_derivative wave.
      Make /O /N=4000 Histo_Noise
      Histogram /B=1 First_Derivative, Histo_Noise  //Histogram with automatic options from Igor.
      //To calculate the limit threshold, 
      //we use the width (SD)of the gaussian obtained when fitting the histogram of data.
      Make /O /N=4  W_Coef
      Variable V_FitOptions=4
      Duplicate /O Histo_Noise Histo_Fit
      CurveFit /Q  Gauss Histo_Noise /D=Histo_Fit
      Noise_Threshold_Increase = W_Coef[3]/4
      Noise_Threshold_Up     = W_Coef[2] + 2*Noise_Threshold_Increase
      Noise_Threshold_Down = W_Coef[2] - 2*Noise_Threshold_Increase
      KillWaves /Z Histo_Noise, Histo_Fit, W_Coef
      WaveStats /Q First_Derivative
      Limit_Threshold_Up     = 0 + 4 * V_SDev
      Limit_Threshold_Down = 0 - 4 * V_SDev
      Do
         Final_T = Beginning_T + Period_Size
         If (Final_T < Right_X)
            //With WaveStats (12 seconds aprox.) the process is slower than with the
            //following Findlevel (less than 1 second)...
            // WaveStats /Q /R=[Beginning_T, Final_T] First_Derivative
            // If ((V_Max<=Noise_Threshold_Up)  %&  (V_Min >= Noise_Threshold_Down))            
            FindLevel  /Q  /R=[Beginning_T, Final_T] First_Derivative, Noise_Threshold_Up            
                  //If level Noise_Threshold is not crossed and the first point is down the level,
                  //all points in that period are down that level.
            If (V_Flag   %&  First_Derivative[Beginning_T] < Noise_Threshold_Up) 
               FindLevel  /Q  /R=[Beginning_T, Final_T] First_Derivative, Noise_Threshold_Down
               If (V_Flag   %&  First_Derivative[Beginning_T] > Noise_Threshold_Down)
                  Period_Found = 1
               Else
                  Beginning_T += Shift
               EndIf
            Else
               Beginning_T += Shift
            Endif
         Else
            Beginning_T = 5*4000
            Period_Size -= Period_Decrease
            If (Period_Size < 4000)  //If period size is less than 1 second in our signals
               Noise_Threshold_Up     += Noise_Threshold_Increase
               Noise_Threshold_Down -= Noise_Threshold_Increase
               Period_Size = 3*4000
            EndIf
         Endif
      While ((!Period_Found)%&(Noise_Threshold_Up<=Limit_Threshold_Up)%&(Noise_Threshold_Down>=Limit_Threshold_Down))
   Else
      Print "Wave too short..."
   EndIf
   If ( Period_Found )   // In wave Noise_Data will be saved characteristics of noise.
      Noise_Data[0] = Pnt2X(Data, Beginning_T)
      Noise_Data[1] = Pnt2X(Data, Final_T)
      WaveStats /Q /R=[Beginning_T, Final_T]  Data
      Noise_Data[2] = V_Sdev
      WaveStats /Q /R=[Beginning_T, Final_T]  First_Derivative
      Noise_Data[3] = V_Sdev
   Endif
   Return (Period_Found)   
End

// It shows or closes controls related with others filters checkbox of the main panel.
Function F_Check_Others_Filters(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   If (Checked)
      CheckBox Check_Smooth_Custom,pos={107,274},size={120,12},proc=F_Check_Smooth_Custom,value=1
      CheckBox Check_Smooth_Custom,title="Custom Smooth"
      SetVariable Coef_Wave_Folder_Ctrl,pos={62,287},size={230,16},title="Coefs:"
      SetVariable Coef_Wave_Folder_Ctrl,font="Arial",limits={-Inf,Inf,1},value= Coef_Wave_Folder
      SetVariable Coef_Wave_Folder_Ctrl,help={"Type here the file name (including full path and file extension) where coeficients for filtering are."}
   Else
      KillControl Check_Smooth_Custom
      KillControl Coef_Wave_Folder_Ctrl
   EndIf
End

// It adds or kills controls related with custom smooth filter check of the main panel.
Function F_Check_Smooth_Custom(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   If (Checked)
      SetVariable Coef_Wave_Folder_Ctrl,pos={62,287},size={230,16},title="Coefs:"
      SetVariable Coef_Wave_Folder_Ctrl,font="Arial",limits={-Inf,Inf,1},value= Coef_Wave_Folder
      SetVariable Coef_Wave_Folder_Ctrl,help={"Type here the file name (including full path and file extension) where coeficients for filtering are."}
   Else
      KillControl Coef_Wave_Folder_Ctrl
   EndIf
End

// It finds the file FIR2 with the filter coefficients in Igor folder.
Function F_Check_FIR2(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   If (Checked)
      PathInfo Igor
      If (Find_File("FIR2", S_Path) == 1)
         DoAlert 0, "FIR2 file has not been found in: \r"+S_Path+"\rThis filter will not be applied ..."
         CheckBox Check_FIR2, value=0
      EndIf
   EndIf
End

// It finds the file FIR1 with the filter coefficients in Igor folder.
Function F_Check_FIR1(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   If (Checked)
      PathInfo Igor
      If (Find_File("FIR1", S_Path) == 1)
         DoAlert 0, "FIR1 file has not been found in: \r"+S_Path+"\rThis filter will not be applied ..."
         CheckBox Check_FIR1, value=0
      EndIf
   EndIf
End

// It adds or kills controls related with smooth filter check of the main panel.
Function F_Check_Smooth(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   If (Checked)
      SetVariable Set_Smooth_Factor,pos={135,241},size={50,16},title=" ", format="%g"
      SetVariable Set_Smooth_Factor,font="Arial",limits={0,Inf,1},value= Smooth_Factor
      SetVariable Set_Smooth_Factor,help={"Key here the factor for smoothing."}
   Else
      KillControl Set_Smooth_Factor
   EndIf
End

// This function finds and loads the wave where coeficients for custom smoothing are.
// The parameter Coef_Wave_Folder saves the folder plus the name of file where coeficients are.
Function Load_Coef_Wave( Coef_Wave_Folder)
   String Coef_Wave_Folder
   // Locals
   Variable Pointer
   String Coef_File_Name, Coef_Folder_Name
   String Wave_Name
   PauseUpdate; Silent 1
   Pointer = Find_Last_Semicolon( Coef_Wave_Folder)
   If  ( Pointer != -1)
      Coef_Folder_Name = Coef_Wave_Folder[0, Pointer]
      Coef_File_Name = Coef_Wave_Folder[Pointer + 1, StrLen( Coef_Wave_Folder) - 1]
      If ( ! Find_File( Coef_File_Name, Coef_Folder_Name))
         Wave_Name = Loading_File( Coef_Folder_Name, Coef_File_Name)
         If ( StrLen( Wave_Name))  // Loads file without error.
                  // This procedure is run expecting that coeficients are in a wave named "Coef_Wave",
                  // then we have to rename loaded wave as "Coef_Wave".
            If ( CmpStr(Wave_Name, "Coef_Wave")) // If wave name is not "Coef_Wave", wave is renamed.
               Duplicate /O $Wave_Name Coef_Wave
               KillWaves /Z $Wave_Name
            EndIf
         Else
            DoAlert 0, "Error loading coeficient file of custom smooth."
            Pointer = -1
         EndIf
      Else
         DoAlert 0, "Error in Custom Smooth, coeficient file is not correct. You must type the folder and name of file (with extension if exists) where coeficients are."
         Pointer = -1
      EndIf
   Else
      DoAlert 0, "Error in Custom Smooth, coeficient file is not correct. You must type the folder and name of file (with extension if exists) where coeficients are."
   EndIf
   Return ( Pointer)  // -1  =  with errors.
End

//It adds the last semicolon when it is not typed.
Function Find_Last_Semicolon( Coef_Wave_Folder)
   String Coef_Wave_Folder
   // Locals
   Variable Pointer
   PauseUpdate; Silent 1
   Pointer = StrLen( Coef_Wave_Folder)
   Do
      Pointer -= 1
   While (( Pointer >= 0) %&  (CmpStr(Coef_Wave_Folder[ Pointer], ":")))
   If ( Pointer == (StrLen( Coef_Wave_Folder) - 1))
      Pointer = -1
   EndIf
   Return( Pointer)  // If ":" is not found, it returns -1.
End

// This function runs when you click in run button of main panel. The analysis begins in this function.
Function F_Bu_Run ( CtrlName) : ButtonControl
   String CtrlName
   Variable Pointer, Line = 30
   Variable Total_Spikes = 0
   Variable Number_Spikes
   // Globals
   SVar Result_Folder = Result_Folder
   Wave /T Data_Folders = Data_Folders
   Wave /T Data_Names = Data_Names
   Wave /T Data_Comments = Data_Comments
   // Globals of the information panel
   NVar Dis_Total_N = Dis_Total_N
   SVar Dis_Name = Dis_Name
   NVar Dis_Spk_N = Dis_Spk_N
   NVar Dis_Spk_Total = Dis_Spk_Total
   NVar Dis_Id = Dis_Id
   PauseUpdate; Silent 1
   DoWindow /K ChoosePanel
   F_Bu_Close_Filter_Graph("") // Remove the graph of data filtered, which might be shown.
   F_Bu_Close_Threshold_Graph("") // Remove the graph of threshold, which might be shown.
   Saving_Panel_Config()      // Save the parameters of main panel in file "Panel_Config" in path Igor.
   If ( StrLen(Result_Folder))
      If ( CmpStr( Result_Folder[StrLen(Result_Folder) - 1], ":" ) )
         Result_Folder = Result_Folder + ":"
      EndIf
      Dis_Total_N = NumPnts( Data_Names)
      If ( Dis_Total_N > 0 )
         // Checking the Several Folders check.
         ControlInfo /W=Main_Panel_Analysis  Several_Folders
         If ( ! V_Value )  // If results of every file will be saved in the same folder...
            DoAlert 1, "Warning! The Several Folders checkbox is not clicked. If two or more files had the same name, their results will be overwritten by the last one. CONTINUE?"
            If ( V_Flag != 1)
               Return ( V_Flag)
            EndIf
         EndIf
         // Checking if result folder is right.
         KillPath /Z Result_Folder_Path
         NewPath  /Z  /C  /O  /Q  Result_Folder_Path  Result_Folder
               // If the sub-folder does not exist, it is created.
         PathInfo Result_Folder_Path
         If ( V_Flag )
            Pointer = 0
            Dis_Id = Pointer
            Execute "Show_Info( )"
            DoUpdate
            Do
               Number_Spikes = 0
               Print Time(), "Processing file  " + Num2Str( Pointer+1) + " of  " + Num2Str( Dis_Total_N )
               CtrlName = Loading_File( Data_Folders(Pointer), Data_Names(Pointer))
                  // CtrlName keep the wave name loaded from the file.
               If ( StrLen( CtrlName))  // Loads file without error.
                  Print Time(), "Wave " + CtrlName + " loaded from file " + Data_Names(Pointer)
                  // This procedure is run expecting that data are in a wave named "Data",
                  // then we have to rename data wave as "Data".
                  Renaming_Data( CtrlName) // This argument is the wave name without the last character ";".                                 
                  If (NumPnts(Data) > 32000) //32000 points are neccessary in F_Noise_Data.
                     Number_Spikes = Processing_Wave()
                     If ( Number_Spikes )  // If the number of spikes is not zero...
                        Total_Spikes += Number_Spikes
                        Process_Parameters( )  // Put in a wave the parameters used in main panel.
                        Saving_Results( Result_Folder, Data_Comments[Pointer], Data_Names(Pointer) )
                      EndIf
                  Else
                     Print "Wave too short... ", Data_Names(Pointer) 
                  EndIf
               Else
                  Print "Error loading file   " + Data_Names(Pointer) + "   in   " + Data_Folders(Pointer)
               EndIf
               Print ""  // A blank line in history area between one file processed and the following one.
               Pointer += 1
               // To show data in the information panel.
               Dis_Name = Data_Names( Pointer - 1)
               Dis_Spk_N = Number_Spikes
               Dis_Spk_Total = Total_Spikes
               Dis_Id = Pointer
               Execute "Show_Info( )"
               DoUpdate
            While ( Pointer < Dis_Total_N )
         Else
            DoAlert 0, "Error!  Result folder wrong..."
         EndIf
         KillPath /Z Result_Folder_Path
      Else
         DoAlert 0, "Error! There is no file to analyse..."
      Endif
   Else
      DoAlert   0, "Error!  Result folder is blank..."
   Endif
End

// This function creates a wave (called Parameters) to keep the parameters of filters and defining noise
// used to process the data file (parameters in main panel).
Function Process_Parameters( )
   // Locals
   Variable Check_Filter
   // Globals
   Wave /T Parameters = Parameters
   NVar Scale_pAV = Scale_pAV
   NVar Smooth_Differentiate = Smooth_Differentiate
   NVar Slope_Threshold =    Slope_Threshold
   NVar Smooth_Factor = Smooth_Factor
   PauseUpdate; Silent 1
   Make /T /O /N=3 Parameters
   Parameters[0] = "Scale pAV: "+ Num2Str(Scale_paV)
   Parameters[1] = "Smooth 1st. Der: " + Num2Str(Smooth_Differentiate)
   Parameters[2] = "Slope Threshold: " + Num2Str(Slope_Threshold)
   ControlInfo /W=Main_Panel_Analysis  Check_FIR1
   Check_Filter = V_Value
   If ( Check_Filter )
      InsertPoints NumPnts(Parameters), 1, Parameters
      Parameters[NumPnts(Parameters) - 1] = "FIR1 applied"
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_FIR2
   Check_Filter = V_Value
   If ( Check_Filter )
      InsertPoints NumPnts(Parameters), 1, Parameters
      Parameters[NumPnts(Parameters) - 1] = "FIR2 applied"
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_Smooth
   Check_Filter = V_Value
   If ( Check_Filter )
      InsertPoints NumPnts(Parameters), 1, Parameters
      Parameters[NumPnts(Parameters) - 1] = "Smooth applied"
      InsertPoints NumPnts(Parameters), 1, Parameters
      Parameters[NumPnts(Parameters) - 1] = Num2Str(Smooth_Factor)
   EndIf
   ControlInfo /W=Main_Panel_Analysis  Check_Others_Filters
   Check_Filter = V_Value
   If ( Check_Filter )
      InsertPoints NumPnts(Parameters), 1, Parameters
      Parameters[NumPnts(Parameters) - 1] = "Others Filters"
   EndIf
End

// This macro shows an information panel about the timing of the process.
Macro Show_Info( )
   // Locals
   Variable Size_Rect
   Silent 1
   
   Size_Rect = 126 / Dis_Total_N
   If ( ! Dis_Id )  // If it is the first file to process, the information panel is made.
      Dis_Spk_N = 0
      Dis_Spk_Total = 0
      Dis_Name = " "
      DoWindow /K Info_Panel
      NewPanel /W=(229,156,435,313) as "Processed files..."
      DoWindow /C Info_Panel
      SetDrawLayer UserBack
      SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
      DrawRect 0,0,206,157
      DrawText 40,109,"Timing..."
      DrawRect 40,110,168,123
      ValDisplay ValDis_Id,pos={5,10},size={60,13},title="File:",font="Arial",fSize=12
      ValDisplay ValDis_Id,limits={0,0,0},barmisc={0,1000},value= #" Dis_Id"
      ValDisplay ValDis_Total_N,pos={70,10},size={65,13},title="of:",font="Arial"
      ValDisplay ValDis_Total_N,fSize=12,limits={0,0,0},barmisc={0,1000}
      ValDisplay ValDis_Total_N,value= #" Dis_Total_N"
      SetVariable ValDis_Dis_Name,pos={5,35},size={160,13},title="Last processed:"
      SetVariable ValDis_Dis_Name,font="Arial",fSize=12
      SetVariable ValDis_Dis_Name,limits={-Inf,Inf,1},value= Dis_Name
      ValDisplay ValDis_Spk,pos={5,60},size={90,13},title="Spikes:",font="Arial"
      ValDisplay ValDis_Spk,fSize=12,limits={0,0,0},barmisc={0,1000}
      ValDisplay ValDis_Spk,value= #" Dis_Spk_N"
      ValDisplay ValDis_Spk_Total,pos={100,60},size={90,13},title="Total:"
      ValDisplay ValDis_Spk_Total,font="Arial",fSize=12
      ValDisplay ValDis_Spk_Total,limits={0,0,0},barmisc={0,1000}
      ValDisplay ValDis_Spk_Total,value= #" Dis_Spk_Total"
      Button Close_Info_Panel,pos={90,129},size={40,20},proc=F_Bu_Close_Info_Panel,title="Close"
   Else  // If the information panel is already made, only it is drawn the timing bar.
      DoWindow  /F Info_Panel
      SetDrawEnv fillfgc= (0,15872,65280),linethick= 0.00
      DrawRect (41+ ( Dis_Id - 1)*Size_Rect), 111, ( 41+ (Dis_Id)*Size_Rect),122
   EndIf
EndMacro

// It kills the information panel when you click in Close button.
Function F_Bu_Close_Info_Panel(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Info_Panel
End

// This function makes the name of the folder where results will be saved.
// The name of the folder will be only the string typed in RESULT FOLDER of
// the main panel, if the checkbox "Several Folders" is not clicked.
// If it is clicked, the name of the folder will begin with the file name,
// plus date and time, so the results of each data file will saved in its own result folder.
Function /T Make_Result_Folder_Name( Result_Folder, Data_Comment, Data_File_Name)
   String Result_Folder, Data_Comment, Data_File_Name
   // Locals
   String Full_Folder_Name
   PauseUpdate; Silent 1
   ControlInfo /W=Main_Panel_Analysis  Several_Folders
   If ( V_Value )  // If results of each file will be saved in one different folder...
      Full_Folder_Name = Result_Folder + Data_Comment + "_" + Data_File_Name
   Else  // If results of all files are saved in the same folder...
      Full_Folder_Name = Result_Folder
   EndIf
   Return ( Full_Folder_Name)
End

//This function remove extension from string received as parameter.
Function /T RemoveExtension(FileName)
   String FileName
   Variable Counter, Total
   PauseUpdate; Silent 1
   Counter = StrLen(FileName)
   If (Counter > 0)
      Do
         Counter -= 1   
      While ((CmpStr(FileName[Counter], ".")) %& (Counter > 0))
      If (CmpStr(FileName[Counter], ".") == 0)
         FileName = FileName[0, Counter-1]
      EndIf
   EndIf
   Return(FileName)
End

// This function saves in hard disk results obtained from each data file.
Function Saving_Results( Result_Folder, Data_Comment, Data_File_Name )
   String Result_Folder, Data_Comment, Data_File_Name
   // Locals
   String DT_File
   String Full_Result_Folder
   PauseUpdate; Silent 1
   //Remove extension from Data_File_Name to create folder where results are saved.
   Data_File_Name = RemoveExtension(Data_File_Name)
   Full_Result_Folder = Make_Result_Folder_Name( Result_Folder, Data_Comment, Data_File_Name)
   KillPath /Z Result_Folder_Path
   NewPath /C /O /Q /Z Result_Folder_Path  Full_Result_Folder
   PathInfo Result_Folder_Path
   If ( V_Flag )
      Print Time(), "Saving Results..."
      Save /O /P=Result_Folder_Path   Data      as   "Data_"         + Data_File_Name
      Save /O /P=Result_Folder_Path   X_Peak      as   "X_Peak_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   X_Beginning   as   "X_Beginning_"   + Data_File_Name
      Save /O /P=Result_Folder_Path   X_Final      as   "X_Final_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   pC         as   "pC_"         + Data_File_Name
      Save /O /P=Result_Folder_Path   pA         as   "pA_"         + Data_File_Name
      Save /O /P=Result_Folder_Path   T_Half      as   "T_Half_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   pC_Third      as   "pC_Third_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   M_Half      as   "M_Half_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   T_Peak      as   "T_Peak_"      + Data_File_Name
      Save /O /P=Result_Folder_Path   TauUp   as   "TauUp_"   + Data_File_Name
      Save /O /P=Result_Folder_Path   TauDown   as   "TauDown_"   + Data_File_Name
      Save /O /P=Result_Folder_Path   Noise_Data   as   "Noise_Data_"   + Data_File_Name
      Save /O /P=Result_Folder_Path   Parameters   as   "Parameters_"   + Data_File_Name
   Else
      Print "Error!  It is imposible to create the result folder..."
   Endif
   KillPath /Z Result_Folder_Path
End

// It processes the wave Data where data have been loaded from file.
Function Processing_Wave( )
   // Locals
   Variable Number_Spikes
   // Globals
   Wave Data = Data
   NVar Scale_pAV = Scale_pAV
   NVar Smooth_Differentiate = Smooth_Differentiate
   NVar Slope_Threshold =    Slope_Threshold
   PauseUpdate; Silent 1
   Data   *=  Scale_pAV   *  1e-12
   WaveStats /Q Data
   SetScale y V_Min, V_Max, "A", Data
   Print Time(), "Filtering..."
   Filtering()
   Print Time(), "Differentiating..."
   Differentiating( Smooth_Differentiate)   // First derivative has been used to find peaks in a first pass.
   Print Time(), "Locating noise data..."   // A period of noise is searched to know the characteristics of noise.
   If ( F_Noise_Data() )
      Wave Noise_Data = Noise_Data
            //This wave is created by function F_Noise_Data. It is returned by the function.
      Print Time(), "Locating spikes..."
      Number_Spikes = Finding_Spikes(Slope_Threshold, Noise_Data[3])
      If ( Number_Spikes > 0)
         Parameters_Of_Spikes( Number_Spikes)  // Parameters of every spike found are calculated.
      Else
         Print "No spikes..."
      EndIf
   Else
      Print "Period of noise not found... Wave not processed..."   
   EndIf
   Return ( Number_Spikes)
End

// This function calculates caracteristics of spikes in waves: pC - charge, area; pA - maximum height;
// T_Half - half height width; pC_Third - pC powered to 1/3; T_Peak - time from quick rise (without
// considering foot) to peak; M_Half - slope from 25% to 75% of the spike rise; TauUp and TauDown
// are time from X_Peak until 1 - 1/e and 1/e respectively.
Function Parameters_Of_Spikes( Number_Spikes)
   Variable Number_Spikes
   // Locals
   Variable Pointer
   // Globals
   Wave X_Peak = X_Peak
   PauseUpdate; Silent 1
   Duplicate /O X_Peak, pC, pA, T_Half, pC_Third, T_Peak, M_Half, TauUp, TauDown
   Pointer = 0
   Do
      Calculate_Parameters_Spike( Pointer)
      Pointer += 1
   While ( Pointer < Number_Spikes)
End

//This function calculates the parameters of one spike.
Function Calculate_Parameters_Spike( Spike_Number)
   Variable Spike_Number
   // Globals
   Wave Data = Data
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pC = pC
   Wave pA = pA
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   PauseUpdate; Silent 1
   WaveStats /Q /R=( X_Beginning[ Spike_Number], X_Final[ Spike_Number]) Data
   X_Peak[ Spike_Number] = V_MaxLoc
   //Area in the spike is area down the spike less area between basal line and axis X.
   pC[ Spike_Number] = ( Area( Data, X_Beginning[ p], X_Final[ p]) - ( Data( X_Final[ p]) + Data( X_Beginning[ p])) * ( X_Final[ p] - X_Beginning[ p]) / 2) * 1e12
   pC_Third [Spike_Number] = pC[Spike_Number]^(1/3)
   pA[ Spike_Number] = ( Data( X_Peak[ p]) - (( Data( X_Final[ p]) - Data( X_Beginning[ p])) / ( X_Final[ p] - X_Beginning[ p]) * ( X_Peak[ p] - X_Beginning[ p]) + Data( X_Beginning[ p]))) * 1e12
   T_Half[ Spike_Number] = T_Half_Estimation( Data, X_Peak[ Spike_Number],X_Beginning[Spike_Number], X_Final[Spike_Number]) * 1e3
   Make /O /N=2 M_Half_And_T_Peak
   M_Half_And_T_Peak_Estimation(Data, X_Peak[Spike_Number], X_Beginning[Spike_Number], M_Half_And_T_Peak)
   M_Half[Spike_Number] = M_Half_And_T_Peak[0]
   T_Peak[Spike_Number] = M_Half_And_T_Peak[1]
   KillWaves /Z M_Half_And_T_Peak

   Make /O /N=2 TauUp_And_TauDown
   Calculate_Tau(Data, pA[Spike_Number]/(1e12), X_Peak[Spike_Number], X_Final[Spike_Number], TauUp_And_TauDown)
   TauUp[Spike_Number] = TauUp_And_TauDown[0] * 1e3
   TauDown[Spike_Number] = TauUp_And_TauDown[1] * 1e3
   KillWaves /Z TauUp_And_TauDown
End

//It calculates the TauUp and TauDown parameters.
Function Calculate_Tau(Data, IMax, Peak_Time, Final_Time, TauUp_And_TauDown)
   Wave Data
   Variable IMax, Peak_Time, Final_Time
   Wave TauUp_And_TauDown
   PauseUpdate; Silent 1
   TauUp_And_TauDown = 0
   // For avoiding error with the findlevel, we can use this sentence if...
   If ( Peak_Time < (Final_Time - DeltaX(Data)))
      //Here it is calculated TauUp, sustracting 36,7%*IMax from the highest point.
      FindLevel /Q /R=(Peak_Time, Final_Time) Data, Data(Peak_Time) - IMax*(1/e)
      TauUp_And_TauDown[0] = V_LevelX - Peak_Time
      //Here it is calculated TauDown, sustracting 63,2%*IMax  from the highest point.
      FindLevel /Q /R=(Peak_Time, Final_Time) Data, Data(Peak_Time) -  IMax*(1 - 1/e)
      TauUp_And_TauDown[1] = V_LevelX - Peak_Time
  EndIf
End

//It calculates the M_Half and T_Peak parameter.
Function M_Half_And_T_Peak_Estimation(Data, Peak_Time, Beginning_Time, M_Half_And_T_Peak)
   Wave Data
   Variable Peak_Time, Beginning_Time
   Wave M_Half_And_T_Peak = M_Half_And_T_Peak
   // Locals
   Variable x0, x1
   PauseUpdate; Silent 1
   M_Half_And_T_Peak = 0
   // For avoiding error with the findlevel, we can use this sentence if...
   If ( Beginning_Time < (Peak_Time - DeltaX(Data) ) )
      FindLevel /Q /R=(Beginning_Time, Peak_Time) Data, Data(Beginning_Time)+3*(Data(Peak_Time)-Data(Beginning_Time))/4
      x1 = V_LevelX
      FindLevel /Q /R=(Beginning_Time, Peak_Time) Data, Data(Beginning_Time)+(Data(Peak_Time)-Data(Beginning_Time))/4
      x0 = V_LevelX
      If ( X2Pnt(Data,x0) < X2Pnt(Data,x1)) //For avoiding error in Curvefit: insufficient range...
         CurveFit /Q Line Data(x0,x1) /D
         Wave W_Coef = W_Coef
         M_Half_And_T_Peak[0] = W_Coef[1] * 1e9  //M is the slope of the fit line between the 3/4 and 1/4 Imax points in the rise.
         //Time to peak: time from point PB to peak point of the spike. PB is the point where line with m slope
         //has the amplitude of the beginning of the spike.
         Variable PB = (Data(Beginning_Time) - W_Coef[0]) / W_Coef[1]
         M_Half_And_T_Peak[1] = (Peak_Time - PB) * 1e3
         KillWaves /Z Fit_Data,W_Coef
      EndIf
   EndIf
End

// This function locates maxima of spikes, searching quick increases in First_Derivative wave.
// When FindPeak locates a peak in first_derivative wave, it does not stop in the highest peak, but in the first peak.
// The first_derivative wave can have various peaks before decrease until the zero level, and we need only the highest peak
// in that period (between the first peak and the zero cross).
//  Then the cross by zero following that peak is found, and is located the highest peak between the first peak and that zero cross.
Function Finding_Peaks( Slope_Threshold, Slope_Std_Deviation )
   Variable Slope_Threshold, Slope_Std_Deviation
   // Locals
   Variable Beginning, Final
   Variable Pointer
   Variable Number_Spikes = 0
   Variable Threshold
   Variable Zero_Cross
   Variable Threshold_Cross
   Variable Found
   // Globals
   Wave First_Derivative = First_Derivative
   Wave Data = Data
   PauseUpdate; Silent 1
   Make /O /N=0 X_Beginning
   // First: locating quick increases in First_Derivative wave, higher than a threshold
   Threshold    = Slope_Threshold * Slope_Std_Deviation
   Beginning   = LeftX( First_Derivative)
   Final      = RightX( First_Derivative)
   Do
      FindLevel /Q /R=(Beginning, Final) First_Derivative, Threshold
      Found = ! V_Flag
      If (Found)         
         InsertPoints  Number_Spikes, 1, X_Beginning         
         //After a peak located, another higher peak can exist. FindPeak stops in the first peak, 
         //not in the maximum point higher than the threshold.
         //Find the following cross with 0, to locate the maximum in the first_derivative wave.
         Threshold_Cross = V_LevelX
         FindLevel /Q /R=(Threshold_Cross + DeltaX(First_Derivative),  Final) First_Derivative, 0
         If (! V_Flag)
            Zero_Cross = V_LevelX
            WaveStats /Q /R=(Threshold_Cross, Zero_Cross) First_Derivative
            X_Beginning[Number_Spikes] = V_MaxLoc
            Beginning = Zero_Cross
         Else
            X_Beginning[Number_Spikes] = Threshold_Cross
            Beginning = Threshold_Cross
         EndIf
         Beginning += DeltaX(First_Derivative)
         Number_Spikes += 1            
      EndIf
   While ( Found  %&  ( Beginning < Final) )   
   // If the last peak has the beginning at the end of the First_Derivative wave, it is removed, so the
   // following FindLevel does not return an error in any case (by insufficient range).
   If (Beginning >= Final)
      DeletePoints (Number_Spikes-1), 1, X_Beginning
   EndIf
   If ( Number_Spikes > 0)
    Duplicate /O X_Beginning X_Final
    Pointer = 0
    Do
       FindLevel /Q /R=( X_Beginning(Pointer) + DeltaX(Data), ) Data, Data( X_Beginning(Pointer))
       If ( ! V_Flag )
          X_Final[ Pointer] = V_LevelX
       Else
          X_Final[ Pointer] = RightX(Data)
       EndIf
       Pointer += 1
    While ( Pointer < Number_Spikes)
    Duplicate /O X_Beginning  X_Peak
    Pointer = 0
    Do
       WaveStats /Q /R = ( X_Beginning[ Pointer], X_Final[ Pointer]) Data
       X_Peak[ Pointer] = V_MaxLoc
       Pointer += 1
    While ( Pointer < Number_Spikes)
    // Some peaks may be repeated.
    Sort X_Peak, X_Peak
    If ( Number_Spikes > 1 )  // If there were only one spike, it can not be repeated
       Pointer = 0
       Do
          If ( X_Peak[ Pointer] == X_Peak[ Pointer + 1])
             DeletePoints ( Pointer + 1), 1, X_Peak
             Number_Spikes -= 1
          Else
             Pointer += 1
          EndIf
       While ( Pointer < ( Number_Spikes - 1) )
    EndIf
   EndIf
   KillWaves /Z X_Beginning, X_Final
   Return( Number_Spikes)
End   

// This function finds spikes, giving peak, beginning and final time of every spike.
Function Finding_Spikes( Slope_Threshold, Slope_Std_Deviation)
   Variable Slope_Threshold, Slope_Std_Deviation
   // Locals
   Variable Number_Spikes
   //Globals
   Wave Data = Data
   PauseUpdate; Silent 1
   Number_Spikes = Finding_Peaks( Slope_Threshold, Slope_Std_Deviation)
      // Find peaks above a threshold in the first derivative wave. Peak times are kept in wave X_Peak.
   If ( Number_Spikes > 0)
         Finding_Beginning_Final()
   EndIf
   Print Time(), "Found ", Number_Spikes," spikes."
   Return ( Number_Spikes)
End

//This function finds the beginning and final points of the spike.
Function Finding_Beginning_Final()
   // Locals
   Variable Pointer = 0
   Variable N_Spikes
   //Globals
   Wave X_Peak = X_Peak
   Wave Data = Data
   PauseUpdate; Silent 1
   Duplicate /O X_Peak X_Beginning, X_Final
   Finding_Beginning()
   Finding_Final()
   Correct_Beginning_Final()
End

//It corrects the beginning and final points in overlapped spikes.
Function Correct_Beginning_Final()
   // Locals
   Variable Pointer = 0
   Variable N_Spikes
   //Globals
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave Data = Data
   PauseUpdate; Silent 1
   N_Spikes = NumPnts(X_Peak) - 1
   If (N_Spikes > 0) //If only one spike is found, it is imposible two overlapped spikes.
      Pointer  = 0
      Do
         If (X_Final[Pointer] > X_Beginning[Pointer+1])
            WaveStats /Q /R=(X_Peak[Pointer], X_Peak[Pointer+1]) Data
            X_Final[Pointer] = V_MinLoc
            X_Beginning[Pointer+1] = V_MinLoc
         EndIf
         Pointer += 1
      While ( Pointer < N_Spikes )
   EndIf
End

//It finds the begin of all spikes.
Function Finding_Beginning()
   // Locals
   Variable Pointer = 0
   Variable N_Spikes
   //Globals
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave Data = Data
   PauseUpdate; Silent 1
   N_Spikes = NumPnts(X_Peak)
   Pointer  = 0
   Do
      X_Beginning[Pointer] = Spike_Beginning( Pointer)
      Pointer += 1
   While ( Pointer < N_Spikes )
End

//It finds the final of all spikes.
Function Finding_Final()
   // Locals
   Variable Pointer = 0
   Variable N_Spikes
   //Globals
   Wave X_Peak = X_Peak
   Wave X_Final = X_Final
   Wave Data = Data
   PauseUpdate; Silent 1
   N_Spikes = NumPnts(X_Peak)
   Pointer  = 0
   Do
      X_Final[Pointer] = Spike_Final( Pointer)
      Pointer += 1
   While ( Pointer < N_Spikes )
End

// This function finds the beginning of the spike, calculating previously the moda before the spike.
// It returns the beginning time of the spike.
Function Spike_Beginning(Spike_N)
   Variable Spike_N
   // Locals
   Variable From_X   // Time where histogram begins the calculations.
   Variable Histo_Period = 0.15 // Period of time in which histogram will be calculated.
   // Globals
   Wave Data = Data
   Wave X_Peak = X_Peak
   PauseUpdate; Silent 1
   From_X = X_Peak[Spike_N] - Histo_Period
   If (Spike_N > 0)
      If ( From_X  <  X_Peak[Spike_N-1] ) 
         From_X = X_Peak[Spike_N -1] - Histo_Period
      EndIf
   EndIf
   If ( From_X < LeftX(Data))
      From_X = LeftX(Data)
   EndIf
   If (From_X < (X_Peak[Spike_N] - 5*DeltaX(Data))) //If next histogram has sufficient range...
      Make  /O  Histo
      WaveStats /Q /R=(From_X, X_Peak[Spike_N]) Data
      Histogram /B={V_Min, 0.05e-12, (V_Max-V_Min)/0.05e-12} /R=(From_X, X_Peak[Spike_N]) Data, Histo
      WaveStats /Q Histo
      FindLevel /Q /R=(X_Peak[Spike_N], From_X ) Data, V_MaxLoc
      From_X = V_LevelX
      KillWaves /Z Histo
   EndIf
   Return ( From_X )
End

// This function finds the final of the spike, calculating the moda after the spike.
// It returns the final time of the spike.
Function Spike_Final( Spike_N)
   Variable Spike_N
   // Locals
   Variable To_X            // Time where histogram ends the calculation.
   Variable Histo_Period = 0.7   // Period of time in which histogram will be calculated.
   // Globals
   Wave Data = Data
   Wave X_Peak = X_Peak
   PauseUpdate; Silent 1
   To_X = X_Peak[Spike_N] + Histo_Period
   If (Spike_N < (NumPnts(X_Peak)-1))
      If ( To_X  >  X_Peak[Spike_N+1] ) 
         To_X = X_Peak[Spike_N+1] + Histo_Period
      EndIf
   EndIf
   If ( To_X > RightX(Data))
      To_X = RightX(Data)
   EndIf
   If (To_X > (X_Peak[Spike_N] + 5*DeltaX(Data))) //If next histogram has sufficient range...
      Make  /O  Histo
      WaveStats /Q /R=(X_Peak[Spike_N], To_X) Data
      Histogram /B={V_Min, 0.05e-12, (V_Max-V_Min)/0.05e-12} /R=(X_Peak[Spike_N], To_X) Data, Histo
      WaveStats /Q Histo
      FindLevel /Q /R=(X_Peak[Spike_N], To_X ) Data, V_MaxLoc
      To_X = V_LevelX
      KillWaves /Z Histo
   EndIf
   Return ( To_X )
End

// It differentiates wave Data but smoothing previously. The result wave is called First_Derivative.
Function Differentiating(Smooth_Der)
   Variable Smooth_Der
   // Globals
   Wave Data = Data
   PauseUpdate; Silent 1
   Duplicate /O Data First_Derivative
   If ( Smooth_Der)   // If it is 0, function Smooth would return error.
      Smooth (Smooth_Der), First_Derivative
   EndIf
   Differentiate First_Derivative
End

// This function finds from time From_X towards previous times the first point with value <= than Level_Wanted in wave Data_Wave.
// It returns the time of the point found.
Function Finding_Level_Backwards( Data_Wave, Level_Wanted, From_X)
   Wave Data_Wave
   Variable Level_Wanted, From_X
   // Locals
   Variable Pointer
   PauseUpdate; Silent 1
   Pointer = X2Pnt( Data_Wave, From_X)   // The finding begins from pointer.
   Do   // While level has not been found, pointer decreases.
      Pointer -= 1                     
   While ((( Data_Wave[ Pointer] - Level_Wanted) >= 0) %& ( Pointer > 0))
   Return ( Pnt2X( Data_Wave, Pointer))
End

// This function finds from time From_X towards following times the first point with value <= than Level_Wanted in wave Data_Wave.
// It returns the time of the point found.
Function Finding_Level_Towards( Data_Wave, Level_Wanted, From_X)
   Wave Data_Wave
   Variable Level_Wanted, From_X
   // Locals
   Variable Pointer
   PauseUpdate; Silent 1
   Pointer = X2Pnt( Data_Wave, From_X)   // The finding begins from pointer.
   Do   // While level has not been found, pointer increases.
      Pointer += 1
   While ((( Data_Wave[ Pointer] - Level_Wanted) >= 0) %& ( Pointer < NumPnts( Data_Wave)))
   Return ( Pnt2X( Data_Wave, Pointer))
End

// This function estimates the T_Half of one spike. T_Half is the width of the spike (time) on
// the half of the height of the spike. Level_Wanted keeps the value of the half of the height.
// It returns that T_Half.
Function T_Half_Estimation( Data_Wave, Peak_Time, Beginning_Time, Final_Time)
   Wave Data_Wave
   Variable Peak_Time, Beginning_Time, Final_Time
   // Locals
   Variable From_X_0, To_X_0
   Variable From_X_1, To_X_1
   Variable From_X, To_X, Level_Wanted_Ascent, Level_Wanted_Descent
   PauseUpdate; Silent 1
   Level_Wanted_Ascent = (Data_Wave(Peak_Time) - Data_Wave(Beginning_Time)) / 2  +  Data_Wave(Beginning_Time)
   Level_Wanted_Descent = (Data_Wave(Peak_Time) - Data_Wave(Final_Time)) / 2  +  Data_Wave(Final_Time)
   From_X_0 = Finding_Level_Backwards( Data_Wave, Level_Wanted_Ascent, Peak_Time)
   To_X_0 = Finding_Level_Towards( Data_Wave, Level_Wanted_Descent, Peak_Time)   
   From_X_1 = Pnt2X( Data_Wave, X2Pnt( Data_Wave, From_X_0) + 1)
   To_X_1 = Pnt2X( Data_Wave, X2Pnt( Data_Wave, To_X_0) - 1)
   From_X = ( From_X_1 - From_X_0) / ( Data_Wave( From_X_1) - Data_Wave( From_X_0)) * ( Level_Wanted_Ascent - Data_Wave( From_X_0)) + From_X_0
   To_X = ( To_X_1 - To_X_0) / ( Data_Wave( To_X_1) - Data_Wave( To_X_0)) * ( Level_Wanted_Descent - Data_Wave( To_X_0)) + To_X_0
   Return ( To_X - From_X)
End

// It extracts the last path used in Igor and it is showed in main panel, so user will know
// the format that has to be typed in folders asked in main panel.
Function /T Current_Path()
   String Path_String
   Variable Pointer
   PauseUpdate; Silent 1
   Path_String = PathList( "*", ";", "")
   Pointer = StrLen( Path_String) - 1
   Do
      Pointer -= 1
   While (( Pointer > 0)  %&  ( CmpStr( Path_String[ Pointer], ";") ) )
   If ( ! CmpStr( Path_String[ Pointer], ";" ) )
      Path_String = Path_String[ Pointer + 1, StrLen( Path_String) - 2]
   Else
      Path_String = Path_String[ 0, StrLen( Path_String) - 2]
   EndIf
   PathInfo $Path_String
   If ( V_Flag )
      Path_String = S_Path
   Else
      Path_String = "Not Found. Key it here!"
   Endif
   Return ( Path_String)
End

// It closes windows used in the procedure of analysis.
Function Kill_Windows_Analyse()
   PauseUpdate; Silent 1
   DoWindow /K Data_Table
   DoWindow /K Main_Panel_Analysis
   DoWindow /K Info_Panel
   DoWindow /K ChoosePanel
   F_Bu_Close_Filter_Graph("")
End

// It shows the main panel, where data and parameters used in the analysis are selected.
Window Main_Panel_Analysis() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(9,43,304,440) as "Selecting data and parameters..."
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect -3,0,387,421
   SetDrawEnv fname= "Arial",fstyle= 1
   SetDrawEnv save
   DrawText 8,19,"DATA FOLDER:"
   DrawText 8,56,"RESULT FOLDER:"
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 203,130,260,158
   DrawText 8,186,"FILTERS:"
   DrawText 89,186,"Test on file Id#"
   DrawText 8,353,"DEFINING NOISE:"
   DrawText 8,116,"DATA FILE NAME:"
   DrawText 205,105,"Scale (pA/V):"
   DrawText 85,210,"FIR1: 500-850 Hz"
   DrawText 85,234,"FIR2: 350-600 Hz"
   DrawText 84,258,"Smooth"
   DrawText 49,287,"Others"
   DrawText 128,353,"1D.Threshold"
   DrawText 7,370,"Smth.1stDer"
   DrawText 134,55,"Several folders"
   SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
   DrawLine 401,165,-1,165
   SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
   DrawLine 401,335,-1,335
   DrawText 8,95,"Comment:"
   DrawText 144,387,"Test on file Id#"
   SetVariable Set_File_Folder,pos={7,20},size={256,16},proc=FSetFileFolder,title=" "
   SetVariable Set_File_Folder,help={"Type here the full path of the folder where data file is."}
   SetVariable Set_File_Folder,font="Arial",limits={-Inf,Inf,0},value= File_Folder
   SetVariable Set_Result_Folder,pos={7,56},size={257,16},title=" "
   SetVariable Set_Result_Folder,help={"Type here the full path of the folder where results will be saved."}
   SetVariable Set_Result_Folder,font="Arial"
   SetVariable Set_Result_Folder,limits={-Inf,Inf,0},value= Result_Folder
   CheckBox Several_Folders,pos={116,42},size={16,12},title=""
   CheckBox Several_Folders,help={"Results of each data file will be saved in different folder when this check is clicked."},value=1
   SetVariable Set_Comment,pos={72,79},size={108,16},title=" "
   SetVariable Set_Comment,help={"Type here a comment to remember how the experiment was carried out. This comment will be used in the name of the folder where results will be saved."}
   SetVariable Set_Comment,font="Arial",limits={-Inf,Inf,1},value= Comment
   SetVariable Set_Scale_pAV,pos={205,106},size={55,16},title=" "
   SetVariable Set_Scale_pAV,help={"To do the conversion from volts to amperes."}
   SetVariable Set_Scale_pAV,font="Arial",format="%g"
   SetVariable Set_Scale_pAV,limits={-Inf,Inf,1},value= Scale_pAV
   Button Bu_Kill,pos={125,139},size={30,20},proc=F_Bu_Kill,title="Kill"
   Button Bu_Kill,help={"Kill or erase a data file previously added to the list of files to be processed."}
   Button Bu_Add,pos={87,139},size={30,20},proc=F_Bu_Add,title="Add"
   Button Bu_Add,help={"Add a data file to the list of files to be processed."}
   Button Bu_Run,pos={210,135},size={42,19},proc=F_Bu_Run,title="Run"
   Button Bu_Run,help={"Analyse each data file previously added to the list."}
   Button Bu_Test_Filter,pos={72,170},size={15,15},proc=F_Bu_Test_Filter,title=""
   Button Bu_Test_Filter,help={"Show a graph with data and data filtered to know the results of the filters selected below. It is filtered the data file selected in Id# which corresponds to Id# row of the table on the right."}
   SetVariable Filter_Test_File,pos={174,169},size={50,16},title=" "
   SetVariable Filter_Test_File,help={"Id# of data file to filter. It corresponds to file in Id# row of the table."}
   SetVariable Filter_Test_File,font="Arial",format="%g"
   SetVariable Filter_Test_File,limits={0,Inf,1},value= Filter_Test_File
   CheckBox Check_FIR1,pos={63,196},size={16,12},proc=F_Check_FIR1,title="",value=0
   CheckBox Check_FIR2,pos={63,220},size={16,12},proc=F_Check_FIR2,title="",value=0
   CheckBox Check_Smooth,pos={63,244},size={16,12},proc=F_Check_Smooth,title="",value=1
   CheckBox Check_Others_Filters,pos={31,274},size={16,12},proc=F_Check_Others_Filters,title="",value=0
   SetVariable Set_Slope_Threshold,pos={129,353},size={65,16},title=" "
   SetVariable Set_Slope_Threshold,help={"This value will be multiplied by the standard deviation of noise slope giving a threshold, which will be used in finding the peaks in first derivative of the data."}
   SetVariable Set_Slope_Threshold,font="Arial",format="%g"
   SetVariable Set_Slope_Threshold,limits={0,Inf,0.5},value= Slope_Threshold
   SetVariable Set_Smooth_Differentiate,pos={8,370},size={65,16},title=" "
   SetVariable Set_Smooth_Differentiate,help={"The data wave will be smoothed with this value before being differentiated."}
   SetVariable Set_Smooth_Differentiate,font="Arial",format="%g"
   SetVariable Set_Smooth_Differentiate,limits={0,Inf,1},value= Smooth_Differentiate
   Button Bu_Test_Threshold,pos={128,372},size={15,15},proc=F_Bu_Test_Threshold,title=""
   Button Bu_Test_Threshold,help={"Show a graph with first_derivative wave and the threshold corresponding to the value in 1D.Threshold."}
   SetVariable Threshold_Test_File,pos={227,371},size={45,16},title=" "
   SetVariable Threshold_Test_File,help={"Id# of data file to display threshold. It corresponds to file in Id# row of the table."}
   SetVariable Threshold_Test_File,font="Arial",format="%g"
   SetVariable Threshold_Test_File,limits={0,Inf,1},value= Threshold_Test_File
   SetVariable Set_Smooth_Factor,pos={135,241},size={50,16},title=" "
   SetVariable Set_Smooth_Factor,help={"Key here the factor for smoothing."}
   SetVariable Set_Smooth_Factor,font="Arial",format="%g"
   SetVariable Set_Smooth_Factor,limits={0,Inf,1},value= Smooth_Factor
   Button Bu_ChooseDataFolder,pos={265,20},size={20,15},proc=FBuChooseDataFolder,title="<>"
   Button Bu_ChooseResultFolder,pos={266,56},size={20,15},proc=FBuChooseResultFolder,title="<>"
   PopupMenu PopUpChooseFiles,pos={7,117},size={142,19},proc=FPopUpChooseFiles
   PopupMenu PopUpChooseFiles,mode=6,value= #"FilesInFileFolder"
EndMacro

//Function associates to PopUpChooseFiles of Main_Analysis_Panel.
Function FPopUpChooseFiles(ctrlName,popNum,PopString) : PopupMenuControl
   String ctrlName
   Variable popNum   // which item is currently selected (1-based)
   String PopString   // contents of current popup item as string
   SVar ItemSelected = ItemSelected
   PauseUpdate; Silent 1
   ItemSelected = PopString
End

//Function associates to Set_File_Folder of Main_Analysis_Panel to update the PopUpChooseFiles.
Function FSetFileFolder(CtrlName,varNum,Folder,varName) : SetVariableControl
   String CtrlName 
   Variable varNum   // value of variable as number
   String Folder   // value of variable as string
   String varName   // name of variable
   SVar FilesInFileFolder = FilesInFileFolder
   PauseUpdate; Silent 1
   FilesInFileFolder="All files;" + FindWavesInFolder(Folder)
   PopUpMenu PopUpChooseFiles mode=1
End

//This function must be called by button <> associated to Data Folder.
Function FBuChooseDataFolder(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   If (WinType("ChoosePanel") == 0)
      String /G VariableName = "File_Folder"
      String /G ProcName = "FSetFileFolder" //It is used in FBuOKFolder to execute the proc associated to setvariable.
      ChooseFolder(VariableName)
   Else
      DoWindow /F ChoosePanel
   EndIf
End

//This function must be called by button <> associated to Result Folder.
Function FBuChooseResultFolder(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   If (WinType("ChoosePanel") == 0)
      String /G VariableName = "Result_Folder"
      String /G ProcName = "" //It is used in FBuOKFolder to execute the proc associated to setvariable.
      ChooseFolder(VariableName)
   Else
      DoWindow /F ChoosePanel
   EndIf
End

Function ChooseFolder(VariableName)
   String VariableName
   SVar Folder = $VariableName
   String /G CurrentFolder = Folder
   String /G PopFolders
   String /G PopFiles
   PauseUpdate; Silent 1
   Execute "ChoosePanel()"
   FSetCurrentFolder("",0,CurrentFolder,"")
End

//Panel for selecting the folder where files are.
Window ChoosePanel() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(143,174,617,254) as "Choose folder..."
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect 474,-1,-5,269
   SetDrawEnv fstyle= 1
   SetDrawEnv save
   SetDrawEnv fname= "Arial"
   DrawText 8,19,"FOLDER:"
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 428,15,470,43
   SetDrawEnv fname= "Arial"
   DrawText 259,67,"Subfolders:"
   SetDrawEnv fname= "Arial"
   DrawText 38,66,"Files:"
   SetVariable Set_CurrentFolder,pos={7,21},size={417,16},proc=FSetCurrentFolder,title=" "
   SetVariable Set_CurrentFolder,font="Arial"
   SetVariable Set_CurrentFolder,limits={-Inf,Inf,0},value= CurrentFolder
   Button Bu_OKFolder,pos={435,20},size={29,20},proc=FBuOKFolder,title="OK"
   PopupMenu PopUpFolders,pos={329,47},size={70,19},proc=FPopUpFolders
   PopupMenu PopUpFolders,mode=1,value= #"PopFolders"
   PopupMenu PopUpFiles,pos={72,47},size={70,19},mode=1,value= #"PopFiles"
EndMacro

//This function is run when folder has been completed.
Function FBuOKFolder(CtrlName)
   String CtrlName
   SVar CurrentFolder = CurrentFolder
   SVar VariableName = VariableName
   SVar Folder = $VariableName
   SVar ProcName = ProcName
   PauseUpdate; Silent 1
   DoWindow /K ChoosePanel
   Folder = CurrentFolder
   If (StrLen(ProcName)) //To execute the proc associated to Set_Variable with variable Folder.
      Execute ProcName+"(\"\",0, $VariableName, \"\")"
   EndIf
   KillStrings /Z CurrentFolder, PopFolders, VariableName, PopFiles, ProcName
End

//Function associates to Set_CurrentFolder of ChoosePanel. 
Function FSetCurrentFolder(CtrlName,varNum,Folder,varName) : SetVariableControl
   String CtrlName 
   Variable varNum   // value of variable as number
   String Folder   // value of variable as string
   String varName   // name of variable
   SVar PopFolders = PopFolders
   SVar PopFiles = PopFiles
   SVar CurrentFolder = CurrentFolder
   PauseUpdate; Silent 1
   CurrentFolder = LastSemicolon(CurrentFolder)
   If (StrLen(CurrentFolder) == 0)
      CurrentFolder = HardDiskName()
   EndIf
   NewPath /Z /O  /Q  PathCurrentFolder  CurrentFolder
   PathInfo PathCurrentFolder
   If (!V_Flag)
      DoAlert 1, "Folder does not exist...  MAKE IT?\r" + CurrentFolder
      If (V_Flag == 2)
         Do
            UpFolder()
            NewPath /Z /O /Q  PathCurrentFolder  CurrentFolder
            PathInfo PathCurrentFolder
         While (V_Flag == 0)
      Else
         NewPath /C /Z /O /Q  PathCurrentFolder  CurrentFolder
         PathInfo PathCurrentFolder
         If (V_Flag == 0)
            DoAlert 0, "Folder not created!\rYou must make the higher level in directory tree..."
            Do
               UpFolder()
               NewPath /Z /O /Q  PathCurrentFolder  CurrentFolder
               PathInfo PathCurrentFolder
            While (V_Flag == 0)
         EndIf
      EndIf
   EndIf   
   If (V_Flag)
      NewPath /Z /O  /Q  PathCurrentFolder  S_Path
      CurrentFolder = S_Path
      PopFolders = IndexedDir(PathCurrentFolder, -1, 0)
      PopFolders = SortFolders(PopFolders)
      PopFolders = "<< UP >>;" + PopFolders
      PopFiles = IndexedFile(PathCurrentFolder, -1, "????")
      PopFiles = SortFolders(PopFiles)
      PopFiles = " ;"+PopFiles
   EndIf
   PopUpMenu PopUpFolders mode=1
   PopUpMenu PopUpFiles mode=1
   ControlUpdate /A
   KillPath /Z PathCurrentFolder
End

//Function associates to PopUpFolders of ChoosePanel.
Function FPopUpFolders(ctrlName,popNum,Folder) : PopupMenuControl
   String ctrlName
   Variable popNum   // which item is currently selected (1-based)
   String Folder   // contents of current popup item as string
   SVar CurrentFolder = CurrentFolder
   PauseUpdate; Silent 1
   If (PopNum > 1)
      CurrentFolder += Folder
      CurrentFolder += ":"
      FSetCurrentFolder("",0,CurrentFolder,"")
      PopUpMenu $CtrlName mode=1
      ControlUpdate /A
   Else
      UpFolder()
      FSetCurrentFolder("", 0, "", "")
   EndIf
End

//This function steps up in the directory tree (Current Folder).
Function UpFolder()
   Variable Position
   SVar CurrentFolder = CurrentFolder
   PauseUpdate; Silent 1
   If (StrLen(CurrentFolder) > 0)
      Position = StrLen(CurrentFolder) - 1
      Do
         Position -= 1
      While ((Position >= 0)  %&  (CmpStr(CurrentFolder[Position], ":") != 0))
      If (Position >= 0)
         CurrentFolder = CurrentFolder[0, Position]
      EndIf
   EndIf
End

//It returns the name of the local hard disk where Igor is installed.
Function /T HardDiskName()
   String HardDisk
   Variable Position
   PauseUpdate; Silent 1
   PathInfo Igor
   If (V_Flag)
      Position = StrSearch(S_Path, ":", 0)
      If (Position > 0)
         HardDisk = S_Path[0,Position]
      Else
         HardDisk = S_Path
      EndIf
   Else
      HardDisk = "C:"   
   EndIf
   Return(HardDisk)
End

//It sorts the folders in the parameter Folders, where each folder is separated by ";".
Function /T SortFolders(Folders)
   String Folders
   Variable Counter, Total, InitialPosition
   PauseUpdate; Silent 1
   Total = StrLen(Folders)
   If (Total > 0)
      Counter = 0
      InitialPosition = 0
      Make /T /N=0 FolderWave
      Do
         If (CmpStr(Folders[Counter], ";") == 0)
            InsertPoints NumPnts(FolderWave), 1, FolderWave
            FolderWave[NumPnts(FolderWave)-1] = Folders[InitialPosition, Counter-1]
            InitialPosition = Counter + 1
         EndIf
         Counter += 1
      While (Counter < Total)
      Sort FolderWave FolderWave
      Counter = 0
      Total = NumPnts(FolderWave)
      Folders = ""
      Do
         Folders += FolderWave[Counter]
         Folders += ";"
         Counter += 1
      While (Counter < Total)
      KillWaves FolderWave
   EndIf
   Return(Folders)
End

//It adds a semicolon at the end of the parameter Folder when it does not exist.
Function /T LastSemicolon (Folder)
   String Folder
   String LastCharacter
   Variable NumberOfCharacters
   PauseUpdate; Silent 1
   If (StrLen(Folder) > 0)
      NumberOfCharacters = StrLen(Folder)
      LastCharacter = Folder[NumberOfCharacters - 1]
      If (CmpStr(LastCharacter, ":") != 0)
         Folder += ":"
      EndIf
   EndIf
   Return(Folder)
End

///////////////////////////////////////////////////////////////////////
///////  SECOND PART:  CHECK SPIKES 
////////////////////////////////////////////////////////////////////////
//This is the initial function of the second part of the program.
Function Spike_View()
   // Locals
   Variable Go_To_Save = 0
   PauseUpdate; Silent 1
   If ( Exists( "Making_Spike_View"))
      DoAlert 2, "Not all result files are saved, save them now?"
      If ( V_Flag == 1)
         Go_To_Save = 1
         F_Bu_Show_Save_Panel(" ")
      Else
         If (V_Flag == 3)
            Go_To_Save = 1
         EndIf
      EndIf
   EndIf

   If ( ! Go_To_Save)
      KillVariables /Z Making_Spike_View
      Kill_Windows_Analyse()
      Kill_Windows_Check()
      Kill_Windows_Gallery()
      Creating_Objects_Check()
      Execute "Load_Panel()"
   EndIf
End

// Create global waves and variables.
Function Creating_Objects_Check()
   PauseUpdate; Silent 1
   // To begin without objects of others options in memory.
   KillWaves /A /Z
   // KillVariables /A /Z
   // KillStrings /A /Z
   String /G Exp_Folder = Current_Path()
   String /G Exp_Name = "Exp01"
   FSetExpFolder("",0,Exp_Folder,"Exp_Folder")
   String /G Exp_Name_Show = "Exp01"
   Make /O X_Peak,X_Beginning, X_Final 
   Make /O pC, pA, T_Half
   Make /O M_Half, T_Peak, pC_Third
   Make /O TauUp, TauDown
   Variable /G Number_Of_Spikes
   Variable /G Number_Current_Spike = 0, Dots = 0, Spike_Tags = 0
   Variable /G Spike_To_Go = 0
   String /G Checked_Result_Folder = Current_Path()
End

//Main Panel of the second part of the program
Window Main_Panel_Check() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(7,42,204,190) as "Analysis Panel "
	ModifyPanel cbRGB=(52224,52224,52224)
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
	DrawRect -3,-3,202,166
	SetDrawEnv fillfgc= (65280,21760,0),fsize= 9
	SetDrawEnv save
	SetDrawEnv linefgc= (65280,21760,0)
	SetDrawEnv save
	SetDrawEnv linefgc= (34816,34816,34816),fillfgc= (34816,34816,34816)
	SetDrawEnv save
	SetDrawEnv linefgc= (0,0,0)
	SetDrawEnv save
	SetDrawEnv fillfgc= (52224,52224,52224)
	SetDrawEnv save
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 5,63,193,112
	SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
	DrawText 4,18,"EXPERIMENT NAME:"
	SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
	DrawText 134,18,"Spikes:"
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 35,116,92,144
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 105,116,162,144
	SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
	DrawText 92,57,"Noise data"
	Button Bu_Traces,pos={101,67},size={88,20},proc=F_Bu_Traces,title="Traces"
	Button Bu_Traces,help={"Click here to show the three graphs."}
	Button Bu_Spike_Tags,pos={9,67},size={88,20},proc=F_Bu_Spike_Tags,title="Spike tags"
	Button Bu_Spike_Tags,help={"Click here for tagging all spikes."}
	Button Bu_Show_Load_Panel,pos={42,120},size={43,20},proc=F_Bu_Show_Load_Panel,title="Load"
	Button Bu_Show_Load_Panel,help={"Load files resulting from \"Spike Analysis\" ."}
	Button Bu_Show_Save_Panel,pos={113,120},size={42,20},proc=F_Bu_Show_Save_Panel,title="Save"
	Button Bu_Show_Save_Panel,help={"Save corrected data."}
	Button Bu_Charge,pos={101,89},size={88,20},proc=F_Bu_Charge,title="Total charge"
	Button Bu_Charge,help={"Click here if you want to see the temporal evolution of the charge."}
	Button Bu_Histogram,pos={9,89},size={88,20},proc=F_Bu_Histogram,title="Histograms"
	Button Bu_Histogram,help={"Construct histogram result."}
	ValDisplay ValDis_Number_Spikes,pos={133,18},size={50,16}
	ValDisplay ValDis_Number_Spikes,help={"Number of spikes in this experiment."}
	ValDisplay ValDis_Number_Spikes,font="Arial",limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDis_Number_Spikes,value= #"Number_Of_Spikes"
	SetVariable Set_Dis_Exp_Name,pos={4,18},size={75,16},proc=F_Set_Dis_Exp_Name,title=" "
	SetVariable Set_Dis_Exp_Name,font="Arial"
	SetVariable Set_Dis_Exp_Name,limits={-Inf,Inf,1},value= Exp_Name_Show
	CheckBox Check_Noise_Data,pos={74,44},size={16,11},proc=F_Check_Noise_Data,title=""
	CheckBox Check_Noise_Data,help={"Click here for showing/hiding information about the segment of noise analysis."},value=0
EndMacro

//Function associated to Exp_Name object of the panel.
Function F_Set_Dis_Exp_Name( CtrlName, VarNum, VarStr, VarName) : SetVariableControl
   String CtrlName
   Variable VarNum   // value of variable as number
   String VarStr      // value of variable as string
   String VarName   // name of variable
   // Globals
   SVar Exp_Name = Exp_Name
   SVar Exp_Name_Show = Exp_Name_Show
   PauseUpdate; Silent 1
   Exp_Name_Show = Exp_Name
End

//Function associated to an object of the panel.
Function F_Bu_Show_Load_Panel( CtrlName)
   String CtrlName
   // Locals
   Variable Go_To_Save = 0
   PauseUpdate; Silent 1
   If ( Exists( "Making_Spike_View"))
      DoAlert 2, "Not all result files are saved, save them now?"
      If ( V_Flag == 1)
         Go_To_Save = 1
         F_Bu_Show_Save_Panel(" ")
      Else
         If (V_Flag == 3)
            Go_To_Save = 1
         Else
            KillVariables /Z Making_Spike_View
         EndIf
      EndIf
   EndIf
   If ( ! Go_To_Save)
      If ( WinType( "Load_Panel") == 0)
         Execute "Load_Panel()"
      Else
         DoWindow /F Load_Panel
      EndIf
   EndIf
End

Function F_Bu_Cancel_Load( CtrlName) //Function associated to an object of the panel.
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Load_Panel
   DoWindow /K ChoosePanel
End

// Load each result wave from an experiment in waves with their original
// names and display graphics to examine spikes.
Function F_Bu_Load_Waves_Exp( CtrlName )
   String CtrlName
   // Globals
   SVar Exp_Folder = Exp_Folder
   SVar Exp_Name = Exp_Name
   PauseUpdate; Silent 1
   DoWindow /K  ChoosePanel
   If ( StrLen( Exp_Folder))
      If ( CmpStr( Exp_Folder[StrLen(Exp_Folder) - 1], ":" ) )
         Exp_Folder = Exp_Folder + ":"
      EndIf
      // Checking if experiment folder is right.
      KillPath /Z Exp_Folder_Path
      NewPath  /Z  /O  /Q  Exp_Folder_Path  Exp_Folder
      PathInfo Exp_Folder_Path
      If ( V_Flag )
         If ( Load_Waves_Exp(Exp_Name, Exp_Folder))   // If waves are loaded correctly...
            KillWaves /Z Data_Erased_Spike
            Making_Panel_Graphs()
         EndIf
      Else
         DoAlert 0, "Error!  Experiment folder wrong..."
      EndIf
      KillPath /Z Exp_Folder_Path
   Else
      DoAlert   0, "Error!  Experiment folder is blank..."
   Endif
   KillPath /Z Exp_Folder_Path
End

//It loads files in RAM from hard disk.
Function Load_Waves_Exp(Exp_Name, Exp_Folder)
   String Exp_Name, Exp_Folder
   // Locals
   Variable Load_Correct = 1   // If any error ocurrs, Load_Correct will be 0.
   PauseUpdate; Silent 1
   If ( ! Find_File("Data_" + Exp_Name, Exp_Folder))
      Loading_File( Exp_Folder, "Data_" + Exp_Name)
      If ( ! Find_File("X_Peak_" + Exp_Name, Exp_Folder))
         Loading_File( Exp_Folder, "X_Peak_" + Exp_Name)
         If ( ! Find_File( "X_Beginning_" + Exp_Name, Exp_Folder))
            Loading_File( Exp_Folder, "X_Beginning_" + Exp_Name)
            If ( ! Find_File( "X_Final_" + Exp_Name, Exp_Folder))
               Loading_File( Exp_Folder, "X_Final_" + Exp_Name)
               If ( ! Find_File( "pC_" + Exp_Name, Exp_Folder))
                  Loading_File( Exp_Folder, "pC_" + Exp_Name)
                  If ( ! Find_File( "pA_" + Exp_Name, Exp_Folder))
                     Loading_File( Exp_Folder, "pA_" + Exp_Name)
                     If ( ! Find_File( "T_Half_" + Exp_Name, Exp_Folder))
                        Loading_File( Exp_Folder, "T_Half_" + Exp_Name)
                        If ( ! Find_File( "pC_Third_" + Exp_Name, Exp_Folder))
                           Loading_File( Exp_Folder, "pC_Third_" + Exp_Name)
                           If ( ! Find_File( "M_Half_" + Exp_Name, Exp_Folder))
                              Loading_File( Exp_Folder, "M_Half_" + Exp_Name)
                              If ( ! Find_File( "T_Peak_" + Exp_Name, Exp_Folder))
                                 Loading_File( Exp_Folder, "T_Peak_" + Exp_Name)
                                If ( ! Find_File( "TauUp_" + Exp_Name, Exp_Folder))
                                   Loading_File( Exp_Folder, "TauUp_" + Exp_Name)
                                 If ( ! Find_File( "TauDown_" + Exp_Name, Exp_Folder))
                                    Loading_File( Exp_Folder, "TauDown_" + Exp_Name)
                                  If ( ! Find_File( "Noise_Data_" + Exp_Name, Exp_Folder))
                                     Loading_File( Exp_Folder, "Noise_Data_" + Exp_Name)
                                    If ( ! Find_File( "Parameters_" + Exp_Name, Exp_Folder))
                                       Loading_File( Exp_Folder, "Parameters_" + Exp_Name)
                                    Else
                                       Load_Correct = 0
                                       DoAlert 0, "File  Parameters_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                                    EndIf
                                  Else
                                     Load_Correct = 0
                                     DoAlert 0, "File  Noise_Data_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                                  EndIf
                                 Else
                                    Load_Correct = 0
                                    DoAlert 0, "File  TauDown_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                                 EndIf
                                Else
                                   Load_Correct = 0
                                   DoAlert 0, "File  TauUp_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                                EndIf
                              Else
                                 Load_Correct = 0
                                 DoAlert 0, "File  T_Peak_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                              EndIf
                           Else                        
                              Load_Correct = 0
                              DoAlert 0, "File  M_Half_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                           EndIf
                        Else
                           Load_Correct = 0
                           DoAlert 0, "File  pC_Third_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                        EndIf
                     Else
                        Load_Correct = 0
                        DoAlert 0, "File  T_Half_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                     EndIf
                  Else
                     Load_Correct = 0
                     DoAlert 0, "File  pA_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
                  EndIf
               Else
                  Load_Correct = 0
                  DoAlert 0, "File  pC_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
               EndIf
            Else
               Load_Correct = 0
               DoAlert 0, "File  X_Final_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
            EndIf
         Else
            Load_Correct = 0
            DoAlert 0, "File  X_Beginning_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
         EndIf
      Else
         Load_Correct = 0
         DoAlert 0, "File  X_Peak_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
      EndIf
   Else
      Load_Correct = 0
      DoAlert 0, "File  Data_" + Exp_Name + " in folder " + Exp_Folder + " \rdoes not exist. Load incomplete."
   EndIf
   Return( Load_Correct)
End

Function Making_Panel_Graphs() //It creates the graphs of this second part.
   // Globals
   SVar Exp_Name = Exp_Name
   SVar Exp_Name_Show = Exp_Name_Show
   NVar Number_Of_Spikes = Number_Of_Spikes
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Spike_To_Go = Spike_To_Go
   Wave X_Beginning = X_Beginning
   Wave X_Peak = X_Peak
   Wave X_Final = X_Final
   Wave Data = Data
   PauseUpdate; Silent 1
   Exp_Name_Show = Exp_Name
   Kill_Windows_Check()
   Execute "Main_Panel_Check()"
   CheckBox Check_Noise_Data, value = 0
   Number_Current_Spike = 0
   Spike_To_Go = 0
   Number_Of_Spikes = NumPnts( X_Beginning)
   Make /O /N=2 Basal
   SetScale /I x, X_Beginning[ 0], X_Final[0],"s", Basal
   Basal[ 0] = Data( X_Beginning[ 0])
   Basal[ 1] = Data( X_Final[ 0])
   Duplicate /O/R=( X_Beginning[ 0] - 0.05, X_Final[ 0] + 0.2) Data, Current_Spike
   Execute "Graph_All_Data()"
   DoWindow /T Graph_All_Data Exp_Name
   Execute "Graph_Spike_Other_Scale()"
   Execute "Graph_Spike()"
   Update_Graph_Spike( 0)
End

Function F_Bu_Show_Save_Panel( CtrlName)
   String CtrlName
   // Globals
   SVar Checked_Result_Folder = Checked_Result_Folder
   SVar Exp_Folder = Exp_Folder
   PauseUpdate; Silent 1
   Checked_Result_Folder = Exp_Folder
   If ( WinType( "Save_Panel") == 0)
      Execute "Save_Panel()"
   Else
      DoWindow /F Save_Panel
   EndIf
End

Window Save_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(10,108,521,199) as "Saving experiment..."
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
	DrawRect -2,-2,558,116
	SetDrawEnv fstyle= 1
	SetDrawEnv save
	SetDrawEnv fname= "Arial"
	DrawText 8,19,"SAVING FOLDER:"
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 143,51,200,79
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 220,51,277,79
	SetVariable Set_Checked_Result_Folder,pos={6,20},size={471,16},title=" "
	SetVariable Set_Checked_Result_Folder,help={"Type here the full path of the folder where experiment waves will be saved: Data, X_Peak, X_Beginning, X_Final, etc."}
	SetVariable Set_Checked_Result_Folder,font="Arial"
	SetVariable Set_Checked_Result_Folder,limits={-Inf,Inf,0},value= Checked_Result_Folder
	Button Bu_Save_Exp,pos={151,56},size={42,19},proc=F_Bu_Save_Exp,title="Save"
	Button Bu_Cancel_Save_Exp,pos={226,55},size={46,20},proc=F_Bu_Cancel_Save_Exp,title="Cancel"
	Button Bu_ChooseExpFolder,pos={482,20},size={20,15},proc=FBuChooseCheckedResultFolder,title="<>"
EndMacro

//This function must be called by button <> associated to Saving Folder (String  Checked_Result_Folder).
Function FBuChooseCheckedResultFolder(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   If (WinType("ChoosePanel") == 0)
      String /G VariableName = "Checked_Result_Folder"
      String /G ProcName = "" //It is used in FBuOKFolder to execute the proc associated to setvariable.
      ChooseFolder(VariableName)
   Else
      DoWindow /F ChoosePanel
   EndIf
End

Function F_Bu_Cancel_Save_Exp( CtrlName)
   String CtrlName
   PauseUpdate; Silent 1   
   DoWindow /K Save_Panel
End

Function F_Bu_Save_Exp( CtrlName)
   String CtrlName
   // Locals
   Variable Pointer = 0   // To indicate the number of files saved.
   Variable Overwrite_All
   Variable Overwrite_NoOne
   // Globals
   SVar Checked_Result_Folder = Checked_Result_Folder
   SVar Exp_Name = Exp_Name
   Wave Data = Data
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   Wave Noise_Data = Noise_Data
   Wave Parameters = Parameters
   PauseUpdate; Silent 1
   KillPath /Z Checked_Result_Folder_Path
   NewPath /C /O /Q /Z Checked_Result_Folder_Path  Checked_Result_Folder
   PathInfo Checked_Result_Folder_Path
   If ( V_Flag )
      If ( ! Find_File("Data_" + Exp_Name, Checked_Result_Folder))
         DoAlert 1, "File  Data_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
         If ( V_Flag == 1)
            Save /O /P=Checked_Result_Folder_Path   Data      as   "Data_"         + Exp_Name
            Pointer += 1
            DoAlert 1, "Overwrite all files?"
            Overwrite_All = V_Flag
         Else
            DoAlert 1, "Skip all files without overwriting?"
            Overwrite_NoOne = V_Flag
         EndIf
      Else
         Save /O /P=Checked_Result_Folder_Path   Data      as   "Data_"         + Exp_Name
         Pointer += 1
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("X_Peak_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  X_Peak_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   X_Peak      as   "X_Peak_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   X_Peak      as   "X_Peak_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("X_Beginning_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  X_Beginning_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   X_Beginning      as   "X_Beginning_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   X_Beginning      as   "X_Beginning_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("X_Final_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  X_Final_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   X_Final      as   "X_Final_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   X_Final      as   "X_Final_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("pC_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  pC_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   pC      as   "pC_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   pC      as   "pC_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("pA_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  pA_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   pA      as   "pA_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   pA      as   "pA_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("T_Half_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  T_Half_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   T_Half      as   "T_Half_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   T_Half      as   "T_Half_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("pC_Third_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  pC_Third_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   pC_Third      as   "pC_Third_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   pC_Third      as   "pC_Third_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("M_Half_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  M_Half_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   M_Half      as   "M_Half_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   M_Half      as   "M_Half_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("T_Peak_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  T_Peak_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   T_Peak      as   "T_Peak_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   T_Peak      as   "T_Peak_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("TauUp_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  TauUp_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   TauUp      as   "TauUp_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   TauUp      as   "TauUp_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("TauDown_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  TauDown_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   TauDown      as   "TauDown_"      + Exp_Name
               Pointer += 1
               DoAlert 1, "Overwrite all following files?"
               Overwrite_All = V_Flag
            Else
               DoAlert 1, "Skip all files without overwrite?"
               Overwrite_NoOne = V_Flag
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   TauDown      as   "TauDown_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("Noise_Data_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  Noise_Data_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   Noise_Data      as   "Noise_Data_"      + Exp_Name
               Pointer += 1
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   Noise_Data      as   "Noise_Data_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
      If ( Overwrite_NoOne != 1)
         If (( ! Find_File("Parameters_" + Exp_Name, Checked_Result_Folder)) %& (Overwrite_All != 1)  )
            DoAlert 1, "File  Parameters_" + Exp_Name + " in folder " + Checked_Result_Folder + " already exists.\rOverwrite?"
            If ( V_Flag == 1)
               Save /O /P=Checked_Result_Folder_Path   Parameters      as   "Parameters_"      + Exp_Name
               Pointer += 1
            EndIf
         Else
            Save /O /P=Checked_Result_Folder_Path   Parameters      as   "Parameters_"      + Exp_Name
            Pointer += 1
         EndIf
      EndIf
   Else
      Print "Error!  It is imposible to create the result folder..."
   Endif
   KillPath /Z Result_Folder_Path
   DoWindow /K Save_Panel
   If ( Pointer == 14)
      KillVariables /Z Making_Spike_View  // To indicate that all result files are saved.
   EndIf
End

Function F_Bu_Traces( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Spike_Tags = Spike_Tags
   Wave X_Peak = X_Peak
   PauseUpdate; Silent 1
   If ( WinType( "Graph_All_Data") == 0)
      Execute "Graph_All_Data()"
      Tag /C /N=Tag_Spike /B=(5,5,56000) Data, X_Peak[ Number_Current_Spike]
      DoWindow /F Main_Panel_Check
      Button Bu_Spike_Tags,title="Spike tags"
      Spike_Tags = 0
   EndIf
   If ( WinType( "Graph_Spike") == 0)
      Execute "Graph_Spike()"
      Update_Graph_Spike( Number_Current_Spike)
   EndIf
   If ( WinType( "Graph_Spike_Other_Scale") == 0)
      Execute "Graph_Spike_Other_Scale()"
   EndIf
End

Function F_Bu_Spike_Tags( CtrlName)
   String CtrlName
   // Locals
   Variable Pointer = 0
   // Globals
   NVar Number_Of_Spikes = Number_Of_Spikes
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Spike_Tags = Spike_Tags
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   PauseUpdate; Silent 1
   If ( WinType("Graph_All_Data") == 0)
      Execute "Graph_All_Data()"
      Tag /C /N=Tag_Spike /B=(5,5,56000) Data, X_Peak[ Number_Current_Spike]
   EndIf
   DoWindow /F Graph_All_Data
   If ( Spike_Tags)
      Do
         Tag /K /N=$("Text"+Num2Str(Pointer))
         Pointer += 1
      While ( Pointer < (Number_Of_Spikes * 3))
      DoWindow /F Main_Panel_Check
      Button Bu_Spike_Tags,title="Spike tags"
      Spike_Tags = 0
   Else
      Do
         Tag /I=1 /F=0 /X=0.00 /Y=10.00 /B=1 /L=0 Data, X_Peak[ Pointer], Num2Str( Pointer)
         Pointer += 1
      While ( Pointer < Number_Of_Spikes)
      DoWindow /F Main_Panel_Check
      Button Bu_Spike_Tags,title="No spike tags"
      Spike_Tags = 1
   EndIf
   DoWindow /F Graph_Spike
End

Function Update_Graph_Spike( Number_Spike)
   Variable Number_Spike
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave Data = Data
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   Wave Basal = Basal
   PauseUpdate; Silent 1
   If ( Number_Of_Spikes)
      If ( WinType("Graph_Spike") == 0)
         Execute "Graph_Spike()"
      EndIf
      TextBox /K /N=Text_Overlapped_Previous
      TextBox /K /N=Text_Overlapped_Next
      Variable Common_Points
      If ( Number_Spike > 0)
         Common_Points = X2Pnt(Data, X_Beginning[ Number_Spike]) - X2Pnt(Data, X_Final[ Number_Spike - 1])
         If ( Common_Points < 0)
            DoWindow /F Graph_Spike
            TextBox /N=Text_Overlapped_Previous /G=(0,0,65000) /F=0 /A=LT Num2Str(-Common_Points)+" points overlapped with PREVIOUS spike."
         EndIf
      EndIf
      If ( Number_Spike < ( Number_Of_Spikes - 1))
         Common_Points = X2Pnt(Data, X_Beginning[ Number_Spike + 1]) - X2Pnt(Data, X_Final[ Number_Spike])
         If ( Common_Points < 0)
            DoWindow /F Graph_Spike
            TextBox /N=Text_Overlapped_Next /G=(0,0,65000) /F=0 /A=RC Num2Str(-Common_Points)+" points overlapped with NEXT spike."
         EndIf
      EndIf
      Number_Current_Spike = Number_Spike
      If (WinType("Graph_All_Data") != 0) 
         DoWindow  /F  Graph_All_Data
         GetAxis /Q Bottom
         If (( X_Peak[ Number_Spike] < V_Min) %| ( X_Peak[ Number_Spike] > V_Max))
            SetAxis /Z Bottom, (X_Peak[ Number_Spike] - ((V_Max - V_Min) / 2)), (X_Peak[ Number_Spike] + ((V_Max - V_Min) / 2))
         EndIf
         Tag /C /N=Tag_Spike /B=(5,5,56000) Data, X_Peak[ Number_Spike]
      EndIf
        SetScale /I x, X_Beginning[ Number_Spike], X_Final[ Number_Spike],"s", basal
        basal[0]=Data(X_Beginning[ Number_Spike])
        basal[1]=Data(X_Final[ Number_Spike])
        Duplicate /O/R=(X_Beginning[ Number_Spike]-0.05, X_Final[ Number_Spike]+0.2) Data, Current_Spike
        DoWindow /F Graph_Spike
        DoWindow /T Graph_Spike, "Spike " + Num2Str( Number_Current_Spike) + "   (0 - " + Num2Str( Number_Of_Spikes - 1) + ")"
        //Adjust the left axis to appreciate the initial and final points.
        Variable Height
        If ( Data(X_Beginning[Number_Spike]) < Data(X_Final[Number_Spike]))
           Height = Data(X_Peak[Number_Spike]) - Data(X_Beginning[Number_Spike])
           SetAxis /Z Left, Data(X_Beginning[Number_Spike])-0.1*Height, Data(X_Peak[Number_Spike])+0.1*Height
        Else
           Height = Data(X_Peak[Number_Spike]) - Data(X_Final[Number_Spike])
           SetAxis /Z Left, Data(X_Final[Number_Spike])-0.1*Height, Data(X_Peak[Number_Spike])+0.1*Height
        EndIf
        Tag /C /N=Tag_Peak /B=1/A=LC/X=7.87/Y=0.00 Current_Spike, X_Peak[ Number_Spike]
        Tag /C /N=Tag_Begin_Spike /F=0 /B=1/A=RB/X=-8.82/Y=7.66 Current_Spike, X_Beginning[ Number_Spike],"Start"
        Tag /C /N=Tag_Final_Spike /F=0 /B=1/A=LB Current_Spike, X_Final[ Number_Spike], "End"
        If (( Number_Spike > 0 ) %& ( X_Peak[ Number_Spike - 1] > (X_Beginning[ Number_Spike] - 0.05)))
           Tag /C /N=Tag_Final_Back_Spike /F=0 /B=1/A=RB/X=-5.82/Y=7.66 Current_Spike, X_Peak[ Number_Spike-1],"Back"
        Else
           Tag /K /N=Tag_Final_Back_Spike
        EndIf
        If (( Number_Spike < (Number_Of_Spikes - 1)) %& ( X_Peak[ Number_Spike + 1] < (X_Final[ Number_Spike] + 0.2)))
           Tag /C /N=Tag_Beginning_Next_Spike /F=0 /B=1/A=RB /X=5.82/Y=7.66 Current_Spike, X_Peak[ Number_Spike+1],"Next"
        Else
           Tag /K /N=Tag_Beginning_Next_Spike
        EndIf
        TextBox /C /N=text3 /F=0/b=1 "Imax=" + num2str(pA[ Number_Spike])+" pA\r"+"Q=" + num2str(pC[ Number_Spike])+" pC\r t\\B1/2\\M="+num2str(T_Half[ Number_Spike])+" ms\r m="+num2str(M_Half[ Number_Spike])+" nA/s\r t\\Bp\\M="+num2str(T_Peak[ Number_Spike])+" ms\r Tau="+num2str(TauUp[ Number_Spike])+" ms\r Tau'="+num2str(TauDown[ Number_Spike])+" ms"
        Cursor /K A
        Cursor /K B
        If (Exists("Parameters_Painted"))
           Erase_Parameters()
           Show_Parameters()        
        EndIf
   Else
      Current_Spike = 0
      Basal = 0
      DoWindow /F Graph_All_Data
      Tag /K /N=Tag_Spike
      DoWindow /F Graph_Spike
      Tag /K /N=Tag_Peak
      Tag /K /N=Tag_Begin_Spike
      Tag /K /N=Tag_Final_Spike
      Tag /K /N=Tag_Final_Back_Spike
      Tag /K /N=Tag_Beginning_Next_Spike
      TextBox /K /N=Text3
      DoWindow /T Graph_Spike, "No spikes."
   EndIf
End

Function F_Bu_Previous_Spike( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   PauseUpdate; Silent 1
   If ( Number_Of_Spikes)
      If ( Number_Current_Spike > 0)
         Number_Current_Spike -= 1
         Update_Graph_Spike( Number_Current_Spike)
      Else
         DoAlert 0, "This is the first spike."
      EndIf
   Else
      DoAlert 0, "There are no spikes."
   EndIf
End

Function F_Bu_Next_Spike( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   PauseUpdate; Silent 1
   If ( Number_Of_Spikes)
      If ( Number_Current_Spike < ( Number_Of_Spikes - 1)) 
         Number_Current_Spike+=1
         Update_Graph_Spike( Number_Current_Spike)
      Else
         DoAlert 0, "This is the last spike."
      EndIf
   Else
      DoAlert 0, "There are no spikes."
   EndIf
End

// Erase spikes whose maximum is between A and B cursors, which have been put on the wave Data.
Function F_Bu_Remove_Between( CtrlName)
   String CtrlName
   // Locals
   Variable From_Spike, To_Spike, From_X, To_X, No_Spikes = 0
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   PauseUpdate; Silent 1
   If ( NumPnts( X_Peak) > 0)
      If  (  ! (CmpStr("Data", CsrWave(A)))   %&   !(CmpStr("Data", CsrWave(B)))  )
         DoAlert 1, "Are you sure about removing spikes between placed cursors?"
         If ( V_Flag == 1 )
            If ( XCsr( A) > XCsr( B))
               From_X = XCsr(B)
               To_X = XCsr(A)
            Else
               From_X = XCsr(A)
               To_X = XCsr(B)
            EndIf
            If ( From_X > X_Peak( NumPnts( X_Peak) - 1))
               No_Spikes = 1
            Else
               If ( From_X <= X_Peak( 0))
                  From_Spike = 0  // To avoid error with the next findlevel
               Else
                  FindLevel /Q X_Peak, From_X
                  From_Spike = Trunc( V_LevelX) + 1
               EndIf
            EndIf
            If ( To_X < X_Peak( 0))
               No_Spikes = 1
            Else
               If ( To_X >= X_Peak( NumPnts( X_Peak) - 1))
                  To_Spike = NumPnts( X_Peak) -1
               Else
                  FindLevel /Q X_Peak, To_X
                  To_Spike = Trunc( V_LevelX)
               EndIf
            EndIf
            If ( ! No_Spikes )
               DeletePoints From_Spike, (To_Spike - From_Spike + 1), X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, pC_Third, T_Peak, TauUp, TauDown
               Variable /G Making_Spike_View
               Number_Of_Spikes -= (To_Spike - From_Spike + 1)
               If ( Number_Of_Spikes > 0)
                  If ( (Number_Current_Spike >= From_Spike) %& (Number_Current_Spike <= To_Spike) )
                     Number_Current_Spike = From_Spike - 1
                     If ( Number_Current_Spike < 0 )
                        Number_Current_Spike = 0
                     EndIf
                  EndIf
                  DoAlert 0, Num2Str(To_Spike - From_Spike + 1) + " spikes have been removed. It has been left " + Num2Str( Number_Of_Spikes) + " spikes."
               Else
                  DoAlert 0, "It has been left no spikes."
               EndIf
               Update_Graph_Spike( Number_Current_Spike)
               DoWindow /F Graph_Spike
            Else
               DoAlert 0, "There are no spikes between cursors."
            Endif
         EndIf
      Else
         DoAlert 0, "Error! Cursors must be placed on the desired points of wave Data."
      Endif
   Else
      DoAlert 0, "There are no spikes."
   EndIf
End

//It calculates the temporal evolution of charge, considering only spikes or the complete signal.
Function F_Bu_Charge( CtrlName)
   String CtrlName
   // Locals
   Variable Counter = 0, A, B
   // Globals
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave Data = Data
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   PauseUpdate; Silent 1
   If ( Number_Of_Spikes > 0)
      Duplicate /O Data Charge
      Charge = 0
      SetScale d 0,0,"Q", Charge
      Do
         Duplicate /O /R=(X_Beginning(Counter), X_Final(Counter)) Data Spike
         Duplicate /O Spike Basal_Line
         Basal_Line = 0
         A = Data(X_Beginning(Counter)) - X_Beginning(Counter)*(  (Data(X_Final(Counter)) - Data(X_Beginning(Counter))) / ( X_Final(Counter) - X_Beginning(Counter) )  )
         B = (Data(X_Final(Counter)) - Data(X_Beginning(Counter))) / ( X_Final(Counter) - X_Beginning(Counter) )  
         Basal_Line = A + B * x
         Integrate Basal_Line
         Integrate Spike
         Spike -= Basal_Line
         Charge[ X2Pnt(Charge, X_Beginning(Counter)), X2Pnt(Charge, X_Final(Counter))] = Charge(X_Final(Counter-1)) + Spike(x)
         If ( Counter >= (Number_Of_Spikes - 1) ) // This is the last Spike...
            Charge[ X2Pnt(Charge, X_Final(Counter)),  ] = Charge[X2Pnt(Charge,X_Final(Counter))]
         Else
            Charge[ X2Pnt(Charge,X_Final(Counter)), X2Pnt(Charge, X_Beginning(Counter+1)) ] = Charge[X2Pnt(Charge,X_Final(Counter))]
         EndIf
         Counter += 1
      While ( Counter < Number_Of_Spikes)
      KillWaves Spike, Basal_Line
      Duplicate /O Data Data_Without_OffSet
      Variable Segment_Size = 2
      Variable Final = RightX(Data)
      Variable Increment = DeltaX(Data)
      Make /O Histo_Charge
      Counter = 0
      Do
         Duplicate /O /R=(Counter, Counter + Segment_Size - Increment) Data, Period
         WaveStats /Q Period         
         Histogram /B={V_Min, 0.5e-12, 200}  Period, Histo_Charge
         WaveStats /Q Histo_Charge
         Period -= V_MaxLoc
         Data_Without_OffSet[ X2Pnt( Data_Without_OffSet,Counter), X2Pnt( Data_Without_OffSet,Counter + Segment_Size - Increment)] = Period(x)
         Counter += Segment_Size
      While ( Counter < Final )
      KillWaves Period, Histo_Charge
      Duplicate /O Data_Without_OffSet Charge2
      SetScale d 0,0,"Q", Charge2   
      Integrate Charge2
      If ( WinType( "Graph_Charge") == 0)
         Execute "Graph_Charge()"
      EndIf
   Else
      DoAlert 0, "There are no spikes."
   EndIf
End

Window Graph_Charge() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(55.5,71.75,450.75,280.25) Charge,Charge2 as "Temporal evolution of  the charge"
   ModifyGraph rgb(Charge2)=(1,4,52428)
   Button Bu_Close_Graph_Charge,pos={90,7},size={50,20},title="Close"
   Button Bu_Close_Graph_Charge,proc=F_Bu_Close_Graph_Charge
   SetDrawLayer UserFront
   SetDrawEnv fsize= 10,textrgb= (0,0,65280)
   DrawText 0.05,0.2,"Total register"
   SetDrawEnv fsize= 10,textrgb= (65280,0,0)
   DrawText 0.05,0.3,"Only spikes"
EndMacro

Function F_Bu_Close_Graph_Charge( CtrlName)
   String ctrlName
   PauseUpdate; Silent 1   
   DoWindow /K Graph_Charge
End

Window Graph_Spike_Other_Scale() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(580,218,797,592) Current_Spike,Basal as "Update Spike"
	ModifyGraph rgb(Basal)=(1,26214,0)
	ModifyGraph axOffset(left)=-3.57143
EndMacro

Window Graph_Spike() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(6,217,565,593) Current_Spike,Basal as "Spike 35   (0 - 38)"
	ModifyGraph rgb(Basal)=(1,26214,0)
	ModifyGraph axOffset(bottom)=0.416667
	SetAxis left 2.09077373048358e-12,1.23559611018251e-11
	Tag/N=Tag_Peak/B=1/A=LC/X=7.87/Y=0.00 Current_Spike, 32.3807500000000025, ""
	Tag/N=Tag_Begin_Spike/F=0/B=1/A=RB/X=-8.82/Y=7.66 Current_Spike, 32.3574999999999945, "Start"
	Tag/N=Tag_Final_Spike/F=0/B=1/A=LB Current_Spike, 32.5307499999999993, "End"
	Textbox/N=text3/F=0/B=1/X=6.02/Y=-1.52 "Imax=8.4141 pA\rQ=0.32209 pC\r t\\B1/2\\M=26.237 ms\r m=0.71491 nA/s"
	AppendText " t\\Bp\\M=10.237 ms"
	ShowInfo
	ControlBar 27
	Button Bu_Remove_Spike,pos={142,5},size={44,20},proc=F_Bu_Remove_Spike,title="Erase"
	Button Bu_Remove_Spike,help={"Delete spike.   "}
	Button Bu_Modify_Spike,pos={88,5},size={49,20},proc=F_Bu_Modify_Spike,title="Modify"
	Button Bu_Modify_Spike,help={"Modify the beginning and final of this spike.  Drag cursors at the desired points. "}
	Button Bu_Add_Spike,pos={48,5},size={35,20},proc=F_Bu_Add_Spike,title="Add"
	Button Bu_Add_Spike,help={"Add a new spike to table. Place cursors at the desired points. "}
	Button Bu_Previous_Spike,pos={246,5},size={35,20},proc=F_Bu_Previous_Spike,title="<<"
	Button Bu_Previous_Spike,help={"Previous spike."}
	Button Bu_Next_Spike,pos={284,5},size={35,20},proc=F_Bu_Next_Spike,title=">>"
	Button Bu_Next_Spike,help={"Next spike"}
	Button Bu_Dots_Line,pos={7,5},size={35,20},proc=F_Bu_Dots_Line,title="Dots"
	Button Bu_Dots_Line,help={"Modify graph to dots/line mode"}
	Button Bu_Go_Spike,pos={325,5},size={18,20},proc=F_Bu_Go_Spike,title=">"
	Button Bu_Go_Spike,help={"Show the spike with the number selected."}
	SetVariable Set_Go_Spike,pos={346,7},size={49,16},title=" "
	SetVariable Set_Go_Spike,help={"Choose the number of spike you wish to show."}
	SetVariable Set_Go_Spike,font="Arial",limits={0,Inf,1},value= Spike_To_Go
	Button Bu_Back_Start,pos={183,29},size={23,18},proc=F_Bu_Back_Start,title="< S"
	Button Bu_Back_Start,help={"Move start point backward, by 5 points each time."}
	Button Bu_Next_Start,pos={210,29},size={23,18},proc=F_Bu_Next_Start,title="S >"
	Button Bu_Next_Start,help={"Move start point forward, by 5 points each time."}
	Button Bu_Back_End,pos={242,29},size={23,18},proc=F_Bu_Back_End,title="< E"
	Button Bu_Back_End,help={"Move end point backward, by 5 points each time."}
	Button Bu_Next_End,pos={269,29},size={23,18},proc=F_Bu_Next_End,title="E >"
	Button Bu_Next_End,help={"Move end point forward, by 5 points each time."}
	Button Bu_Paint_Parameters,pos={191,5},size={50,20},proc=F_Bu_Paint_Parameters,title="Param."
	Button Bu_Paint_Parameters,help={"Adds to graph the parameters of displayed spike."}
	Button Bu_Undo_Last_Erased_Spike,pos={400,5},size={32,20},title="LES",proc=F_Bu_Undo_Last_Erased_Spike
	Button Bu_Undo_Last_Erased_Spike,help={"Restore the last erased spike."}
	SetWindow Graph_Spike, hook=F_Graph_Spike, hookevents=1
EndMacro

//It allows to modify beginning or final spike clicking on the trace, without dragging
//the Cursor, so the modification is much quicker.
Function F_Graph_Spike(InfoStr)
   String InfoStr
   Variable PosX, PosY
   PauseUpdate; Silent 1
   If (CmpStr(StringByKey("EVENT", InfoStr), "mousedown") == 0)
      Variable /G ClickDown  //This variable is created to know if mouse button
                                        //has clicked down before mouse button is up into the same window.
   Else
      If (CmpStr(StringByKey("EVENT", InfoStr), "mouseup") == 0)
         If (Exists("ClickDown")) //If this variable exists, mouse has clicked down before up in the same window.
            NVar ClickDown = ClickDown
            KillVariables /Z ClickDown
            PosX = Str2Num(StringByKey("MOUSEX", InfoStr))
            PosY = Str2Num(StringByKey("MOUSEY", InfoStr))
            String TraceClicked = TraceFromPixel(PosX,PosY,"ONLY:Current_Spike")
            If (CmpStr(StringByKey("TRACE",TraceClicked),"Current_Spike") == 0)
               Variable PointClicked = Str2Num(StringByKey("HITPOINT", TraceClicked))
               Cursor /P A, Current_Spike, PointClicked
               F_Bu_Modify_Spike("")
            EndIf
         EndIf
      EndIf
   EndIf
   return(1)
End

Function F_Bu_Undo_Last_Erased_Spike(CtrlName)
   String CtrlName
   Variable N_Erased_Spike
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave X_Beginning = X_Beginning
   Wave X_Peak = X_Peak
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   Wave M_Half = M_Half
   PauseUpdate; Silent 1
   If (Exists("Data_Erased_Spike"))
      Wave Data_Erased_Spike = Data_Erased_Spike
      N_Erased_Spike = Data_Erased_Spike[0]
      InsertPoints N_Erased_Spike, 1, X_Beginning, X_Peak, X_Final, pA, pC, pC_Third, T_Half, T_Peak, TauUp, TauDown, M_Half
      X_Beginning[N_Erased_Spike] = Data_Erased_Spike[1]
      X_Peak[N_Erased_Spike] = Data_Erased_Spike[2]
      X_Final[N_Erased_Spike] = Data_Erased_Spike[3]
      pA[N_Erased_Spike] = Data_Erased_Spike[4]
      pC[N_Erased_Spike] = Data_Erased_Spike[5]
      pC_Third[N_Erased_Spike] = Data_Erased_Spike[6]
      T_Half[N_Erased_Spike] = Data_Erased_Spike[7]
      T_Peak[N_Erased_Spike] = Data_Erased_Spike[8]
      TauUp[N_Erased_Spike] = Data_Erased_Spike[10]
      TauDown[N_Erased_Spike] = Data_Erased_Spike[11]
      M_Half[N_Erased_Spike] = Data_Erased_Spike[9]
      KillWaves /Z Data_Erased_Spike
      Number_Current_Spike = N_Erased_Spike
      Number_Of_Spikes += 1
      Update_Graph_Spike( Number_Current_Spike)
   Else
      DoAlert 0, "Last erased spike has already been restored or no spike has been erased..."
   EndIf
End

Function F_Bu_Paint_Parameters(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   If (Exists("Parameters_Painted"))
      KillVariables Parameters_Painted
      Erase_Parameters()
   Else
      Variable /G Parameters_Painted
      Show_Parameters()
   EndIf
End

//It eliminates the displayed parameters in Graph_Spike.
Function Erase_Parameters()
   // Globals
   NVar NS = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Beginning = X_Beginning
   Wave X_Peak = X_Peak
   Wave X_Final = X_Final
   Wave pA = pA
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   PauseUpdate; Silent 1
   Tag /K /N=Tag_Imax
   RemoveFromGraph /Z Parameter_T_Half
   KillWaves /Z Parameter_T_Half
   RemoveFromGraph /Z Parameter_M
   KillWaves /Z Parameter_M
   RemoveFromGraph /Z Parameter_T_Peak
   KillWaves /Z Parameter_T_Peak
   RemoveFromGraph /Z Parameter_TauU
   KillWaves /Z Parameter_TauU
   RemoveFromGraph /Z Parameter_TauD
   KillWaves /Z Parameter_TauD
End

//It shows the spike parameters in Graph_Spike.
Function Show_Parameters()
   // Globals
   NVar NS = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Beginning = X_Beginning
   Wave X_Peak = X_Peak
   Wave X_Final = X_Final
   Wave pA = pA
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   //Locals
   Variable From_X_0, To_X_0, From_X_1, To_X_1, From_X, To_X
   PauseUpdate; Silent 1
   //The following Tag needs the height of the spike as a % of left axis in parameter /Y. GetAxis informs about
   //maximum and minimum values of axis (V_Max - V_Min will be the 100%). Into this 100%, pA[NS] will
   //be the % of the tag (to put in /Y parameter).
   DoWindow /F Graph_Spike
   GetAxis /Q Left
   //Show Imax parameter.
   Tag /N=Tag_Imax /F=0 /I=1 /L=1 /P=1 /X=0 /Y=(-100*pA[NS]/((V_Max-V_Min)*1e12)) Current_Spike, X_Peak[NS]
   //Show T1/2 parameter.
   Make /O /N=2 Parameter_T_Half
   Parameter_T_Half[0] = (Current_Spike(X_Peak[NS]) - Current_Spike(X_Beginning[NS])) / 2   +  Current_Spike(X_Beginning[NS])
   Parameter_T_Half[1] = (Current_Spike(X_Peak[NS]) - Current_Spike(X_Final[NS])) / 2   +  Current_Spike(X_Final[NS])
   From_X_0 = Finding_Level_Backwards( Current_Spike, Parameter_T_Half[0], X_Peak[NS])
   To_X_0 = Finding_Level_Towards( Current_Spike, Parameter_T_Half[1], X_Peak[NS])   
   From_X_1 = Pnt2X(Current_Spike, X2Pnt(Current_Spike, From_X_0) + 1)
   To_X_1 = Pnt2X( Current_Spike, X2Pnt( Current_Spike, To_X_0) - 1)
   From_X = ( From_X_1 - From_X_0) / ( Current_Spike( From_X_1) - Current_Spike( From_X_0)) * ( Parameter_T_Half[0] - Current_Spike( From_X_0)) + From_X_0
   To_X = ( To_X_1 - To_X_0) / ( Current_Spike( To_X_1) - Current_Spike( To_X_0)) * ( Parameter_T_Half[1] - Current_Spike( To_X_0)) + To_X_0
   SetScale/I x  From_X, To_X,"", Parameter_T_Half
   AppendToGraph Parameter_T_Half
   ModifyGraph rgb(Parameter_T_Half)=(1,4,52428), lsize(Parameter_T_Half)=2   
   //Show M parameter.
   Show_M_Half(Current_Spike, X_Peak[NS], X_Beginning[NS])
   //Show T_Peak parameter.
   Show_T_Peak(Current_Spike(X_Beginning[NS]), X_Peak[NS], T_Peak[NS], M_Half[NS])
   //Show Tau and Tau' parameters.
   Show_Tau(X_Peak[NS], Current_Spike(X_Peak[NS]), pA[NS], TauUp[NS], TauDown[NS])
End

//It shows the Tau and Tau' parameters.
Function Show_Tau(Peak_Time, Peak_Data, IMax, TauU, TauD)
   Variable Peak_Time, Peak_Data, IMax, TauU, TauD
   PauseUpdate; Silent 1
   IMax *= 1e-12
   If (TauU > 0)
      TauU *= 1e-3
      Make /O /N=2 Parameter_TauU
      SetScale/I x Peak_Time, Peak_Time+ TauU,"", Parameter_TauU
      Parameter_TauU = Peak_Data - IMax*1/e
      AppendToGraph Parameter_TauU
      ModifyGraph rgb(Parameter_TauU)=(20000,50000,20000), lsize(Parameter_TauU)=2 
   EndIf
   If (TauD > 0)
      TauD *= 1e-3
      Make /O /N=2 Parameter_TauD
      SetScale/I x Peak_Time, Peak_Time+ TauD,"", Parameter_TauD
      Parameter_TauD = Peak_Data - IMax*(1 - 1/e)
      AppendToGraph Parameter_TauD
      ModifyGraph rgb(Parameter_TauD)=(20000,50000,20000), lsize(Parameter_TauD)=2    
   EndIf
End

//It shows the T_Peak parameter.
Function Show_T_Peak(Beginning_Amplitude, Peak_Time, Time_To_Peak, M_Parameter)
   Variable Beginning_Amplitude, Peak_Time, Time_To_Peak, M_Parameter
   PauseUpdate; Silent 1
   If (M_Parameter != 0)
      Make /O /N=2 Parameter_T_Peak
      SetScale/I x (Peak_Time - Time_To_Peak/1e3), Peak_Time,"", Parameter_T_Peak
      Parameter_T_Peak = Beginning_Amplitude
      AppendToGraph Parameter_T_Peak
      ModifyGraph rgb(Parameter_T_Peak)=(1,4,52428), lsize(Parameter_T_Peak)=2   
   Else
      Print "Error in T_Peak..."
   EndIf
End

//It shows the m parameter in Graph_Spike.
Function Show_M_Half(Spike, Peak_Time, Beginning_Time)
   Wave Spike
   Variable Peak_Time, Beginning_Time
   // Locals
   Variable x0, x1
   PauseUpdate; Silent 1
   // For avoiding error with the findlevel, we can use this sentence if...
   If ( Beginning_Time < (Peak_Time - DeltaX(Spike) ) )
      FindLevel /Q /R=(Beginning_Time, Peak_Time) Spike, Spike(Beginning_Time)+3*(Spike(Peak_Time)-Spike(Beginning_Time))/4
      x1 = V_LevelX
      FindLevel /Q /R=(Beginning_Time, Peak_Time) Spike, Spike(Beginning_Time)+(Spike(Peak_Time)-Spike(Beginning_Time))/4
      x0 = V_LevelX
      If ( X2Pnt(Spike,x0) < X2Pnt(Spike,x1)) //For avoiding error in Curvefit: insufficient range...
         Duplicate /O Spike Parameter_M
         CurveFit /Q Line Spike(x0,x1) /D=Parameter_M
         SetScale/I x Beginning_Time,Peak_Time,"", Parameter_M
         Wave W_Coef = W_Coef
         Parameter_M = W_Coef[0] + x*W_Coef[1]
         AppendTograph Parameter_M
         ModifyGraph rgb(Parameter_M)=(1,4,52428), lsize(Parameter_M)=2
         KillWaves /Z W_Coef
      Else
         Print "Error in M parameter..."
      EndIf
   Else
         Print "Error in M parameter..."
   EndIf
End

Function F_Bu_Back_Start( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Beginning = X_Beginning
   PauseUpdate; Silent 1
   Cursor /K A
   Cursor /K B
   Cursor A, Current_Spike, (X_Beginning[Number_Current_Spike] - (5* DeltaX(Current_Spike)))
   F_Bu_Modify_Spike(" ")
End

Function F_Bu_Next_Start( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Beginning = X_Beginning
   PauseUpdate; Silent 1
   Cursor /K A
   Cursor /K B
   Cursor A, Current_Spike, (X_Beginning[Number_Current_Spike] + (5* DeltaX(Current_Spike)))
   F_Bu_Modify_Spike(" ")
End

Function F_Bu_Back_End( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Final = X_Final
   PauseUpdate; Silent 1
   Cursor /K A
   Cursor /K B
   Cursor B, Current_Spike, (X_Final[Number_Current_Spike] - (20* DeltaX(Current_Spike)))
   F_Bu_Modify_Spike(" ")
End

Function F_Bu_Next_End( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   Wave Current_Spike = Current_Spike
   Wave X_Final = X_Final
   PauseUpdate; Silent 1
   Cursor /K A
   Cursor /K B
   Cursor B, Current_Spike, (X_Final[Number_Current_Spike] + (20* DeltaX(Current_Spike)))
   F_Bu_Modify_Spike(" ")
End

Function F_Bu_Go_Spike( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Of_Spikes = Number_Of_Spikes
   NVar Spike_To_Go = Spike_To_Go
   PauseUpdate; Silent 1
   If (( Spike_To_Go >= 0) %& ( Spike_To_Go < Number_Of_Spikes))
      Update_Graph_Spike( Spike_To_Go)
   Else
      DoAlert 0, "The number selected must be between 0 and " + Num2Str( Number_Of_Spikes - 1) + "."
   EndIf
End

Function F_Bu_Remove_Spike( CtrlName)
   String CtrlName
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave X_Peak = X_Peak
   Wave Current_Spike = Current_Spike
   Wave Basal = Basal
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   PauseUpdate; Silent 1   
   If (( Number_Current_Spike >= 0) %& ( Number_Current_Spike < Number_Of_Spikes))
      Make /O /N=12 Data_Erased_Spike
      Data_Erased_Spike[0] = Number_Current_Spike
      Data_Erased_Spike[1] = X_Beginning[Number_Current_Spike]
      Data_Erased_Spike[2] = X_Peak[Number_Current_Spike]
      Data_Erased_Spike[3] = X_Final[Number_Current_Spike]
      Data_Erased_Spike[4] = pA[Number_Current_Spike]
      Data_Erased_Spike[5] = pC[Number_Current_Spike]
      Data_Erased_Spike[6] = pC_Third[Number_Current_Spike]
      Data_Erased_Spike[7] = T_Half[Number_Current_Spike]
      Data_Erased_Spike[8] = T_Peak[Number_Current_Spike]
      Data_Erased_Spike[9] = M_Half[Number_Current_Spike]
      Data_Erased_Spike[10] = TauUp[Number_Current_Spike]
      Data_Erased_Spike[11] = TauDown[Number_Current_Spike]
      DeletePoints Number_Current_Spike,1, X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, pC_Third, T_Peak, TauUp, TauDown
      Variable /G Making_Spike_View
      Number_Of_Spikes -= 1
      If ( Number_Of_Spikes)
         If ( Number_Current_Spike == Number_Of_Spikes)
            Number_Current_Spike -= 1
         EndIf
      EndIf
      Update_Graph_Spike( Number_Current_Spike)
   Else
      DoAlert 0, "There are no spikes."
   EndIf
End

Function F_Bu_Dots_Line( CtrlName)
   String CtrlName
   // Globals
   NVar Dots = Dots
   PauseUpdate; Silent 1
   If ( ! Dots)  // If graph has format of line...
      ModifyGraph mode(Current_Spike)=2
      ModifyGraph lSize(Current_Spike)=1.5
      Button Bu_Dots_Line, title="Line"
      Dots = 1
   Else
      ModifyGraph lSize(Current_Spike)=1
      ModifyGraph mode(Current_Spike)=0
      Button Bu_Dots_Line, title="Dots"
      Dots = 0
   Endif
End

Window Graph_All_Data() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(216,42,792,191) DATA as "Exp12"
	Tag /B=(5,5,56000) /N=Tag_Spike DATA, 0, ""
	ShowInfo
	Button Bu_Add_Spike_Global,pos={77,4},size={55,20},proc=F_Bu_Add_Spike,title="Add"
	Button Bu_Add_Spike_Global,help={"Add a new spike to table. Place cursors at the desired points. "}
	Button Bu_Remove_Between_Cursors,pos={157,4},size={60,20},proc=F_Bu_Remove_Between,title="A-Kill-B"
	Button Bu_Remove_Between_Cursors,help={"Delete spikes between cursors. Place cursors at the desired points. "}
EndMacro

Function F_Bu_Histogram( CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   Make /N=0 /O Histo_T_Half, Histo_pA, Histo_pC
   Histogram /B={0,2.5,28} T_Half, Histo_T_Half
   Histogram /B={0,5,40} pA, Histo_pA
   Histogram /B={0,0.1,40} pC, Histo_pC
   If ( WinType( "Graph_Histo_T_Half") == 0)
      Execute "Graph_Histo_T_Half()"
   Endif
   If ( WinType( "Graph_Histo_Imax") == 0)
      Execute "Graph_Histo_Imax()"
   Endif
   If ( WinType( "Graph_Histo_Charge") == 0)
      Execute "Graph_Histo_Charge()"
   Endif
   Execute "TileWindows /W=(4,20,296,512) Graph_Histo_T_Half,Graph_Histo_Imax,Graph_Histo_Charge"
   Make_Layout_Histograms()
EndMacro

Window Graph_Histo_Charge() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(3.75,310.25,296.25,422) Histo_pC as "Histogram Charge (pC)"
   ModifyGraph mode=5
   ModifyGraph hbFill=3
   TextBox/N=text0/F=1 "Charge"
   Button Bu_Close_Histo_Charge,pos={9,111},size={36,20},title="Close",proc=F_Bu_Close_Histo_Charge
EndMacro

Function F_Bu_Close_Histo_Charge(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Graph_Histo_Charge
End

Window Graph_Histo_Imax() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(3.75,173.75,296.25,285.5) Histo_pA as "Histogram Imax (pA)"
   ModifyGraph mode=5
   ModifyGraph hbFill=3
   TextBox/N=text0/F=1 "Imax"
   Button Bu_Close_Histo_Imax,pos={10,111},size={36,20},title="Close",proc=F_Bu_Close_Histo_Imax
EndMacro

Function F_Bu_Close_Histo_Imax(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Graph_Histo_Imax
End

Window Graph_Histo_T_Half() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(4,39,296,178) Histo_T_Half as "Histogram T. Half (s)"
   ModifyGraph mode=5
   ModifyGraph hbFill=3
   TextBox/N=text0/F=1 "T. Half"
   Button Bu_Close_Histo_T_Half,pos={9,108},size={37,20},proc=F_Bu_Close_Histo_T_Half,title="Close"
   Button Bu_Close_All_Histo,pos={106,3},size={55,19},proc=F_Bu_Close_All_Histo,title="Close All"
   Button Bu_Close_All_Histo,help={"Close 4 windows: the three histograms and the layout."}
EndMacro

Function F_Bu_Close_Histo_T_Half(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Graph_Histo_T_Half
End

Function F_Bu_Close_All_Histo(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Graph_Histo_T_Half
   DoWindow /K Graph_Histo_Imax
   DoWindow /K Graph_Histo_Charge
   DoWindow /K Layout_Histograms
End

Function Make_Layout_Histograms()
   PauseUpdate; Silent 1
   If ( WinType("Layout_Histograms") == 0)
      Execute "Layout_Histograms()"
   EndIf
End

Window Layout_Histograms() : Layout
   PauseUpdate; Silent 1      // building window...
   Layout/C=1/W=(149.25,113.75,505.5,345.5) Graph_Histo_Charge(72.75,72.75,204.75,293.25)/O=1 as "Histograms"
   Append Graph_Histo_Imax(212.25,72.75,344.25,293.25)/O=1,Graph_Histo_T_Half(351.75,72.75,483.75,293.25)/O=1
   TextBox/N=text0/A=LB/X=11.31/Y=44.68 "Press over {A} and  put on here TEXT "
EndMacro

Function F_Check_Noise_Data( CtrlName, Checked)
   String CtrlName
   Variable Checked
   // Globals
   Wave Noise_Data = Noise_Data
   PauseUpdate; Silent 1
   If ( WinType( "Noise_Data_Panel") == 0)
      Execute "Noise_Data_Panel()"
      DoWindow /T Noise_Data_Panel "Statistic of noise"
      If ( WinType( "Graph_All_Data") != 0)
         DoWindow /F Graph_All_Data
           Tag /C /N=Start_Noise_Tag /F=0 /B=1/A=RB/X=-2.82/Y=33.66 Data, Noise_Data[0],"Start of noise"
           Tag /C /N=End_Noise_Tag /F=0 /B=1/A=LB/X=2.82/Y=33.66 Data, Noise_Data[1], "End of noise"
        EndIf
      DoWindow /F Main_Panel_Check
      CheckBox Check_Noise_Data, value = 1
   Else
      DoWindow /K Noise_Data_Panel
      DoWindow /F Graph_All_Data
      Tag /K /N=Start_Noise_Tag
      Tag /K /N=End_Noise_Tag
      DoWindow /F Main_Panel_Check
      CheckBox Check_Noise_Data, value = 0
   EndIf
End

Window Noise_Data_Panel() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(9,222,312,338) as "Statistic of noise"
   ModifyPanel cbRGB=(52224,52224,52224)
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect -3,-3,305,118
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 210,65,267,93
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 7,17,"St.dev.of noise (pA):"
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 138,17,"St.dev.of noise slope (pA^2):"
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 7,61,"Period of noise:"
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 43,81,"Start:"
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 49,105,"End:"
   ValDisplay Start_noise,pos={78,63},size={85,16},font="Arial",format="%g s"
   ValDisplay Start_noise,limits={0,0,0},barmisc={0,1000},value= #"Noise_Data(0)"
   ValDisplay End_noise,pos={78,87},size={86,16},font="Arial",format="%g s"
   ValDisplay End_noise,limits={0,0,0},barmisc={0,1000},value= #"Noise_Data(1)"
   ValDisplay valdisp0,pos={7,19},size={101,16},font="Arial"
   ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"Noise_Data(2)*1e12"
   ValDisplay valdisp1,pos={139,19},size={123,16},font="Arial"
   ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"Noise_Data(3)*1e24"
   Button Bu_Close_Noise,pos={217,70},size={43,20},proc=F_Bu_Close_Noise,title="Close"
   Button Bu_Close_Noise,help={"Click here for closing the noise information panel."}
EndMacro

Function F_Bu_Close_Noise(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   Dowindow /K Noise_Data_Panel
   DoWindow /F Graph_All_Data
   Tag /K /N=Start_Noise_Tag
   Tag /K /N=End_Noise_Tag
   DoWindow /F Main_Panel_Check
   CheckBox Check_Noise_Data, value=0
End

Window Load_Panel() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(13,101,522,189) as "Selecting experiment..."
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect -2,-2,538,115
   SetDrawEnv fstyle= 1
   SetDrawEnv save
   SetDrawEnv fname= "Arial"
   DrawText 8,19,"EXPERIMENT FOLDER:"
   SetDrawEnv fname= "Arial"
   DrawText 8,59,"EXPERIMENT NAME:"
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 143,51,200,79
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 220,51,277,79
   SetVariable Set_Exp_Folder,pos={6,20},size={472,16},proc=FSetExpFolder,title=" "
   SetVariable Set_Exp_Folder,help={"Type here the full path of the folder where experiment waves are: Data, X_Peak, X_Beginning, X_Final, etc."}
   SetVariable Set_Exp_Folder,font="Arial",limits={-Inf,Inf,0},value= Exp_Folder
   SetVariable Set_Exp_Name,pos={6,60},size={112,16},title=" "
   SetVariable Set_Exp_Name,help={"Type here the name of the experiment, the same name of original Data before analysing."}
   SetVariable Set_Exp_Name,font="Arial",limits={-Inf,Inf,0},value= Exp_Name
   Button Bu_Load_Exp,pos={150,56},size={45,20},proc=F_Bu_Load_Waves_Exp,title="Load"
   Button Bu_Load_Exp,help={"Load experiment Data, which has been analysed previously, and now you will be able to correct manually posible errors."}
   Button Bu_Cancel_Load,pos={227,56},size={45,20},proc=F_Bu_Cancel_Load,title="Cancel"
   Button Bu_ChooseExpFolder,pos={482,20},size={20,15},proc=FBuChooseExpFolder,title="<>"
EndMacro

//Function associates to Set_Exp_Folder of Load_Panel in Spike View.
//It is used to update Exp_Name with last characters of Exp_Folder for avoiding to type Exp_Name.
Function FSetExpFolder(CtrlName,varNum,Folder,varName) : SetVariableControl
   String CtrlName 
   Variable varNum   // value of variable as number
   String Folder   // value of variable as string
   String varName   // name of variable
   Variable Counter
   SVar Exp_Name = Exp_Name
   PauseUpdate; Silent 1
   Counter = StrLen(Folder)
   If (Counter > 0)
      If (CmpStr(Folder[Counter-1], ":") == 0)
         Counter -= 1  //To avoid the last semicolon.
      EndIf
      Do
         Counter -= 1
      While ((Counter > 0) %& (CmpStr(Folder[Counter], "_"))  %& (CmpStr(Folder[Counter], ":")) )
      If ((CmpStr(Folder[Counter], "_") == 0) %| (CmpStr(Folder[Counter], ":") == 0))
         Exp_Name = Folder[Counter+1, StrLen(Folder)-1]
      EndIf
      If (CmpStr(Exp_Name[StrLen(Exp_Name)-1], ":") == 0)
         Exp_Name = Exp_Name[0, StrLen(Exp_Name)-2]  //To remove the last semicolon.
      EndIf
   EndIf   
End

//This function must be called by button <> associated to Exp. Folder.
Function FBuChooseExpFolder(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   If (WinType("ChoosePanel") == 0)
      String /G VariableName = "Exp_Folder"
      String /G ProcName = "FSetExpFolder" //It is used in FBuOKFolder to execute the proc associated to setvariable.
      ChooseFolder(VariableName)
   Else
      DoWindow /F ChoosePanel
   EndIf
End

Function Kill_Windows_Check()
   PauseUpdate; Silent 1
   DoWindow /K Main_Panel_Check
   DoWindow /K Load_Panel
   DoWindow /K Save_Panel
   DoWindow /K Graph_All_Data
   DoWindow /K Graph_Spike
   DoWindow /K Graph_Spike_Other_Scale
   DoWindow /K Graph_Charge
   DoWindow /K Noise_Data_Panel
   DoWindow /K Graph_Histo_T_Half
   DoWindow /K Graph_Histo_Imax
   DoWindow /K Graph_Histo_Charge
   DoWindow /K Layout_Histograms
   DoWindow /K ChoosePanel
End

Function F_Bu_Add_Spike( CtrlName)
   String CtrlName
   // Locals
   Variable Peak_Time
   // Globals
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave Data = Data
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   PauseUpdate;Silent 1
   If ( ! CmpStr( CsrWave( A), "Current_Spike") %| ! CmpStr( CsrWave(A), "Data"))
      If ( ! CmpStr( CsrWave( A), CsrWave ( B)))
         WaveStats /Q /R=( XCsr(A), XCsr(B)) Data
         Peak_Time = V_MaxLoc
         Variable /G Order_Spike   // In this variable, the function Spike_Already_Exists saves the position of the spike in X_Peak.
         If ( Number_Of_Spikes)
            If ( Spike_Already_Exists( Peak_Time))
               DoAlert 1, "Spike already added. Do you wish to modify beginning and final of spike?"
               If ( V_Flag == 1)
                  X_Peak[ Order_Spike] = Peak_Time
                  Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
                  Calculate_Parameters_Spike( Order_Spike)
                  Variable /G Making_Spike_View
                  Update_Graph_Spike( Order_Spike)
               EndIf
            Else
               InsertPoints Order_Spike,1, X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, T_Peak, pC_Third, TauUp, TauDown
               Number_Of_Spikes += 1
               X_Peak[ Order_Spike] = Peak_Time
               Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
               Calculate_Parameters_Spike( Order_Spike)
               Variable /G Making_Spike_View
               Update_Graph_Spike( Order_Spike)
            EndIf
         Else
            Order_Spike = 0
            InsertPoints Order_Spike,1, X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, T_Peak, pC_Third, TauUp, TauDown
            Number_Of_Spikes = 1
            X_Peak[ Order_Spike] = Peak_Time
            Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
            Calculate_Parameters_Spike( Order_Spike)
            Variable /G Making_Spike_View
            Update_Graph_Spike( Order_Spike)
         EndIf
         KillVariables /Z Order_Spike
      Else
         DoAlert 0, "B cursor is not over right wave."
      EndIf
   Else
      DoAlert 0, "A cursor is not over right wave."
   EndIf
End         

Function F_Bu_Modify_Spike( CtrlName)
   String CtrlName
   // Locals
   Variable Peak_Time
   // Globals
   NVar Number_Current_Spike = Number_Current_Spike
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave Data = Data
   Wave X_Peak = X_Peak
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   Wave pA = pA
   Wave pC = pC
   Wave pC_Third = pC_Third
   Wave T_Half = T_Half
   Wave M_Half = M_Half
   Wave T_Peak = T_Peak
   Wave TauUp = TauUp
   Wave TauDown = TauDown
   PauseUpdate;Silent 1
      // If it is placed only one cursor (A or B), it is suppossed that the other cursor will be placed on the
      // beginning or final of current spike, depending on the time of the placed cursor.
   If ( ! CmpStr( CsrWave( A), "Current_Spike") %& CmpStr( CsrWave( B), "Current_Spike"))  // If cursor A is placed but not cursor B...
      If ( XCsr(A) > X_Peak( Number_Current_Spike))
         Cursor B, Current_Spike, X_Beginning( Number_Current_Spike)
      Else
         Cursor B, Current_Spike, X_Final( Number_Current_Spike)
      EndIf
   Else
      If ( CmpStr( CsrWave( A), "Current_Spike") %& ! CmpStr( CsrWave( B), "Current_Spike"))  // If cursor B is placed but not cursor A...
         If ( XCsr(B) > X_Peak( Number_Current_Spike))
            Cursor A, Current_Spike, X_Beginning( Number_Current_Spike)
         Else
            Cursor A, Current_Spike, X_Final( Number_Current_Spike)
         EndIf
      EndIf
   EndIf
   If ( ! CmpStr( CsrWave( A), "Current_Spike") %&  ! CmpStr( CsrWave( B), "Current_Spike"))  // If both cursor A and B are placed...
      WaveStats /Q /R=( XCsr(A), XCsr(B)) Data
      Peak_Time = V_MaxLoc
      Variable /G Order_Spike   // In this variable, the function Spike_Already_Exists saves the position of the spike in X_Peak.
      If ( Number_Of_Spikes)
         If ( Spike_Already_Exists( Peak_Time))
            X_Peak[ Order_Spike] = Peak_Time
            Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
            Calculate_Parameters_Spike( Order_Spike)
            Variable /G Making_Spike_View
            Update_Graph_Spike( Order_Spike)
         Else
            DoAlert 1, "That spike is new. Do you wish to create it?"
            If ( V_Flag == 1)
               InsertPoints Order_Spike,1, X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, T_Peak, pC_Third, TauUp, TauDown
               Number_Of_Spikes += 1
               X_Peak[ Order_Spike] = Peak_Time
               Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
               Calculate_Parameters_Spike( Order_Spike)
               Variable /G Making_Spike_View
               Update_Graph_Spike( Order_Spike)
            EndIf
         EndIf
      Else
         DoAlert 1, "That spike is new. Do you wish to create it?"
         If ( V_Flag == 1)
            Order_Spike = 0
            InsertPoints Order_Spike,1, X_Peak, X_Beginning, X_Final, pA, pC, T_Half, M_Half, T_Peak, pC_Third, TauUp, TauDown
            Number_Of_Spikes = 1
            X_Peak[ Order_Spike] = Peak_Time
            Set_Begin_Final( XCsr(A), XCsr(B), Order_Spike)
            Calculate_Parameters_Spike( Order_Spike)
            Variable /G Making_Spike_View
            Update_Graph_Spike( Order_Spike)
         EndIf
      EndIf
      KillVariables /Z Order_Spike
   Else
      DoAlert 0, "Cursor A and/or B must be placed on desired points for new beginning and final of spike."
   EndIf
End

Function Spike_Already_Exists( Peak_Time)
   Variable Peak_Time
   // Locals
   Variable N_Order  // For saving the number of order of the spike in X_Peak.
   Variable Total, Peak_Point
   Variable Already_Exists = 0
   // Globals
   NVar Order_Spike = Order_Spike
   Wave X_Peak = X_Peak
   Wave Data = Data
   PauseUpdate; Silent 1

   Peak_Point = X2Pnt(Data, Peak_Time)
   N_Order = -1
   Total = NumPnts(X_Peak)
   If (Total > 0)
      Do
         N_Order += 1
      While ((N_Order < Total) %& (Peak_Point > X2Pnt(Data, X_Peak[N_Order])))
      If (Peak_Point == X2Pnt(Data, X_Peak[N_Order]))
         Already_Exists = 1  //N_Order saves the correct value, exists or not exists the spike.
      EndIf
   Else
      N_Order = 0
   EndIf
   Order_Spike = N_Order
   Return( Already_Exists)
End

// It puts the beginning of the spike N_Order in the smaller value of Cursor_A and Cursor_B and the final
// of that spike in the higher value of those cursors.
Function Set_Begin_Final( Cursor_A, Cursor_B, N_Order)
   Variable Cursor_A, Cursor_B, N_Order
   // Globals
   Wave Data = Data
   NVar Number_Of_Spikes = Number_Of_Spikes
   Wave X_Beginning = X_Beginning
   Wave X_Final = X_Final
   PauseUpdate; Silent 1
   If ( Cursor_A > Cursor_B)
      X_Beginning[ N_Order] = Cursor_B
      X_Final[N_Order] = Cursor_A
   Else
      X_Beginning[ N_Order] = Cursor_A
      X_Final[N_Order] = Cursor_B
   EndIf
End

////////////////////////////////////////////////////////////////////////////////////////////////
///////  THIRD PART:  MAKE GALLERIES FROM EXPERIMENTS
////////////////////////////////////////////////////////////////////////////////////////////////
Function Galleries()
   // Locals
   Variable Go_To_Save = 0
   PauseUpdate; Silent 1
   If ( Exists( "Making_Spike_View"))
      DoAlert 2, "Not all result files are saved, save them now?"
      If ( V_Flag == 1)
         Go_To_Save = 1
         F_Bu_Show_Save_Panel(" ")
      Else
         If (V_Flag == 3)
            Go_To_Save = 1
         EndIf
      EndIf
   EndIf
   If ( ! Go_To_Save)
      KillVariables /Z Making_Spike_View
      Kill_Windows_Analyse()   // If windows are already shown, they are killed.
      Kill_Windows_Check()   // If windows of check option are shown, they are killed.
      V_Flag = 1
      If ( Exists( "Gallery_In_Process"))
         DoAlert 1, "Starting new gallery. The current gallery will be overwritten.\rContinue?"
      EndIf
      If ( V_Flag == 1)
         KillVariables /Z Gallery_In_Process
         Kill_Windows_Gallery()   // If windows of Gallery option are shown, they are killed.
         Print "-------- BEGIN NEW GALLERY --------"
         // Creating global objects.
         Creating_Objects_Gallery()
         Execute "Gallery_Load_Panel()"
      Else
         If ( WinType("Gallery_Main_Panel") == 0)
            Execute "Gallery_Main_Panel()"
         EndIf
      EndIf
   EndIf
End

Function Creating_Objects_Gallery()
   PauseUpdate; Silent 1
   // Kill all objetcts used in others options of Macros menu.
   // KillVariables /A /Z
   // KillStrings /A /Z
   KillWaves /A /Z
   Variable /G Number_Of_Spikes
   Variable /G Check_Waves_Exp
   Variable /G NCell
   //Variables from the panel where spikes by cell are selected...
   Variable /G N_Min_Spikes, N_Max_Spikes, N_Cell_Min, N_Cell_Max, N_Spikes_By_Cell
   Variable /G N_Spikes_Selected,N_Of_Cells, Total_Spikes=0, N_Min_Spk_Exclude_Cell
   String /G Exp_Folder = Current_Path()
   String /G Exp_Name = "Exp01"
   FSetExpFolder("",0,Exp_Folder,"Exp_Folder")
   Make /O /N=0 /T Gallery_Id
   Make /O /N=0 Gallery_Spk, Gallery_Begin, Gallery_XMax, Gallery_Final
   Make /O /N=0 Gallery_Imax, Gallery_Q, Gallery_Qter, Gallery_Tm, Gallery_m, Gallery_tp, Gallery_TauUp, Gallery_TauDown, Gallery_Cell
   SetScale/P y -Inf,Inf,"nA/s" Gallery_m
   SetScale d 0,0,"pA", Gallery_Imax
   SetScale d 0,0,"pC", Gallery_Q
   SetScale d 0,0,"pC^1/3", Gallery_Qter
   SetScale d 0,0,"ms", Gallery_Tm
   SetScale d 0,0,"ms", Gallery_tp
   SetScale d 0,0,"ms", Gallery_TauUp
   SetScale d 0,0,"ms", Gallery_TauDown
End

Window Gallery_Main_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(8,43,107,385) as "Gallery"
	ModifyPanel cbRGB=(52224,52224,52224)
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
	DrawRect -4,0,142,343
	SetDrawEnv fstyle= 1
	SetDrawEnv save
	SetDrawEnv fname= "Arial"
	DrawText 5,45,"Table:"
	SetDrawEnv fname= "Arial"
	DrawText 6,87,"Histograms:"
	SetDrawEnv fname= "Arial"
	DrawText 6,131,"Layout:"
	SetDrawEnv fname= "Arial"
	DrawText 6,198,"Spikes:"
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 20,306,77,334
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 22,1,79,29
	SetDrawEnv linethick= 2
	DrawLine 0,297,104,297
	SetDrawEnv linethick= 2
	DrawLine -1,260,103,260
	SetDrawEnv fname= "Arial"
	DrawText 26,285,"Cell"
	Button Bu_Add_Experiment,pos={29,5},size={42,20},proc=F_Bu_Add_Experiment,title="Add"
	Button Bu_Add_Experiment,help={"Add spikes from one experiment to gallery."}
	Button Bu_Show_Gallery_Table,pos={6,44},size={40,20},proc=F_Bu_Show_Gallery_Table,title="Show"
	Button Bu_Show_Gallery_Table,help={"Show the result table of all spikes."}
	Button Bu_Close_Gallery_Table,pos={52,44},size={40,20},proc=F_Bu_Close_Gallery_Table,title="Close"
	Button Bu_Close_Gallery_Table,help={"Close the gallery table."}
	Button Bu_Show_Gallery_Histograms,pos={6,87},size={40,20},proc=F_Bu_Show_Gallery_Histograms,title="Show"
	Button Bu_Show_Gallery_Histograms,help={"Construct result histograms."}
	Button Bu_Close_Gallery_Histograms,pos={52,87},size={40,20},proc=F_Bu_Close_Gallery_Histograms,title="Close"
	Button Bu_Close_Gallery_Histograms,help={"Close gallery histograms."}
	Button Bu_Show_Spike_Display,pos={6,200},size={40,20},proc=F_Bu_Show_Spike_Display,title="Show"
	Button Bu_Show_Spike_Display,help={"Show  'spike (gallery) ' graph"}
	Button Bu_Close_Spike_Display,pos={53,200},size={40,20},proc=F_Bu_Close_Spike_Display,title="Close"
	Button Bu_Start_New_Gallery,pos={27,310},size={42,20},proc=F_Bu_Start_New_Gallery,title="Start"
	Button Bu_Start_New_Gallery,help={"Start with a new gallery."}
	Button Bu_Close_All_Gallery_Graphs,pos={13,230},size={71,20},proc=F_Bu_Close_All_Gallery_Graphs,title="Close All"
	Button Bu_Close_All_Gallery_Graphs,help={"Close all graphic windows of this gallery."}
	Button Bu_Show_Gallery_Layout,pos={6,132},size={40,20},proc=F_Bu_Show_Gallery_Layout,title="Show"
	Button Bu_Close_Gallery_Layout,pos={52,132},size={40,20},proc=F_Bu_Close_Gallery_Layout,title="Close"
	Button Bu_Save_Pict_Layout,pos={6,157},size={40,20},proc=F_Bu_Save_Pict_Layout,title="Pict"
	Button Bu_Save_Pict_Layout,help={"Save layout as PICT."}
	CheckBox Check_Cell,pos={51,270},size={15,14},proc=F_Check_Cell,title=" "
	CheckBox Check_Cell,help={"Click here to make the gallery by cell."},value=0
	ValDisplay ValDis_Total_Spikes,pos={49,181},size={44,16},font="Arial"
	ValDisplay ValDis_Total_Spikes,limits={0,0,0},barmisc={0,1000}
	ValDisplay ValDis_Total_Spikes,value= #"Total_Spikes"
EndMacro

//It returns Value_To_Find position in Wave_Where_Find wave (-1 indicates nof found).
Function Find_Value(Value_To_Find, Wave_Where_Find)
   Variable Value_To_Find
   Wave Wave_Where_Find
   Variable Position, Total, Counter
   PauseUpdate; Silent 1
   Position = -1
   Total = NumPnts(Wave_Where_Find)
   If (Total > 0)
      Counter = 0
      Do
         If (Wave_Where_Find[Counter] == Value_To_Find)
            Position = Counter
         Else
            Counter += 1
         EndIf
      While ((Counter < Total)   %&  (Position == -1))
   EndIf
   Return(Position)
End

//This function calculates data by cell to show them in the cell panel.
Function Calculate_Data_By_Cell()
   //Locals
   Variable Counter, P_Cell, Total
   //Globals
   NVar Total_Spikes = Total_Spikes
   NVar N_Min_Spikes = N_Min_Spikes
   NVar N_Max_Spikes = N_Max_Spikes
   NVar N_Cell_Min = N_Cell_Min
   NVar N_Cell_Max = N_Cell_Max
   NVar N_Spikes_Selected = N_Spikes_Selected
   NVar N_Spikes_By_Cell = N_Spikes_By_Cell
   NVar N_Of_Cells = N_Of_Cells
   NVar N_Min_Spk_Exclude_Cell = N_Min_Spk_Exclude_Cell
   Wave Gallery_Cell = Gallery_Cell
   PauseUpdate; Silent 1
   If (Total_Spikes > 0)
      Make /O /N=0 Cells
      Make /O /N=0 Spikes_In_Cell
      Make /O /N=0 Excluded_Cell
      Total = NumPnts(Gallery_Cell)
      Counter = 0
      Do          
         P_Cell = Find_Value(Gallery_Cell[Counter], Cells)  //Cell position in Cells wave.
         If (P_Cell > -1)
            Spikes_In_Cell[P_Cell] += 1
         Else
            InsertPoints NumPnts(Cells), 1, Cells
            InsertPoints NumPnts(Spikes_In_Cell), 1, Spikes_In_Cell
            InsertPoints NumPnts(Excluded_Cells), 1, Excluded_Cell
            Cells[NumPnts(Cells)-1] = Gallery_Cell[Counter]
            Spikes_In_Cell[NumPnts(Spikes_In_Cell)-1] = 1
         EndIf
         Counter += 1
      While (Counter < Total)
      Excluded_Cell = 0
      N_Of_Cells = NumPnts(Cells)
      WaveStats /Q Spikes_In_Cell
      N_Min_Spikes = V_Min
      N_Max_Spikes = V_Max
      N_Cell_Min = Cells[V_MinLoc]
      N_Cell_Max = Cells[V_MaxLoc]
      N_Min_Spk_Exclude_Cell = 0
      N_Spikes_Selected = 0
      N_Spikes_By_Cell = 0
   Else
      DoAlert 0, "No spikes in gallery..."
   EndIf
End

Window Panel_Cells() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(119,42,337,323) as "CELLS..."
	SetDrawLayer UserBack
	SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
	DrawRect 0,-1,305,389
	SetDrawEnv fstyle= 1
	SetDrawEnv save
	SetDrawEnv fillfgc= (30464,30464,30464)
	DrawRect 156,179,213,207
	SetDrawEnv fname= "Arial"
	DrawText 4,95,"Min.spikes.....:"
	SetDrawEnv fname= "Arial"
	DrawText 4,116,"Max.spikes....:"
	SetDrawEnv fname= "Arial"
	DrawText 4,202,"N.Random Spk:"
	SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
	DrawLine 300,169,-2,169
	SetDrawEnv fname= "Arial"
	DrawText 4,268,"Total spikes.......:"
	SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
	DrawLine 301,219,-1,219
	SetDrawEnv fname= "Arial"
	DrawText 3,247,"Spikes selected:"
	SetDrawEnv fname= "Arial"
	DrawText 4,68,"N.of cells........:"
	SetDrawEnv fname= "Arial"
	DrawText 147,77,"Cell:"
	SetDrawEnv fname= "Arial"
	DrawText 26,19,"All Spk/Cell"
	SetDrawEnv fname= "Arial"
	DrawText 106,19,"Random Spk"
	SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
	DrawLine 300,42,-2,42
	SetDrawEnv linethick= 3,linefgc= (13107,13107,13107),linebgc= (17476,17476,17476)
	DrawLine 300,127,-2,127
	SetDrawEnv fname= "Arial"
	DrawText 4,156,"Exclude Cell -- N.Min.Spk:"
	ValDisplay Val_N_Min_Spikes,pos={87,77},size={50,16},font="Arial"
	ValDisplay Val_N_Min_Spikes,limits={0,0,0},barmisc={0,1000}
	ValDisplay Val_N_Min_Spikes,value= #"N_Min_Spikes"
	ValDisplay Val_N_Max_Spikes,pos={87,98},size={50,16},font="Arial"
	ValDisplay Val_N_Max_Spikes,limits={0,0,0},barmisc={0,1000}
	ValDisplay Val_N_Max_Spikes,value= #"N_Max_Spikes"
	ValDisplay Val_Cell_Min,pos={144,77},size={30,16},font="Arial"
	ValDisplay Val_Cell_Min,limits={0,0,0},barmisc={0,1000},value= #"N_Cell_Min"
	ValDisplay Val_Cell_Max,pos={144,98},size={30,16},font="Arial"
	ValDisplay Val_Cell_Max,limits={0,0,0},barmisc={0,1000},value= #"N_Cell_Max"
	SetVariable Set_Spikes_By_Cell,pos={94,185},size={54,16},title=" ",font="Arial"
	SetVariable Set_Spikes_By_Cell,format="%g"
	SetVariable Set_Spikes_By_Cell,limits={0,Inf,1},value= N_Spikes_By_Cell
	Button Bu_Run_Cell_Spike_Statistic,pos={161,183},size={48,20},proc=F_Bu_Run_Cell_Spike_Statistic,title="Run"
	ValDisplay Val_Spikes_Selected,pos={101,230},size={48,16},font="Arial"
	ValDisplay Val_Spikes_Selected,limits={0,0,0},barmisc={0,1000}
	ValDisplay Val_Spikes_Selected,value= #"N_Spikes_Selected"
	ValDisplay Val_Total_Spikes,pos={101,252},size={48,16},font="Arial"
	ValDisplay Val_Total_Spikes,limits={0,0,0},barmisc={0,1000}
	ValDisplay Val_Total_Spikes,value= #"Total_Spikes"
	ValDisplay Val_N_Of_Cells,pos={87,50},size={50,16},font="Arial"
	ValDisplay Val_N_Of_Cells,limits={0,0,0},barmisc={0,1000},value= #"N_Of_Cells"
	CheckBox Check_AllSpkCell,pos={49,18},size={15,16},proc=F_Check_AllSpkCell,title="",value=1
	CheckBox Check_RandomSpk,pos={129,17},size={15,17},proc=F_Check_RandomSpk,title="",value=0
	SetVariable SetVar_N_Min_Spk_Exclude_Cell,pos={152,139},size={52,16},title=" "
	SetVariable SetVar_N_Min_Spk_Exclude_Cell,font="Arial"
	SetVariable SetVar_N_Min_Spk_Exclude_Cell,limits={0,Inf,1},value= N_Min_Spk_Exclude_Cell
EndMacro

Window Table_Cells() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(145,351,338,586) Cells,Spikes_In_Cell,Excluded_Cell as "Spikes in Cells"
	ModifyTable width(Point)=24,title(Point)=" ",width(Cells)=38,title(Cells)="Cell"
	ModifyTable width(Spikes_In_Cell)=38,title(Spikes_In_Cell)="Spk",width(Excluded_Cell)=44
	ModifyTable title(Excluded_Cell)="Exc."
EndMacro

Function F_Check_AllSpkCell(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   //Gallery_Spk is not neccesary to copy, because it contains all spikes and
   //modifying Gallery_Begin and Gallery_Final in subgallery is correct.
   Duplicate /O  Gallery_Begin_Full Gallery_Begin
   Duplicate /O  Gallery_XMax_Full Gallery_XMax
   Duplicate /O  Gallery_Final_Full Gallery_Final
   Duplicate /O  Gallery_Imax_Full Gallery_Imax
   Duplicate /O  Gallery_Q_Full Gallery_Q
   Duplicate /O  Gallery_Qter_Full Gallery_Qter
   Duplicate /O  Gallery_m_Full Gallery_m
   Duplicate /O  Gallery_Tm_Full Gallery_Tm
   Duplicate /O  Gallery_tp_Full Gallery_tp
   Duplicate /O  Gallery_TauUp_Full Gallery_TauUp
   Duplicate /O  Gallery_TauDown_Full Gallery_TauDown
   Duplicate /O  Gallery_Cell_Full Gallery_Cell
   Duplicate /O  Gallery_Id_Full Gallery_Id   
   Close_Windows_All_Spk()
   CheckBox Check_RandomSpk, value = ! Checked
   Calculate_Data_By_Cell()
End

Function F_Check_RandomSpk(CtrlName, Checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   PauseUpdate; Silent 1
   Duplicate /O  Gallery_Begin_Full Gallery_Begin
   Duplicate /O  Gallery_XMax_Full Gallery_XMax
   Duplicate /O  Gallery_Final_Full Gallery_Final
   Duplicate /O  Gallery_Imax_Full Gallery_Imax
   Duplicate /O  Gallery_Q_Full Gallery_Q
   Duplicate /O  Gallery_Qter_Full Gallery_Qter
   Duplicate /O  Gallery_m_Full Gallery_m
   Duplicate /O  Gallery_Tm_Full Gallery_Tm
   Duplicate /O  Gallery_tp_Full Gallery_tp
   Duplicate /O  Gallery_TauUp_Full Gallery_TauUp
   Duplicate /O  Gallery_TauDown_Full Gallery_TauDown
   Duplicate /O  Gallery_Cell_Full Gallery_Cell
   Duplicate /O  Gallery_Id_Full Gallery_Id   
   Close_Windows_All_Spk()
   CheckBox Check_AllSpkCell, value = ! Checked
   Calculate_Data_By_Cell()
End

Function Close_Windows_All_Spk()
   PauseUpdate; Silent 1
   DoWindow /K Table_Mean_Cell
   DoWindow /K Table_Median_Cell
   DoWindow /K Table_StdDev_Cell
End

//It checks if each cell includes more spikes than that indicated in panel.
Function Update_Excluded_Cell()
   Variable Counter, Total
   NVar N_Min_Spk_Exclude_Cell = N_Min_Spk_Exclude_Cell
   Wave Excluded_Cell = Excluded_Cell
   Wave Spikes_In_Cell = Spikes_In_Cell
   PauseUpdate; Silent 1
   Counter = 0
   Total = NumPnts(Excluded_Cell)
   If (Total > 0)
      Do
         If (N_Min_Spk_Exclude_Cell > Spikes_In_Cell[Counter])
            Excluded_Cell[Counter] = 1
         Else
            Excluded_Cell[Counter] = 0
         EndIf
         Counter +=1
      While (Counter < Total)
   EndIf
End

//It begins the statistics by cell.
Function F_Bu_Run_Cell_Spike_Statistic(CtrlName)
   String ctrlName
   PauseUpdate; Silent 1
   Update_Excluded_Cell()
   ControlInfo /W=Panel_Cells  Check_AllSpkCell
   If ( V_Value )
      Cell_Statistic()
   Else
      Spike_Statistic()
   EndIf
   DoWindow /F Panel_Cells
End

//It calculates statistics by cell (Statistic_Type = 1) o by random spikes (Statistic_Type = 2).
Function Calculate_Statistic(Statistic_Type)
   Variable Statistic_Type
   //Locals
   Variable Counter, Total, P_Cell, N_Cell, N_Spk_Cell, All_Cell_Excluded
   //Globals
   NVar N_Of_Cells = N_Of_Cells
   NVar N_Spikes_By_Cell = N_Spikes_By_Cell
   Wave Gallery_Cell = Gallery_Cell
   Wave Cells = Cells
   Wave Spikes_In_Cell = Spikes_In_Cell
   Wave Excluded_Cell = Excluded_Cell
   Wave Gallery_Imax = Gallery_Imax
   Wave Gallery_Q = Gallery_Q
   Wave Gallery_Qter = Gallery_Qter
   Wave Gallery_tm = Gallery_tm
   Wave Gallery_m = Gallery_m
   Wave Gallery_tp = Gallery_tp
   Wave Gallery_TauUp = Gallery_TauUp
   Wave Gallery_TauDown = Gallery_TauDown
   PauseUpdate; Silent 1
      Make /N=(N_Of_Cells) /O Imax_Mean, Q_Mean, Qter_Mean, tm_Mean, m_Mean, tp_Mean, TauUp_Mean, TauDown_Mean
      Make /N=(N_Of_Cells) /O Imax_Median, Q_Median, Qter_Median, tm_Median, m_Median, tp_Median, TauUp_Median, TauDown_Median
      Make /N=(N_Of_Cells) /O Imax_StdDev, Q_StdDev, Qter_StdDev, tm_StdDev, m_StdDev, tp_StdDev, TauUp_StdDev, TauDown_StdDev
      N_Cell = 0
      All_Cell_Excluded = 1
      Total = NumPnts(Gallery_Imax)
      Do 
         If (Excluded_Cell[N_Cell] == 0)
            All_Cell_Excluded = 0
            P_Cell = Cells[N_Cell]
            If (Statistic_Type == 1)
               Make /N=(Spikes_In_Cell[N_Cell]) /O Imax_Cell, Q_Cell, Qter_Cell, tm_Cell, m_Cell, tp_Cell, TauUp_Cell, TauDown_Cell
            Else
               Make /N=(N_Spikes_By_Cell) /O Imax_Cell, Q_Cell, Qter_Cell, tm_Cell, m_Cell, tp_Cell, TauUp_Cell, TauDown_Cell      
            EndIf
            N_Spk_Cell = 0
            Counter = 0
            Do          
               If (P_Cell == Gallery_Cell[Counter])
                  Imax_Cell[N_Spk_Cell] = Gallery_Imax[Counter]
                  Q_Cell[N_Spk_Cell] = Gallery_Q[Counter]
                  Qter_Cell[N_Spk_Cell] = Gallery_Qter[Counter]
                  tm_Cell[N_Spk_Cell] = Gallery_tm[Counter]
                  m_Cell[N_Spk_Cell] = Gallery_m[Counter]
                  tp_Cell[N_Spk_Cell] = Gallery_tp[Counter]
                  TauUp_Cell[N_Spk_Cell] = Gallery_TauUp[Counter]
                  TauDown_Cell[N_Spk_Cell] = Gallery_TauDown[Counter]
                  N_Spk_Cell += 1
               EndIf
               Counter += 1
            While (Counter < Total)
            WaveStats /Q Imax_Cell
            Imax_Mean[N_Cell] = V_Avg
            Imax_StdDev[N_Cell] = V_SDev
            Sort Imax_Cell Imax_Cell
            Imax_Median[N_Cell] = Imax_Cell[NumPnts(Imax_Cell) / 2]
            WaveStats /Q Q_Cell
            Q_Mean[N_Cell] = V_Avg
            Q_StdDev[N_Cell] = V_SDev
            Sort Q_Cell Q_Cell
            Q_Median[N_Cell] = Q_Cell[NumPnts(Q_Cell) / 2]
            WaveStats /Q Qter_Cell
            Qter_Mean[N_Cell] = V_Avg
            Qter_StdDev[N_Cell] = V_SDev
            Sort Qter_Cell Qter_Cell
            Qter_Median[N_Cell] = Qter_Cell[NumPnts(Qter_Cell) / 2]
            WaveStats /Q tm_Cell
            tm_Mean[N_Cell] = V_Avg
            tm_StdDev[N_Cell] = V_SDev
            Sort tm_Cell tm_Cell
            tm_Median[N_Cell] = tm_Cell[NumPnts(tm_Cell) / 2]
            WaveStats /Q m_Cell
            m_Mean[N_Cell] = V_Avg
            m_StdDev[N_Cell] = V_SDev
            Sort m_Cell m_Cell
            m_Median[N_Cell] = m_Cell[NumPnts(m_Cell) / 2]
            WaveStats /Q tp_Cell
            tp_Mean[N_Cell] = V_Avg
            tp_StdDev[N_Cell] = V_SDev
            Sort tp_Cell tp_Cell
            tp_Median[N_Cell] = tp_Cell[NumPnts(tp_Cell) / 2]
            WaveStats /Q TauUp_Cell
            TauUp_Mean[N_Cell] = V_Avg
            TauUp_StdDev[N_Cell] = V_SDev
            Sort TauUp_Cell TauUp_Cell
            TauUp_Median[N_Cell] = TauUp_Cell[NumPnts(TauUp_Cell) / 2]
            WaveStats /Q TauDown_Cell
            TauDown_Mean[N_Cell] = V_Avg
            TauDown_StdDev[N_Cell] = V_SDev
            Sort TauDown_Cell TauDown_Cell
            TauDown_Median[N_Cell] = TauDown_Cell[NumPnts(TauDown_Cell) / 2]
         Else
            Imax_Mean[N_Cell] = 0
            Imax_StdDev[N_Cell] = 0
            Imax_Median[N_Cell] = 0
            Q_Mean[N_Cell] = 0
            Q_StdDev[N_Cell] = 0
            Q_Median[N_Cell] = 0
            Qter_Mean[N_Cell] = 0
            Qter_StdDev[N_Cell] = 0
            Qter_Median[N_Cell] = 0
            tm_Mean[N_Cell] = 0
            tm_StdDev[N_Cell] = 0
            tm_Median[N_Cell] = 0
            m_Mean[N_Cell] = 0
            m_StdDev[N_Cell] = 0
            m_Median[N_Cell] = 0
            tp_Mean[N_Cell] = 0
            tp_StdDev[N_Cell] = 0
            tp_Median[N_Cell] = 0
            TauUp_Mean[N_Cell] = 0
            TauUp_StdDev[N_Cell] = 0
            TauUp_Median[N_Cell] = 0
            TauDown_Mean[N_Cell] = 0
            TauDown_StdDev[N_Cell] = 0
            TauDown_Median[N_Cell] = 0
         EndIf
         N_Cell += 1
      While (N_Cell < N_Of_Cells)
   KillWaves /Z Imax_Cell, Q_Cell, Qter_Cell, tm_Cell, m_Cell, tp_Cell, TauUp_Cell, TauDown_Cell
   Return(All_Cell_Excluded)
End

//It calculates mean, median and std.dev. of every cell.
Function Cell_Statistic()
   //Locals
   Variable Counter, P_Cell, N_Cell, N_Spk_Cell, All_Cell_Excluded
   //Globals
   NVar Total_Spikes = Total_Spikes
   Wave Excluded_Cell = Excluded_Cell
   PauseUpdate; Silent 1
   If (Total_Spikes > 0)
      All_Cell_Excluded = Calculate_Statistic(1)
      If (!All_Cell_Excluded)
         Create_Cell_SubGallery(Excluded_Cell) //It creates a subgallery without including spikes from excluded cells.
         Show_Tables()
      Else
         DoAlert 0, "All cells have been excluded from statistics..."
      EndIf      
   Else
      DoAlert 0, "No spikes in gallery..."
   EndIf
End

//It creates a subgallery with spikes from cells which have not been excluded.
Function Create_Cell_SubGallery(Excluded_Cell)
   Wave Excluded_Cell
   Variable Counter, Total, Pos
   //Globals
   NVar N_Spikes_Selected = N_Spikes_Selected
   Wave Gallery_Begin_Full = Gallery_Begin_Full
   Wave Gallery_XMax_Full = Gallery_XMax_Full
   Wave Gallery_Final_Full = Gallery_Final_Full
   Wave Gallery_Imax_Full = Gallery_Imax_Full
   Wave Gallery_Q_Full = Gallery_Q_Full
   Wave Gallery_Qter_Full = Gallery_Qter_Full
   Wave Gallery_m_Full = Gallery_m_Full
   Wave Gallery_Tm_Full = Gallery_Tm_Full
   Wave Gallery_tp_Full = Gallery_tp_Full
   Wave Gallery_TauUp_Full = Gallery_TauUp_Full
   Wave Gallery_TauDown_Full = Gallery_TauDown_Full
   Wave Gallery_Cell_Full = Gallery_Cell_Full
   Wave /T Gallery_Id_Full = Gallery_Id_Full
   PauseUpdate; Silent 1
   Total = NumPnts(Gallery_Id_Full)
   Counter = 0
   Duplicate /O  Gallery_Begin_Full Gallery_Begin
   Duplicate /O  Gallery_XMax_Full Gallery_XMax
   Duplicate /O  Gallery_Final_Full Gallery_Final
   Duplicate /O  Gallery_Imax_Full Gallery_Imax
   Duplicate /O  Gallery_Q_Full Gallery_Q
   Duplicate /O  Gallery_Qter_Full Gallery_Qter
   Duplicate /O  Gallery_m_Full Gallery_m
   Duplicate /O  Gallery_Tm_Full Gallery_Tm
   Duplicate /O  Gallery_tp_Full Gallery_tp
   Duplicate /O  Gallery_TauUp_Full Gallery_TauUp
   Duplicate /O  Gallery_TauDown_Full Gallery_TauDown
   Duplicate /O  Gallery_Cell_Full Gallery_Cell
   Duplicate /O  Gallery_Id_Full Gallery_Id   
   Do
      Pos = Find_Value(Gallery_Cell[Counter], Cells)
      If (Pos >= 0)
         If (Excluded_Cell[Pos] == 1)
            DeletePoints Counter, 1, Gallery_Begin
            DeletePoints Counter, 1, Gallery_Final
            DeletePoints Counter, 1, Gallery_XMax
            DeletePoints Counter, 1, Gallery_Imax
            DeletePoints Counter, 1, Gallery_Q
            DeletePoints Counter, 1, Gallery_Qter
            DeletePoints Counter, 1, Gallery_m
            DeletePoints Counter, 1, Gallery_Tm
            DeletePoints Counter, 1, Gallery_tp
            DeletePoints Counter, 1, Gallery_TauUp
            DeletePoints Counter, 1, Gallery_TauDown
            DeletePoints Counter, 1, Gallery_Cell
            DeletePoints Counter, 1, Gallery_Id
         Else
            Counter += 1
         EndIf
      Else
         Counter += 1
      EndIf
   While (Counter < Total)
   N_Spikes_Selected = NumPnts(Gallery_Id)
End

//This function shows the three tables with cell statistic: mean, median and std.dev.
Function Show_Tables()
   PauseUpdate; Silent 1
   If ( WinType( "Table_Mean_Cell") == 0)
      Execute "Table_Mean_Cell()"
   EndIf
   If ( WinType( "Table_Median_Cell") == 0)
      Execute "Table_Median_Cell()"
   EndIf
   If ( WinType( "Table_StdDev_Cell") == 0)
      Execute "Table_StdDev_Cell()"
   EndIf
   DoWindow /F Table_StdDev_Cell
   DoWindow /F Table_Median_Cell
   DoWindow /F Table_Mean_Cell
End

Window Table_Mean_Cell() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(348,42.5,696.75,206) Cells,Imax_Mean,Q_Mean,Qter_Mean,tm_Mean,m_Mean,tp_Mean as "MEAN"
	AppendToTable TauUp_Mean,TauDown_Mean
	ModifyTable width(Point)=17,title(Point)="P",size(Cells)=9,width(Cells)=23,size(Imax_Mean)=9
	ModifyTable width(Imax_Mean)=39,title(Imax_Mean)="Imax",size(Q_Mean)=9,width(Q_Mean)=41
	ModifyTable title(Q_Mean)="Q",size(Qter_Mean)=9,width(Qter_Mean)=39,title(Qter_Mean)="Q^1/3"
	ModifyTable size(tm_Mean)=9,width(tm_Mean)=38,title(tm_Mean)="t1/2",size(m_Mean)=9
	ModifyTable width(m_Mean)=36,title(m_Mean)="m",size(tp_Mean)=9,width(tp_Mean)=32
	ModifyTable title(tp_Mean)="tp",size(TauUp_Mean)=9,width(TauUp_Mean)=35,title(TauUp_Mean)="Tau"
	ModifyTable size(TauDown_Mean)=9,width(TauDown_Mean)=36,title(TauDown_Mean)="Tau'"
EndMacro

Window Table_Median_Cell() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(350.25,233.75,697.5,385.25) Cells,Imax_Median,Q_Median,Qter_Median,tm_Median as "MEDIAN"
	AppendToTable m_Median,tp_Median,TauUp_Median,TauDown_Median
	ModifyTable width(Point)=17,title(Point)="P",size(Cells)=9,width(Cells)=20,size(Imax_Median)=9
	ModifyTable width(Imax_Median)=36,title(Imax_Median)="Imax",size(Q_Median)=9,width(Q_Median)=38
	ModifyTable title(Q_Median)="Q",size(Qter_Median)=9,width(Qter_Median)=41,title(Qter_Median)="Q^1/3"
	ModifyTable size(tm_Median)=9,width(tm_Median)=36,title(tm_Median)="t1/2",size(m_Median)=9
	ModifyTable width(m_Median)=33,title(m_Median)="m",size(tp_Median)=9,width(tp_Median)=33
	ModifyTable title(tp_Median)="tp",size(TauUp_Median)=9,width(TauUp_Median)=38,title(TauUp_Median)="Tau"
	ModifyTable size(TauDown_Median)=9,width(TauDown_Median)=38,title(TauDown_Median)="Tau'"
EndMacro

Window Table_StdDev_Cell() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(348.75,413.75,697.5,577.25) Cells,Imax_StdDev,Q_StdDev,Qter_StdDev,tm_StdDev as "STD.DEV."
	AppendToTable m_StdDev,tp_StdDev,TauUp_StdDev,TauDown_StdDev
	ModifyTable width(Point)=17,title(Point)="P",size(Cells)=9,width(Cells)=21,size(Imax_StdDev)=9
	ModifyTable width(Imax_StdDev)=38,title(Imax_StdDev)="Imax",size(Q_StdDev)=9,width(Q_StdDev)=39
	ModifyTable title(Q_StdDev)="Q",size(Qter_StdDev)=9,width(Qter_StdDev)=36,title(Qter_StdDev)="Q^1/3"
	ModifyTable size(tm_StdDev)=9,width(tm_StdDev)=36,title(tm_StdDev)="t1/2",size(m_StdDev)=9
	ModifyTable width(m_StdDev)=36,title(m_StdDev)="m",size(tp_StdDev)=9,width(tp_StdDev)=36
	ModifyTable title(tp_StdDev)="tp",size(TauUp_StdDev)=9,width(TauUp_StdDev)=38,title(TauUp_StdDev)="Tau"
	ModifyTable size(TauDown_StdDev)=9,width(TauDown_StdDev)=36,title(TauDown_StdDev)="Tau'"
EndMacro

//This function selects a number of random spikes from every cell,
//creating a subgallery with them.
Function Spike_Statistic()
   //Locals
   Variable  Cells_Added, All_Cell_Excluded
   //Globals
   NVar N_Spikes_By_Cell = N_Spikes_By_Cell
   NVar N_Spikes_Selected = N_Spikes_Selected
   NVar N_Of_Cells = N_Of_Cells
   PauseUpdate; Silent 1
   If (N_Spikes_By_Cell > 0)
         Cells_Added = 0
         //The spike positions of the new subgallery will be saved in this wave:
         Make /N=0 /O N_Spikes_Random_Gallery 
         Do
            Add_Spikes_Of_Cell(Cells_Added)
            Cells_Added += 1
         While (Cells_Added < N_Of_Cells)
         N_Spikes_Selected = NumPnts(N_Spikes_Random_Gallery)
         If (N_Spikes_Selected)
            Create_Random_SubGallery(N_Spikes_Random_Gallery) //It is created a subgallery with the random spikes.
            All_Cell_Excluded = Calculate_Statistic(2)   //REVISAR AQUI
            Show_Tables()
         Else
            DoAlert 0, "All cells have been excluded from gallery..."
         EndIf
   Else
      DoAlert 0, "No spikes has been selected..."
   EndIf
End

//This function create a subgallery with the spikes which positions are in N_Spikes_Random_Gallery.
Function Create_Random_SubGallery(N_Spikes_Random_Gallery)
   Wave N_Spikes_Random_Gallery
   Variable Counter, Total, Pos
   //Globals
   Wave Gallery_Begin_Full = Gallery_Begin_Full
   Wave Gallery_XMax_Full = Gallery_XMax_Full
   Wave Gallery_Final_Full = Gallery_Final_Full
   Wave Gallery_Imax_Full = Gallery_Imax_Full
   Wave Gallery_Q_Full = Gallery_Q_Full
   Wave Gallery_Qter_Full = Gallery_Qter_Full
   Wave Gallery_m_Full = Gallery_m_Full
   Wave Gallery_Tm_Full = Gallery_Tm_Full
   Wave Gallery_tp_Full = Gallery_tp_Full
   Wave Gallery_TauUp_Full = Gallery_TauUp_Full
   Wave Gallery_TauDown_Full = Gallery_TauDown_Full
   Wave Gallery_Cell_Full = Gallery_Cell_Full
   Wave /T Gallery_Id_Full = Gallery_Id_Full
   PauseUpdate; Silent 1
   Total = NumPnts(N_Spikes_Random_Gallery)
   If (Total > 0)
      Counter = 0
      Sort N_Spikes_Random_Gallery N_Spikes_Random_Gallery
      Make /N=(Total) /O Gallery_Begin, Gallery_Final, Gallery_XMax, Gallery_Imax, Gallery_Q
      Make /N=(Total) /O Gallery_Qter, Gallery_tp, Gallery_TauUp, Gallery_TauDown, Gallery_m, Gallery_Tm, Gallery_Cell
      Make /N=(Total) /O /T Gallery_Id
      Do
         Pos = N_Spikes_Random_Gallery[Counter]
         Gallery_Begin[Counter] = Gallery_Begin_Full[Pos]
         Gallery_Final[Counter] = Gallery_Final_Full[Pos]
         Gallery_XMax[Counter] = Gallery_XMax_Full[Pos]
         Gallery_Imax[Counter] = Gallery_Imax_Full[Pos]
         Gallery_Q[Counter] = Gallery_Q_Full[Pos]
         Gallery_Qter[Counter] = Gallery_Qter_Full[Pos]
         Gallery_tp[Counter] = Gallery_tp_Full[Pos]
         Gallery_TauUp[Counter] = Gallery_TauUp_Full[Pos]
         Gallery_TauDown[Counter] = Gallery_TauDown_Full[Pos]
         Gallery_m[Counter] = Gallery_m_Full[Pos]
         Gallery_Tm[Counter] = Gallery_Tm_Full[Pos]
         Gallery_Cell[Counter] = Gallery_Cell_Full[Pos]   
         Gallery_Id[Counter] = Gallery_Id_Full[Pos]   
         Counter += 1
      While (Counter < Total)
   EndIf
End

//It finds N_Random different values between 0 and (Limit_Value-1).
//They are saved in Spikes_Random wave.
Function Create_Random_Values(N_Random, Limit_Value)
   Variable N_Random, Limit_Value
   //Locals
   Variable Counter, Random_Value, Values_To_Create, NV, Position
   //Globals
   Wave Spikes_Random = Spikes_Random
   PauseUpdate; Silent 1
   //When the number of values to randomly create is > than limit/2
   //they are randomly created the values to exclude.
   If (N_Random > (Limit_Value/2))
      Values_To_Create = Limit_Value - N_Random
   Else
      Values_To_Create = N_Random
   EndIf
   Make /O /N=(Values_To_Create) Value_Wave
   Value_Wave = -1
   Counter = 0
   Do
      Random_Value = Abs(Round(ENoise(Limit_Value - 1 )))
      If (Find_Value(Random_Value, Value_Wave) == -1)
         Value_Wave[Counter] = Random_Value
         Counter += 1
      EndIf
   While (Counter < N_Random)
   If (Values_To_Create == N_Random)
      Spikes_Random = Value_Wave
   Else
      Sort Value_Wave Value_Wave
      Counter = 0
      NV = 0
      Position = 0
      Do
         If ((Counter != Value_Wave[Position]) %| ( Position >= NumPnts(Value_Wave)))
            Spikes_Random[NV] = Counter
            NV += 1
         Else
            Position += 1
         EndIf
         Counter += 1
      While (Counter < Limit_Value)
   EndIf
   Sort Spikes_Random Spikes_Random
   KillWaves /Z Value_Wave
End

//This function randomly selects spikes from cell indicated in position P_Cell.
Function Add_Spikes_Of_Cell(P_Cell)
   Variable P_Cell
   //Locals
   Variable P_Spike, Counter, Spikes_Added, Total_Spk, Current_Cell
   //Globals
   NVar N_Spikes_By_Cell = N_Spikes_By_Cell
   NVar N_Min_Spk_Exclude_Cell = N_Min_Spk_Exclude_Cell
   Wave Cells = Cells
   Wave Excluded_Cell = Excluded_Cell
   Wave Spikes_In_Cell = Spikes_In_Cell
   Wave Gallery_Cell_Full = Gallery_Cell_Full
   Wave N_Spikes_Random_Gallery = N_Spikes_Random_Gallery
   PauseUpdate; Silent 1
   If ((Excluded_Cell[P_Cell] == 0)  %& (Spikes_In_Cell[P_Cell] >= N_Spikes_By_Cell) %& (Spikes_In_Cell[P_Cell] >= N_Min_Spk_Exclude_Cell))
      Make /O /N=(N_Spikes_By_Cell) Spikes_Random
      Create_Random_Values(N_Spikes_By_Cell, Spikes_In_Cell[P_Cell])  //The positions of random spikes are saved in wave Spikes_Random
      P_Spike = 0
      Counter = 0
      Spikes_Added = 0
      Current_Cell = Cells[P_Cell]
      Total_Spk = NumPnts(Gallery_Cell_Full)
      Do
         If (Current_Cell == Gallery_Cell_Full[P_Spike])
            If (Counter == Spikes_Random[Spikes_Added])
               InsertPoints NumPnts(N_Spikes_Random_Gallery), 1, N_Spikes_Random_Gallery
               N_Spikes_Random_Gallery[NumPnts(N_Spikes_Random_Gallery)-1] = P_Spike
               Spikes_Added += 1
            EndIf
            Counter += 1
         EndIf
         P_Spike += 1
      While ((Spikes_Added < N_Spikes_By_Cell) %& (P_Spike < Total_Spk))
   Else
      Excluded_Cell[P_Cell] = 1
   EndIf
End

//This function is executed when "Check cell" is selected.
Function F_Check_Cell (ctrlName, checked) : CheckBoxControl
   String ctrlName
   Variable checked         // 1 if checked, 0 if not
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   F_Close_All_Cell_Graphs()
   F_Bu_Close_All_Gallery_Graphs("")
   If (Checked == 1)
      If (Total_Spikes)
         Duplicate /O Gallery_Begin  Gallery_Begin_Full
         Duplicate /O Gallery_XMax  Gallery_XMax_Full
         Duplicate /O Gallery_Final  Gallery_Final_Full
         Duplicate /O Gallery_Imax  Gallery_Imax_Full
         Duplicate /O Gallery_Q  Gallery_Q_Full
         Duplicate /O Gallery_Qter  Gallery_Qter_Full
         Duplicate /O Gallery_m  Gallery_m_Full
         Duplicate /O Gallery_Tm  Gallery_Tm_Full
         Duplicate /O Gallery_tp  Gallery_tp_Full
         Duplicate /O Gallery_TauUp  Gallery_TauUp_Full
         Duplicate /O Gallery_TauDown  Gallery_TauDown_Full
         Duplicate /O Gallery_Cell  Gallery_Cell_Full
         Duplicate /O Gallery_Id  Gallery_Id_Full
         Calculate_Data_By_Cell()   
         Execute "Table_Cells()"
         Execute "Panel_Cells()"
      Else
         DoAlert 0, "No spikes in this gallery."
      EndIf
   Else
      If (Exists("Gallery_Id_Full")) //If the inverse copy has been made previosly...
         Duplicate /O  Gallery_Begin_Full Gallery_Begin
         Duplicate /O  Gallery_XMax_Full Gallery_XMax
         Duplicate /O  Gallery_Final_Full Gallery_Final
         Duplicate /O  Gallery_Imax_Full Gallery_Imax
         Duplicate /O  Gallery_Q_Full Gallery_Q
         Duplicate /O  Gallery_Qter_Full Gallery_Qter
         Duplicate /O  Gallery_m_Full Gallery_m
         Duplicate /O  Gallery_Tm_Full Gallery_Tm
         Duplicate /O  Gallery_tp_Full Gallery_tp
         Duplicate /O  Gallery_TauUp_Full Gallery_TauUp
         Duplicate /O  Gallery_TauDown_Full Gallery_TauDown
         Duplicate /O  Gallery_Cell_Full Gallery_Cell
         Duplicate /O  Gallery_Id_Full Gallery_Id
         KillWaves /Z Gallery_Begin_Full, Gallery_XMax_Full, Gallery_Final_Full, Gallery_Imax_Full, Gallery_Q_Full
         KillWaves /Z Gallery_Qter_Full, Gallery_m_Full, Gallery_Tm_Full, Gallery_tp_Full, Gallery_TauUp_Full, Gallery_TauDown_Full, Gallery_Cell_Full
         KillWaves /Z Gallery_Id_Full
         KillWaves /Z Spikes_Random, N_Spikes_Random_Gallery, Excluded_Cell, Spikes_In_Cell, Cells
         KillWaves /Z tp_Mean, TauUp_Mean, TauDown_Mean, m_Mean,tm_Mean,Qter_Mean,Q_Mean,Imax_Mean
         KillWaves /Z tp_Median,TauUp_Median, TauDown_Median, m_Median,tm_Median,Qter_Median,Q_Median,Imax_Median
         KillWaves /Z tp_StdDev,TauUp_StdDev, TauDown_StdDev, m_StdDev,tm_StdDev,Qter_StdDev,Q_StdDev,Imax_StdDev
      EndIf
   EndIf
End

Function F_Bu_Start_New_Gallery(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   Galleries()
End

Function F_Bu_Close_All_Gallery_Graphs(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K ChoosePanel
   DoWindow /K Gallery_Load_Panel
   DoWindow /K Histo_Imax
   DoWindow /K Histo_Tm
   DoWindow /K Histo_Q
   DoWindow /K Histo_Qter
   DoWindow /K Histo_tp
   DoWindow /K Histo_TauUp
   DoWindow /K Histo_TauDown
   DoWindow /K Histo_m
   DoWindow /K Gallery_Table
   DoWindow /K Gallery_Spike_Graph
   DoWindow /K Layout_Gallery_Graph
End

Function F_Close_All_Cell_Graphs()
   PauseUpdate; Silent 1
   DoWindow /K Panel_Cells
   DoWindow /K Table_Cells
   DoWindow /K Table_Mean_Cell
   DoWindow /K Table_Median_Cell
   DoWindow /K Table_StdDev_Cell
End

Function F_Bu_Save_Pict_Layout( CtrlName)
   String CtrlName
   // Globals
   SVar Exp_Name = Exp_Name
   PauseUpdate; Silent 1
   If ( WinType("Layout_Gallery_Graph") == 0)
      DoAlert 1, "The layout is not made. Make it?"
      If ( V_Flag == 1)
         F_Bu_Show_Gallery_Layout(" ")
         DoWindow /F Layout_Gallery_Graph
         SavePICT /E=-2 as "Layout_"+Exp_Name
      EndIf
   Else
      DoWindow /F Layout_Gallery_Graph
      SavePICT /E=-2 as "Layout_"+Exp_Name
   EndIf
End

Window Layout_Save_Panel() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(10,108,312,205) as "Saving experiment..."
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect -2,-2,304,115
   SetDrawEnv fstyle= 1
   SetDrawEnv save
   SetDrawEnv fname= "Arial"
   DrawText 8,19,"SAVING FOLDER:"
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 143,51,200,79
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 220,51,277,79
   SetVariable Set_Checked_Result_Folder,pos={6,20},size={269,16},title=" "
   SetVariable Set_Checked_Result_Folder,help={"Type here the full path of the folder where experiment waves will be saved: Data, X_Peak, X_Beginning, X_Final, etc."}
   SetVariable Set_Checked_Result_Folder,font="Arial"
   SetVariable Set_Checked_Result_Folder,limits={-Inf,Inf,0},value= Checked_Result_Folder
   Button Bu_Save_Exp,pos={151,56},size={42,19},proc=F_Bu_Save_Exp,title="Save"
   Button Bu_Cancel_Save_Exp,pos={226,55},size={46,20},proc=F_Bu_Cancel_Save_Exp,title="Cancel"
EndMacro

Function F_Bu_Add_Experiment( CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   F_Bu_Close_All_Gallery_Graphs("")
   F_Close_All_Cell_Graphs()
   //When new spikes are to be added, if Check_Cell is activated, it has to be desactivated, 
   //because these new spikes must be considered in the new calculation by cell.
   CheckBox Check_Cell, Value = 0
   F_Check_Cell(" ", 0)
   Execute "Gallery_Load_Panel()"
   Update_Check_Waves_Exp()
   DoWindow /F Gallery_Load_Panel
End

Function Update_Check_Waves_Exp()
   // Globals
   NVar Check_Waves_Exp = Check_Waves_Exp
   PauseUpdate; Silent 1
   CheckBox Check_Waves, value = Check_Waves_Exp
   CheckBox Check_Exp, value = ! Check_Waves_Exp
End

Window Gallery_Load_Panel() : Panel
   PauseUpdate; Silent 1      // building window...
   NewPanel /W=(107,65,519,195) as "Add experiment to gallery..."
   ModifyPanel cbRGB=(52224,52224,52224)
   SetDrawLayer UserBack
   SetDrawEnv linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect -2,-1,419,154
   SetDrawEnv fname= "Arial",fstyle= 1
   DrawText 10,16,"Experiment folder:"
   SetDrawEnv fillfgc= (65280,0,0),fsize= 9
   SetDrawEnv save
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 199,85,256,113
   SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
   DrawText 10,54,"Experiment name:"
   SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
   DrawText 31,125,"Experiment"
   SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
   DrawText 31,107,"Waves"
   SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
   DrawText 10,91,"Format in disk:"
   SetDrawEnv fillfgc= (30464,30464,30464)
   DrawRect 133,85,190,113
   SetDrawEnv fillfgc= (65535,65535,65535),fname= "Arial",fsize= 12,fstyle= 1
   DrawText 142,54,"Cell:"
   SetVariable Set_Exp_Folder,pos={9,17},size={369,16},title=" "
   SetVariable Set_Exp_Folder,help={"Write here the folder where the experiment waves are."}
   SetVariable Set_Exp_Folder,font="Arial",limits={0,0,0},value= Exp_Folder, proc=FSetExpFolder
   SetVariable Set_Exp_Name,pos={11,54},size={100,16},title=" ",font="Arial"    //proc is the same used in Load_Panel
   SetVariable Set_Exp_Name,limits={0,0,0},value= Exp_Name                                //of Spike View.
   CheckBox Check_Waves,pos={12,91},size={16,16},proc=F_Check_Waves,title=""
   CheckBox Check_Waves,help={"Click here if experiment was saved in format of igor waves."},value=1
   CheckBox Check_Exp,pos={12,109},size={16,16},proc=F_Check_Exp,title=""
   CheckBox Check_Exp,help={"Click here if experiment was saved in format of igor experiment."},value=0
   Button Bu_Load_Exp_Gallery,pos={139,89},size={45,20},proc=F_Bu_Load_Exp_Gallery,title="Load"
   Button Bu_Load_Exp_Gallery,help={"Load files or Igor Experiment from 'Spike view'"}
   Button Bu_Cancel_Load_Gallery,pos={205,89},size={45,20},proc=F_Bu_Cancel_Load_Gallery,title="Cancel"
   SetVariable Set_Cell,pos={142,53},size={47,16},title=" "
   SetVariable Set_Cell,help={"Type here the cell number which generates this experiment."}
   SetVariable Set_Cell,font="Arial",limits={0,Inf,1},value= NCell
   Button Bu_ChooseExpFolder,pos={383,17},size={20,15},title="<>", proc=FBuChooseExpFolder
EndMacro                                                                                   //This proc is the same used in Load_Panel of SpikeView,
                                                                                                   //because it use the same variable: Exp_Folder.
Function F_Bu_Cancel_Load_Gallery( CtrlName)
   String CtrlName
   // Globals
   NVar Check_Waves_Exp = Check_Waves_Exp
   PauseUpdate; Silent 1
   ControlInfo /W=Gallery_Load_Panel Check_Waves
   Check_Waves_Exp = V_Value
   DoWindow /K Gallery_Load_Panel   
   DoWindow /K ChoosePanel
End

Function F_Check_Exp( CtrlName, Checked)
   String CtrlName
   Variable Checked
   PauseUpdate; Silent 1
   CheckBox Check_Waves, value = ! Checked
End

Function F_Check_Waves( CtrlName, Checked)
   String CtrlName
   Variable Checked
   PauseUpdate; Silent 1
   CheckBox Check_Exp, value = ! Checked
End

Function F_Bu_Load_Exp_Gallery(CtrlName)
   String CtrlName
   // Locals
   Variable Last_Point, Spk_In_Gallery, Index=0
   // Globals
   NVar Check_Waves_Exp = Check_Waves_Exp
   NVar Number_Of_Spikes = Number_Of_Spikes
   NVar NCell = NCell
   NVar Total_Spikes = Total_Spikes
   SVar Exp_Name = Exp_Name
   SVar Exp_Folder = Exp_Folder
   Wave Gallery_Spk = Gallery_Spk
   Wave Gallery_Begin = Gallery_Begin
   Wave Gallery_XMax = Gallery_XMax
   Wave Gallery_Final = Gallery_Final
   Wave Gallery_Imax = Gallery_Imax
   Wave Gallery_Q = Gallery_Q
   Wave Gallery_Qter = Gallery_Qter
   Wave Gallery_m = Gallery_m
   Wave Gallery_Tm = Gallery_Tm
   Wave Gallery_tp = Gallery_tp
   Wave Gallery_TauUp = Gallery_TauUp
   Wave Gallery_TauDown = Gallery_TauDown
   Wave Gallery_Cell = Gallery_Cell
   Wave /T Gallery_Id = Gallery_Id
   PauseUpdate;Silent 1
   ControlInfo /W=Gallery_Load_Panel Check_Waves
   Check_Waves_Exp = V_Value
   Make /N=0 /O X_Peak,X_Beginning, X_Final, Data, pC, pA, T_Half, M_Half, T_Peak, TauUp, TauDown, pC_Third
   If ( Load_Exp_Gallery())  // It returns 1 when no load error occurred; 0 when load error occurred.
      If ( ! NumPnts(Gallery_Spk))
         SetScale/P y -Inf,Inf,"A" Gallery_Spk
         Setscale/P x 0,  deltax(DATA), "s" Gallery_Spk
      EndIf
      Number_Of_Spikes = NumPnts(T_Half)
      If ( Number_Of_Spikes)
         Do
            Last_Point=numpnts(Gallery_Spk)
            Duplicate /O /R=(X_Beginning(Index)-0.1, X_Final( Index)+0.4) Data Spike
            InsertPoints Last_Point, NumPnts( Spike), Gallery_Spk
            Gallery_Spk [Last_Point, ]= Spike[ p - Last_Point]
            Spk_In_Gallery=numpnts(Gallery_XMax)
            Redimension/n=(Spk_In_Gallery+1) Gallery_Begin, Gallery_XMax, Gallery_Final, Gallery_Imax, Gallery_Q, Gallery_Qter, Gallery_Tm
            Redimension/n=(Spk_In_Gallery+1) Gallery_m, Gallery_tp, Gallery_TauUp, Gallery_TauDown
            Redimension/n=(Spk_In_Gallery+1) Gallery_Id, Gallery_Cell
            Gallery_Begin[Spk_In_Gallery]=pnt2x(Gallery_Spk, Last_Point) + 0.1
            Gallery_XMax[Spk_In_Gallery]=pnt2x(Gallery_Spk, Last_Point)+(X_Peak[index]-X_Beginning[index])+0.1
            Gallery_Final[Spk_In_Gallery]=pnt2x(Gallery_Spk, Last_Point)+(X_Final[index]-X_Beginning[index])+0.1
            Gallery_Imax[Spk_In_Gallery]=pA[index]
            Gallery_Q[Spk_In_Gallery]=pC[index]
            Gallery_Qter[Spk_In_Gallery]=pC[index]^(1/3)
            Gallery_Tm[Spk_In_Gallery]=T_Half[index]
            Gallery_m[Spk_In_Gallery]=M_Half[index]
            Gallery_tp[Spk_In_Gallery]=T_Peak[index]
            Gallery_TauUp[Spk_In_Gallery]=TauUp[index]
            Gallery_TauDown[Spk_In_Gallery]=TauDown[index]
            Gallery_Id[Spk_In_Gallery]=Exp_Name+"/#"+num2istr(index)
            Gallery_Cell[Spk_In_Gallery]=NCell
            Index += 1
         While ( Index < Number_Of_Spikes)   
         Total_Spikes += Number_Of_Spikes
         KillWaves /Z Spike, X_Beginning, X_Final, X_Peak, pA, pC, pC_Third, T_Half, T_Peak, TauUp, TauDown, M_Half, Data
      Else
         DoAlert 0, "No spikes added to gallery."
      EndIf
      Print "Number of spikes added: " + Num2Str(Number_Of_Spikes) + "    Total in gallery: " + Num2Str(Total_Spikes)
      If ( NumPnts(Gallery_Id))
         Variable /G Gallery_In_Process  // To indicate that a gallery is in process. If you open a new gallery,
                                   // program warns you.
      EndIf
      If ( NumPnts(Gallery_Spk))
         DoWindow /K Gallery_Load_Panel
         DoWindow /K ChoosePanel
         If ( WinType("Gallery_Main_Panel") == 0)
            Execute "Gallery_Main_Panel()"
            CheckBox Check_Cell, Value=0
         EndIf
      EndIf
   EndIf
End

Function F_Bu_Close_Gallery_Histograms( CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Histo_Imax
   DoWindow /K Histo_Tm
   DoWindow /K Histo_Q
   DoWindow /K Histo_Qter
   DoWindow /K Histo_tp
   DoWindow /K Histo_TauUp
   DoWindow /K Histo_TauDown
   DoWindow /K Histo_m
   F_Bu_Close_Gallery_Layout("")
End

Function Make_Histograms()
   PauseUpdate; Silent 1
   Make /O Gallery_HistoTm, Gallery_HistopA, Gallery_HistopC, Gallery_HistopCT, Gallery_Histom, Gallery_Histotp, Gallery_HistoTauUp, Gallery_HistoTauDown
   WaveStats /Q Gallery_Tm
   Histogram/B={0,2, (V_Max / 2) + 1} Gallery_Tm, Gallery_HistoTm
   WaveStats /Q Gallery_Imax   
   Histogram/B={0,2, (V_Max / 2) + 1} Gallery_Imax,Gallery_HistopA
   WaveStats /Q Gallery_Q
   Histogram/B={0,0.1,(V_Max / 0.1) +1 } Gallery_Q, Gallery_HistopC
   WaveStats /Q Gallery_Qter
   Histogram/B={0,0.02,(V_Max/0.02) + 1} Gallery_Qter, Gallery_HistopCT
   WaveStats /Q Gallery_m
   Histogram/B={0,0.5, (V_Max/0.5) + 1} Gallery_m, Gallery_Histom
   WaveStats /Q Gallery_tp
   Histogram/B={0,0.5, (V_Max + 1) / 0.5} Gallery_tp, Gallery_Histotp
   WaveStats /Q Gallery_TauUp
   Histogram/B={0,1, (V_Max / 2) + 1} Gallery_TauUp, Gallery_HistoTauUp
   WaveStats /Q Gallery_TauDown
   Histogram/B={0,2, (V_Max / 2) + 1} Gallery_TauDown, Gallery_HistoTauDown
   Gallery_HistoTm/=numpnts(Gallery_Id)/100
   Gallery_HistopA/=numpnts(Gallery_Id)/100
   Gallery_HistopCT/=numpnts(Gallery_Id)/100
   Gallery_HistopC/=numpnts(Gallery_Id)/100
   Gallery_Histom/=numpnts(Gallery_Id)/100
   Gallery_Histotp/=numpnts(Gallery_Id)/100
   Gallery_HistoTauUp/=numpnts(Gallery_Id)/100
   Gallery_HistoTauDown/=numpnts(Gallery_Id)/100
   SetScale y,0,Inf,"%" Gallery_HistoTm, Gallery_HistopA, Gallery_HistopC, Gallery_HistopCT, Gallery_Histom, Gallery_Histotp, Gallery_HistoTauUp, Gallery_HistoTauDown
End

Function F_Bu_Show_Gallery_Histograms( CtrlName)
   String CtrlName
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   If (Total_Spikes)
      Make_Histograms()
      If ( WinType( "Histo_Imax") == 0)
            Display Gallery_HistopA as "Imax Histogram"
            SetAxis Bottom 0, 200
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "I.Max\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            DoWindow /C Histo_Imax
      Else
            DoWindow /F Histo_Imax
      EndIf
      If (WinType("Histo_Tm")==0)
            Display Gallery_HistoTm as "Tm Histogram"
            SetAxis Bottom 0, 100
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "T.Half\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_Tm
      Else
            DoWindow /F Histo_Tm
      EndIf
      If (WinType("Histo_Q")==0)
            Display Gallery_HistopC as "Q Histogram"
            SetAxis Bottom 0, 5
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Charge\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_Q
      Else
            DoWindow /F Histo_Q
      EndIf
      If (WinType("Histo_Qter")==0)
            Display Gallery_HistopCT as "Q^1/3 Histogram"
            SetAxis Bottom 0, 2
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Charge^1/3\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_Qter
      Else
            DoWindow /F Histo_Qter
      EndIf
      If (WinType("Histo_m")==0)
            Display Gallery_Histom as "m Histogram"
            SetAxis Bottom 0, 40
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Slope 25-75%\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_m
      Else
            DoWindow /F Histo_m
      EndIf
      If (WinType("Histo_tp")==0)
            Display Gallery_Histotp as "tp Histogram"
            SetAxis Bottom 0, 30
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Time to peak\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_tp
      Else
            DoWindow /F Histo_tp
      EndIf
      If (WinType("Histo_TauUp")==0)
            Display Gallery_HistoTauUp as "Tau Histogram"
            SetAxis Bottom 0, 40
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Tau\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_TauUp
      Else
            DoWindow /F Histo_TauUp
      EndIf
      If (WinType("Histo_TauDown")==0)
            Display Gallery_HistoTauDown as "Tau' Histogram"
            SetAxis Bottom 0, 120
            ModifyGraph mode=5
            ModifyGraph hbFill=3
            TextBox/F=0/b=1 "Tau'\rSpikes:"+num2istr(numpnts(Gallery_XMax))
            Dowindow /C Histo_TauDown
      Else
            DoWindow /F Histo_TauDown
      EndIf
      Execute "TileWindows /W=(140,20,550,480) Histo_Imax, Histo_Tm,Histo_Q, Histo_Qter, Histo_m, Histo_tp, Histo_TauUp, Histo_TauDown"
      DoWindow /F Gallery_Main_Panel
   Else
      DoAlert 0, "No spikes in this gallery."
   EndIf
End

Function F_Bu_Show_Gallery_Layout(CtrlName)
   String CtrlName
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   If (Total_Spikes)
      F_Bu_Show_Gallery_Histograms(" ")
      If ( WinType("Layout_Gallery_Graph") == 0)
            Execute "Layout_Gallery_Graph()"
      EndIf
      DoWindow /F Layout_Gallery_Graph
      DoWindow /F Gallery_Main_Panel
   Else
      DoAlert 0, "No spikes in this gallery."
   EndIf
End

Function F_Bu_Close_Gallery_Layout(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Layout_Gallery_Graph
End

Window Layout_Gallery_Graph() : Layout
	PauseUpdate; Silent 1		// building window...
	Layout/C=1/W=(140.25,53,532.5,496.25) Histo_Imax(74.25,111.75,222,325.5)/O=1/F=0 as "Histograms"
	Append Histo_Tm(222.75,111.75,370.5,325.5)/O=1/F=0,Histo_Q(372.75,111.75,520.5,325.5)/O=1/F=0
	Append Histo_Qter(74.25,332.25,222,546)/O=1/F=0,Histo_m(222.75,332.25,370.5,546)/O=1/F=0
	Append Histo_tp(371.25,332.25,519,546)/O=1/F=0,Histo_TauUp(74.25,551.25,222,765)/O=1/F=0
	Append Histo_TauDown(222.75,551.25,370.5,765)/O=1/F=0
	TextBox/N=text0/A=LB/X=32.72/Y=95.06 "Press over {A} and  put on here TEXT "
	ModifyLayout mag=0.5, units=0
EndMacro

Function F_Bu_Show_Gallery_Table( CtrlName)
   String CtrlName
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   If (Total_Spikes)
      If ( WinType("Gallery_Table") == 0)
            Execute "Gallery_Table()"
      EndIf
      DoWindow /F Gallery_Table
      DoWindow /F Gallery_Main_Panel
   Else
      DoAlert 0, "No spikes in this gallery."
   EndIf
End

Function F_Bu_Close_Gallery_Table( CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Gallery_Table
End

Window Gallery_Table() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(126,44,613.5,357.5) Gallery_Imax,Gallery_Q,Gallery_Qter,Gallery_Tm,Gallery_m as "Gallery Data"
	AppendToTable Gallery_tp,Gallery_TauUp,Gallery_TauDown,Gallery_Id,Gallery_Cell
	ModifyTable width(Point)=23,title(Point)="Spk",size(Gallery_Imax)=9,width(Gallery_Imax)=42
	ModifyTable title(Gallery_Imax)="Imax",size(Gallery_Q)=9,width(Gallery_Q)=51,title(Gallery_Q)="Charge"
	ModifyTable size(Gallery_Qter)=9,width(Gallery_Qter)=51,title(Gallery_Qter)="Charge^1/3"
	ModifyTable size(Gallery_Tm)=9,width(Gallery_Tm)=45,title(Gallery_Tm)="T.Half",size(Gallery_m)=9
	ModifyTable width(Gallery_m)=51,title(Gallery_m)="M 25-75%",size(Gallery_tp)=9,width(Gallery_tp)=47
	ModifyTable title(Gallery_tp)="T.Peak",size(Gallery_TauUp)=9,width(Gallery_TauUp)=47
	ModifyTable title(Gallery_TauUp)="Tau",size(Gallery_TauDown)=9,width(Gallery_TauDown)=47
	ModifyTable title(Gallery_TauDown)="Tau'",size(Gallery_Id)=9,alignment(Gallery_Id)=1
	ModifyTable width(Gallery_Id)=51,title(Gallery_Id)="Id.Spike",size(Gallery_Cell)=9
	ModifyTable width(Gallery_Cell)=20,title(Gallery_Cell)="Cell"
EndMacro

Window Gallery_Spike_Graph() : Graph
   PauseUpdate; Silent 1      // building window...
   Display /W=(131,69,637,430) Spike,Basal as "Spike 0    Gallery: 0 - 170"
   ModifyGraph rgb(Basal)=(1,26214,0)
   ModifyGraph axOffset(bottom)=0.416667
   SetAxis left 1.57107388629246e-11,1.96661523871322e-11
   Tag/N=text0/F=0/B=1/A=LC/X=6.59/Y=0.00 Spike, 0.129249999999999998, "Max"
   Tag/N=text1/F=0/B=1/A=RB/X=-5.00 Spike, 0.1, "Start"
   Tag/N=text2/F=0/B=1/A=MB/X=0.00/Y=13.68 Spike, 0.529499999999999992, "End"
   Textbox/N=text3/F=0/B=1/X=-3.55/Y=-1.43 "Imax=3.2364 pA.\rQ=0.21643 pC.\r t\\B1/2\\M= 44.059 ms"
   AppendText "m\\B25-75\\M= 0.31523 nA/s.\r t\\Bp\\M= 14.448 ms\rExp01/#0  Cell: 0"
   ControlBar 25
   Button Bu_Go_Spike_Display,pos={54,2},size={20,20},proc=F_Bu_Go_Spike_Display,title=">"
   Button Bu_Go_Spike_Display,help={"Display the spike whose number is selected."}
   SetVariable Set_Spike_To_Display,pos={82,4},size={50,16},title=" ",font="Arial"
   SetVariable Set_Spike_To_Display,limits={0,Inf,1},value= Spike_To_Display
   Button Bu_Back_Spike_Display,pos={168,2},size={40,20},proc=F_Bu_Back_Spike_Display,title="<<"
   Button Bu_Back_Spike_Display,help={"Display previous spike."}
   Button Bu_Next_Spike_Display,pos={222,2},size={40,20},proc=F_Bu_Next_Spike_Display,title=">>"
   Button Bu_Next_Spike_Display,help={"Display next spike."}
   Button Bu_Close_Spike_Gallery,pos={369,2},size={40,20},proc=F_Bu_Close_Spike_Display,title="Close"
   Button Bu_Remove_Spike_Gallery,pos={280,2},size={55,20},title="Remove", proc=F_Bu_Remove_Spike_Gallery
   SetDrawLayer UserFront
   SetDrawEnv xcoord= abs,ycoord= abs,linefgc= (48059,48059,48059),linebgc= (48059,48059,48059),fillfgc= (39321,39321,39321)
   DrawRect 506,-29,-2,0
EndMacro

Function F_Bu_Remove_Spike_Gallery(CtrlName)
   String CtrlName
   NVar Current_Spike_Display = Current_Spike_Display
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   ControlInfo /W=Gallery_Main_Panel Check_Cell
   If (V_Value)
      DoAlert 1, "You have to disable the Cell option before removing spikes. Disable now?"
      If (V_Flag == 1)
         CheckBox Check_Cell, Value = 0, Win = Gallery_Main_Panel
         F_Check_Cell ("", 0)
      EndIf
   EndIf
   ControlInfo /W=Gallery_Main_Panel Check_Cell
   If (! V_Value) //If the check has been disabled with the previous V_Flag or if it was disabled before click in remove...
      DeletePoints Current_Spike_Display,1, Gallery_Id, Gallery_Cell, Gallery_tp, Gallery_TauUp, Gallery_TauDown, Gallery_m, Gallery_Tm 
      DeletePoints Current_Spike_Display,1, Gallery_Qter, Gallery_Q, Gallery_Imax
      DeletePoints Current_Spike_Display,1, Gallery_XMax, Gallery_Begin, Gallery_Final
      Total_Spikes -= 1
      If (Total_Spikes)
         If ( Current_Spike_Display == Total_Spikes)
            Current_Spike_Display -= 1
         EndIf
         F_Bu_Show_Spike_Display(" ")
         Print "Spikes in gallery: ", NumPnts(Gallery_Id)
      Else
         DoAlert 0, "There are no spikes in this gallery."
         F_Bu_Close_Spike_Display("")
      EndIf
   EndIf
End

Function F_Bu_Close_Spike_Display(CtrlName)
   String CtrlName
   PauseUpdate; Silent 1
   DoWindow /K Gallery_Spike_Graph
   KillVariables /Z Current_Spike_Display, Spike_To_Display
   KillWaves /Z Spike, Basal
End

Function F_Bu_Go_Spike_Display(CtrlName)
   String CtrlName
   // Globals
   NVar Spike_To_Display = Spike_To_Display
   NVar Current_Spike_Display = Current_Spike_Display
   Wave Gallery_XMax = Gallery_XMax
   PauseUpdate; Silent 1
   If (( Spike_To_Display >= 0) %& ( Spike_To_Display < NumPnts(Gallery_XMax)))
      Current_Spike_Display = Spike_To_Display
      F_Bu_Show_Spike_Display(" ")
   Else
      DoAlert 0, "Number of spike must be between 0 and " + Num2Str(NumPnts(Gallery_XMax) - 1)
   EndIf
End

Function F_Bu_Back_Spike_Display(CtrlName)
   String CtrlName
   // Globals
   NVar Current_Spike_Display = Current_Spike_Display
   PauseUpdate; Silent 1
   If (Current_Spike_Display > 0)
      Current_Spike_Display -= 1
      F_Bu_Show_Spike_Display(" ")
   Else
      DoAlert 0, "This is the first spike."
   EndIf
End

Function F_Bu_Next_Spike_Display(CtrlName)
   String CtrlName
   // Globals
   NVar Current_Spike_Display = Current_Spike_Display
   PauseUpdate; Silent 1
   If (Current_Spike_Display < (NumPnts(Gallery_XMax) - 1))
      Current_Spike_Display += 1
      F_Bu_Show_Spike_Display(" ")
   Else
      DoAlert 0, "This is the last spike."
   EndIf
End

Function F_Bu_Show_Spike_Display( CtrlName)
   String CtrlName
   // Globals
   Wave Gallery_Spk = Gallery_Spk
   Wave Gallery_XMax = Gallery_XMax
   Wave Gallery_Begin = Gallery_Begin
   Wave Gallery_Final = Gallery_Final
   Wave Gallery_Imax = Gallery_Imax
   Wave Gallery_Q = Gallery_Q
   Wave Gallery_Tm = Gallery_Tm
   Wave Gallery_m = Gallery_m
   Wave Gallery_tp = Gallery_tp
   Wave Gallery_TauUp = Gallery_TauUp
   Wave Gallery_TauDown = Gallery_TauDown
   Wave Gallery_Cell = Gallery_Cell
   Wave /T Gallery_Id = Gallery_Id
   NVar Total_Spikes = Total_Spikes
   PauseUpdate; Silent 1
   If (Total_Spikes)
      Make /O /N=0 Spike
      Make /O /N=2 Basal
      F_Bu_Close_Gallery_Layout("")
      F_Bu_Close_Gallery_Histograms("")
      If (WinType("Gallery_Spike_Graph") == 0)
         Variable /G Spike_To_Display = 0
         Variable /G Current_Spike_Display = 0
         Execute "Gallery_Spike_Graph()"
      EndIf
      NVar Current_Spike_Display = Current_Spike_Display
      DoWindow /F Gallery_Spike_Graph
      Duplicate /O /R=(Gallery_Begin(Current_Spike_Display)-0.1, Gallery_Final(Current_Spike_Display)+0.4) Gallery_Spk Spike
      SetScale/I x,Gallery_Begin[Current_Spike_Display], Gallery_Final[Current_Spike_Display],"s", basal
      basal[0]=Gallery_Spk(Gallery_Begin[Current_Spike_Display])
      basal[1]=Gallery_Spk(Gallery_Final[Current_Spike_Display])
      DoWindow /T Gallery_Spike_Graph "Spike " + Num2Str(Current_Spike_Display) + "       Gallery: 0 - " + Num2Str(NumPnts(Gallery_Id)-1)
      Tag /C /N=text0 /F=0/B=1/A=LC/X=6.59/Y=0.00 Spike, Gallery_XMax[Current_Spike_Display],"Max"
      Tag /C /N=text1 /F=0/B=1/A=RB/X=-5.00 Spike, LeftX(Spike)+0.1, "Start"
      Tag /C /N=text2 /F=0/B=1/A=MB/X=0.00/Y=13.68 Spike, RightX(Spike)-0.4, "End"
      CtrlName = "Imax="+num2str(Gallery_Imax[Current_Spike_Display])+" pA\rQ="+num2str(Gallery_Q[Current_Spike_Display])
      CtrlName += " pC\r t\\B1/2\\M= " + num2str(Gallery_Tm[Current_Spike_Display])+" ms\rm\\B25-75\\M= "
      CtrlName += num2str(Gallery_m[Current_Spike_Display])+" nA/s\r t\\Bp\\M= "+num2str(Gallery_tp[Current_Spike_Display])+" ms\r"
      CtrlName += "Tau= " + num2str(Gallery_TauUp[Current_Spike_Display]) + " ms\r Tau'= "+num2str(Gallery_TauDown[Current_Spike_Display])+" ms\r"
      CtrlName += Gallery_Id[Current_Spike_Display] + "  Cell: " +Num2Str(Gallery_Cell[Current_Spike_Display])
      TextBox /C/N=text3/F=0/B=1 CtrlName
      WaveStats /Q /R=(Gallery_Begin(Current_Spike_Display), Gallery_Final(Current_Spike_Display)) Spike
      SetAxis left V_Min-(Gallery_Imax(Current_Spike_Display)*0.05e-12) ,V_Max
   Else
      DoAlert 0, "No spikes in this gallery."
   EndIf
End

Function Load_Exp_Gallery()
   // Locals
   Variable Load_Correct = 0  // It is used to indicate if the experiment has been loaded correctly(1) or with error (0).
   // Globals
   SVar Exp_Folder = Exp_Folder
   SVar Exp_Name = Exp_Name
   PauseUpdate; Silent 1
   If ( StrLen( Exp_Folder))
      If ( CmpStr( Exp_Folder[StrLen(Exp_Folder) - 1], ":" ) )
         Exp_Folder = Exp_Folder + ":"
      EndIf
      // Checking if experiment folder is right.
      KillPath /Z Exp_Folder_Path
      NewPath  /Z  /O  /Q  Exp_Folder_Path  Exp_Folder
      PathInfo Exp_Folder_Path
      If ( V_Flag )
         ControlInfo /W=Gallery_Load_Panel Check_Waves
         If ( V_Value)
            Load_Correct = Load_Waves_Exp(Exp_Name, Exp_Folder)  // No load errors = 1; with load errors = 0
         Else
            ControlInfo /W=Gallery_Load_Panel Check_Exp
            If ( V_Value)
               If (! Find_File( Exp_Name, Exp_Folder))
                  NewPath /O  /Q   Exp_Folder_Path   Exp_Folder
                  LoadData /O /Q /P=Exp_Folder_Path /L=1 Exp_Name
                  Load_Correct = 1
               Else  // If extension has not been typed...
                  If (! Find_File( Exp_Name + ".pxp", Exp_Folder))
                     NewPath /O  /Q   Exp_Folder_Path   Exp_Folder
                     LoadData /O /Q /P=Exp_Folder_Path /L=1 Exp_Name+".pxp"
                     Load_Correct = 1
                  Else
                     DoAlert 0, "Error!  Experiment " + Exp_Name + " does not exist in folder " + Exp_Folder
                  EndIf
               EndIf
            Else
               DoAlert 0, "Please! The check Waves or Experiment must be clicked."
            EndIf
         EndIf
      Else
         DoAlert 0, "Error!  Experiment folder wrong..."
      EndIf
      KillPath /Z Exp_Folder_Path
   Else
      DoAlert   0, "Error!  Experiment folder is blank..."
   Endif
   KillPath /Z Exp_Folder_Path
   //The parameters of the added spikes are recalculated, because m and tp may have been calculated
   //with spikes20 (or previous version) and then they are expressed in A/s and s, instead of nA/s and ms.
   If (Load_Correct == 1)
      Parameters_Of_Spikes(NumPnts(X_Peak))
   EndIf
   Return( Load_Correct)
End

Function Kill_Windows_Gallery()
   PauseUpdate; Silent 1
   DoWindow /K Gallery_Main_Panel
   DoWindow /K ChoosePanel
   F_Bu_Close_All_Gallery_Graphs("")
   F_Close_All_Cell_Graphs()
End
