classdef PostProBackEnd < BaseClass
  % PostProBackEnd Post processing and visualization of 2d and 3d datasets
  %   This is the backend to the PostPro app (PostPro.mlapp)
  %   PostPro defines the GUI and controlls callbacks etc, but PostProBackEnd is
  %   doing the actual work...
  %
  %   Accepts the follwoing files / formats
  %   - custom .mat files with Map or Vol data
  %       - FIXME add specs
  %   - matfile containing VolumetricDataset (https://github.com/razanskylab/MVolume)
  %   - files to be supported in the future:
  %     - tiff stacks
  %     - have user select dataset
  %
  %

  properties
    doBatchProcessing(1, 1) {mustBeNumericOrLogical, mustBeFinite} = 0; % flag which causes automatic processing and blocking of
    % dialogs etc
    processingEnabled = false; % if true, enables "automatic" processing cascade

    isVolData = 0; % true when 3D data was loaded, which has a big influence
    % on the  overall processing we are doing
    fileType(1, 1) {mustBeNumeric, mustBeFinite} = 0; 
    % 0 = invalid file, 1 = mat file, 2 = mVolume file, 3 = tiff stack, 4 = image file

    % sub-classes for processing
    FRFilt = Frangi_Filter();
    FreqFilt = FilterClass();
    IMF = Image_Filter.empty; % is filled/reset during Apply_Image_Processing

    % file handling
    filePath = 'C:\Data';
    exportPath = [];
    batchPath = []; % folder to search for mat files for batch processing
    % file info
    MatFileVars; %  who('-file', PPA.filePath);
    MatFile; %      matfile(PPA.filePath);
    FileContent; %  whos(PPA.MatFile);

    % x,y,z - original position and depth vectors as loaded from the mat file
    % these are only changed during load, the vectors used for plotting are depended
    x(1, :) {mustBeNumeric, mustBeFinite};
    y(1, :) {mustBeNumeric, mustBeFinite};
    z(1, :) {mustBeNumeric, mustBeFinite};

    dt(1, :) {mustBeNumeric, mustBeFinite} = 250;
    df(1, :) {mustBeNumeric, mustBeFinite};

    % stores text shown in last tab, for debugging, also exported alongside
    % images
    debugText;

    % used to draw lines on volume projection
    lineCtr(1, 2) {mustBeNumeric, mustBeFinite};

    % used for lines in volume data slice picker
    HorLine;
    VertLine;

    % properties used to store depth map data used for exporting depth map
    maskFrontCMap(:, :) {mustBeNumeric, mustBeFinite};
    zLabels;
    tickLocations;
    exportCounter(1, 1) {mustBeNumeric, mustBeFinite};

    % frangi scales are either entered manually or calculated, thus not a dependend variable
    scalesToUse;
  end

  properties (AbortSet)
    % NOTE AbortSet:
    % https://ch.mathworks.com/help/matlab/matlab_oop/set-events-when-value-does-not-change.html
    % don't call set function when Property Value Is Unchanged
    depthInfo(:, :) single {mustBeNumeric, mustBeFinite};
    % peak location for each pixel
    rawDepthInfo(:, :) single {mustBeNumeric, mustBeFinite};
    % raw version of depth info, to store orig when only loading 2d data...
    depthImage(:, :, 3) {mustBeNumeric, mustBeFinite};
    % image of the depth map
    % with transparency etc. applied, i.e. ready to be used
    % define volumes (in order of processing)
    rawVol(:, :, :) single {mustBeNumeric, mustBeFinite}; % raw untouched vol
    dsVol(:, :, :) single {mustBeNumeric, mustBeFinite}; % downsampled volume...
    cropVol(:, :, :) single {mustBeNumeric, mustBeFinite}; % cropped volume
    freqVol(:, :, :) single {mustBeNumeric, mustBeFinite}; % freq. filtered volume
    filtVol(:, :, :) single {mustBeNumeric, mustBeFinite}; % median filtered volume
    procVol(:, :, :) single {mustBeNumeric, mustBeFinite};
    % processed volume, the one we get projections from
    % NOTE all volumes are updated if any of the "previous" volumes is changed
    % in the end, they are all dependet variables, but recalculating everything

    procVolProj(:, :) single {mustBeNumeric, mustBeFinite}; % untouched proj. from procVol
    xzProc(:, :) single {mustBeNumeric, mustBeFinite};
    yzProc(:, :) single {mustBeNumeric, mustBeFinite};
    xzSlice(:, :) single {mustBeNumeric, mustBeFinite};
    yzSlice(:, :) single {mustBeNumeric, mustBeFinite};

    % final processed image <----
    procProj(:, :) single {mustBeNumeric, mustBeFinite};

    % frangi filtering related images ------------------------------------------
    % MAP before frangi filtering but after applying all other filters
    preFrangi(:, :) single {mustBeNumeric, mustBeFinite};
    % MAP after frangi filtering and after applying all other filters
    frangiFilt(:, :) single {mustBeNumeric, mustBeFinite};
    % MAP of frangi scales
    frangiScales(:, :, :) single {mustBeNumeric, mustBeFinite};
    % seperate frangi scales
    frangiCombo(:, :) single {mustBeNumeric, mustBeFinite};
    % combination of frangiFilt & procProj, see Update_Frangi_Combo

  end

  % plot and other handles
  properties
    % handle to GUI app
    GUI;
    LoadGUI; % handle to app for loading raw files
    ProgBar;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties (Dependent = true)
    fileName;
    folderPath;
    fileExists;
    fileExt; 


    nX; nY; nZ; % size of procVol
    zPlot; xPlot; yPlot;
    dR; % spatial resolution = pixel size
    nXF; nYF; nZF; % actual size of interpolated/downsampled volume / image
    % re-sampled versions of orig x and y vectors
    cropRange(1, :) {mustBeNumeric, mustBeFinite};
    centers(1, 3) {mustBeNumeric, mustBeFinite};
    % calculated actual frangi scales based on start / end / nScales

    % volume processing settings, taken from GUI -------------------------------
    doVolCropping(1, 1) {mustBeNumeric, mustBeFinite};
    doVolDownSampling(1, 1) {mustBeNumeric, mustBeFinite};
    volSplFactor(1, 2) {mustBeNumeric, mustBeFinite};
    doVolMedianFilter(1, 1) {mustBeNumeric, mustBeFinite};
    volMedFilt(1, 3) {mustBeNumeric, mustBeFinite};
    doVolPolarity(1, 1) {mustBeNumeric, mustBeFinite};
    volPolarity(1, 1) {mustBeNumeric, mustBeFinite};

    % image processing settings, taken from GUI --------------------------------
    doImSpotRemoval(1, 1) {mustBeNumeric, mustBeFinite};
    imInterpFct(1, 1) {mustBeNumeric, mustBeFinite};
    doImInterpolate(1, 1) {mustBeNumeric, mustBeFinite};
    imSpotLevel(1, 1) {mustBeNumeric, mustBeFinite};
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties (Constant)
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    % constructor, called when class is created
    function PPA = PostProBackEnd()
    end

    function Start_Wait_Bar(PPA, waitBarText)
      % start Indeterminate progress bar
      PPA.ProgBar = uiprogressdlg(PPA.GUI.UIFigure, 'Title', waitBarText, ...
        'Indeterminate', 'on');
      PPA.Update_Status(waitBarText);
      drawnow();
    end

    function Stop_Wait_Bar(PPA)
      close(PPA.ProgBar);
    end

    function Update_Status(PPA, statusText)

      if nargin == 1
        statusText = sprintf(repmat('-', 1, 66));
      end

      PPA.GUI.StatusText.Value = sprintf('[Status] %s', statusText);
      PPA.GUI.DebugText.Items = [PPA.GUI.DebugText.Items statusText];
      PPA.GUI.DebugText.scroll('bottom');
    end

    function Update_Size_Info(PPA)
      PPA.GUI.nX.Value = PPA.nXF;
      PPA.GUI.nY.Value = PPA.nYF;
      PPA.GUI.nZ.Value = PPA.nZF;
      PPA.GUI.dR.Value = PPA.dR;
    end

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Static)

    function newFiltValue = Get_Allowed_Med_Filt_Coeff(origFiltValue)
      % get allowed median filter value (must be odd and > 1)
      newFiltValue = round(origFiltValue); % just to be safe

      if (newFiltValue > 2) &&~rem(newFiltValue, 2)
        newFiltValue = newFiltValue - 1;
      elseif newFiltValue < 1
        newFiltValue = 1;
      end

    end

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods % SET / GET methods
    % raw untouched vol
    function fileName = get.fileName(PPA)
      if ~isempty(PPA.filePath)
        [~, fileName, ext] = fileparts(PPA.filePath);
        fileName = [fileName ext]; % we also want the extention
      else
        fileName = [];
      end
    end

    function folderPath = get.folderPath(PPA)
      if ~isempty(PPA.filePath)
        folderPath = fileparts(PPA.filePath);
      else
        folderPath = [];
      end
    end

    function fileExists = get.fileExists(PPA)
      if ~isempty(PPA.filePath)
        fileExists = (exist(PPA.filePath, 'file') == 2);
      else
        fileExists = false;
      end
    end

    function fileExt = get.fileExt(PPA)
      if ~isempty(PPA.filePath)
        [~, ~, fileExt] = fileparts(PPA.filePath);
      else
        fileExt = [];
      end
    end

    % SET functions for all volumes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % NOTE all volumes are updated if any of the "previous" volumes is changed
    % in the end, they are all dependet variables, but recal everything every
    % time is too time consuming
    % suppress the get methods should not acces other prop. warnings...
    %#ok<*MCSUP>

    % raw untouched vol
    function set.rawVol(PPA, newRawVol)
      PPA.rawVol = newRawVol;

      if ~isempty(newRawVol) && PPA.processingEnabled
        PPA.Down_Sample_Volume();
      end

    end

    % downsampled volume...
    function set.dsVol(PPA, newDsVol)
      PPA.dsVol = newDsVol;
      PPA.Crop_Volume(); % sets cropVol
    end

    % cropped volume
    function set.cropVol(PPA, newCropVol)
      PPA.cropVol = newCropVol;
      PPA.Freq_Filt_Volume(); % sets freqVol
    end

    % freq. filtered volume
    function set.freqVol(PPA, newFreqVol)
      PPA.freqVol = newFreqVol;
      PPA.Med_Filt_Volume(); % sets filtVol
    end

    % median filtered volume
    function set.filtVol(PPA, newFiltVol)
      PPA.filtVol = newFiltVol;
      PPA.Apply_Polarity_Volume(); % sets procVol
    end

    % processed volume, the one we get projections from
    % NOTE this is the final volume we get the depth information from as well
    function set.procVol(PPA, newProcVol)
      PPA.procVol = newProcVol;
      % FIXME convert depth info to actual mm
      [~, depthMap] = max(newProcVol, [], 3);
      depthMap = imrotate(depthMap, -90);
      depthMap = PPA.z(depthMap); % replace idx value with actual depth in mm
      PPA.depthInfo = single(depthMap);
      PPA.rawDepthInfo = single(depthMap);
      PPA.procVolProj = PPA.Get_Volume_Projections(newProcVol, 3); %% xy projection, i.e. normal MIP
      PPA.xzProc = PPA.Get_Volume_Projections(newProcVol, 2);
      PPA.yzProc = PPA.Get_Volume_Projections(newProcVol, 1);
      PPA.Update_Slice_Lines();
      % when we are done with all of this, we stop the waitbar...
      PPA.Stop_Wait_Bar();
    end

    % SET functions for all projections / MIPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % final processed image
    % NOTE this is what we show on "front" panel, in the Image processing and
    % also the frangi filter panel
    % this is also the basis for the depth map and what we export
    function set.procProj(PPA, newProj)
      PPA.procProj = newProj;
      PPA.Update_Image_Panel(PPA.GUI.FiltDisp, newProj, 3);
      % PPA.Update_Image_Panel(PPA.GUI.imFiltDisp, newProj,3);
      plotAx = PPA.GUI.imFiltDisp.Children(1);
      set(plotAx, 'cdata', newProj);
      PPA.Update_Depth_Map(PPA.GUI.imDepthDisp);
      PPA.Stop_Wait_Bar();
    end

    % untouched proj. from procVol NOTE this is the one we set when we only load
    % map data, as we use the "raw" map, i.e. the one without any contrast
    % enhancements etc...
    function set.procVolProj(PPA, newProj)
      PPA.procVolProj = newProj;

      if ~isempty(PPA.procVolProj) && PPA.processingEnabled
        PPA.Apply_Image_Processing(); % this sets a new procProj
      end

    end

    %---------------------------------------------------------------
    function set.xzProc(PPA, newProj)
      PPA.xzProc = newProj;

      if ~isempty(PPA.xzProc)
        newProj = PPA.Apply_Image_Processing_Simple(newProj);
        PPA.Update_Image_Panel(PPA.GUI.xzProjDisp, newProj, 2);
      end

    end

    %---------------------------------------------------------------
    function set.yzProc(PPA, newProj)
      PPA.yzProc = newProj;

      if ~isempty(PPA.yzProc)
        newProj = PPA.Apply_Image_Processing_Simple(newProj);
        PPA.Update_Image_Panel(PPA.GUI.yzProjDisp, newProj, 1);
      end

    end

    %---------------------------------------------------------------
    function set.xzSlice(PPA, newProj)
      PPA.xzSlice = newProj;

      if ~isempty(PPA.xzSlice)
        newProj = PPA.Apply_Image_Processing_Simple(newProj);
        PPA.Update_Image_Panel(PPA.GUI.xzSliceDisp, newProj, 2);
      end

    end

    %---------------------------------------------------------------
    function set.yzSlice(PPA, newProj)
      PPA.yzSlice = newProj;

      if ~isempty(PPA.yzSlice)
        newProj = PPA.Apply_Image_Processing_Simple(newProj);
        PPA.Update_Image_Panel(PPA.GUI.yzSliceDisp, newProj, 1);
      end

    end

    % OTHER set / get functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function nX = get.nX(PPA)
      nX = size(PPA.procVol, 1);
    end

    %---------------------------------------------------------------
    function nY = get.nY(PPA)
      nY = size(PPA.procVol, 2);
    end

    %---------------------------------------------------------------
    function nZ = get.nZ(PPA)
      nZ = size(PPA.procVol, 3);
    end

    %---------------------------------------------------------------
    function zPlot = get.zPlot(PPA)
      % check if we are downsampling in z
      if PPA.doVolDownSampling
        zPlot = PPA.z(1:PPA.volSplFactor(2):end);
      else
        zPlot = PPA.z;
      end

      % cropping ranges do not take into account downsampling
      if PPA.doVolCropping
        zPlot = zPlot(PPA.cropRange);
      end

    end

    %---------------------------------------------------------------
    function cropRange = get.cropRange(PPA)

      if PPA.doVolCropping
        % indicies to be used to get cropped volume after a potential
        % downsampling

        % get "original" start and stop indicies e.g. 50:450
        startIdx = PPA.GUI.zCropLowEdit.Value;
        stopIdx = PPA.GUI.zCropHighEdit.Value;

        % correct for potential volumetric downsampling e.g. 50:450 -> 25:225
        if PPA.doVolDownSampling
          startIdx = ceil(startIdx ./ PPA.volSplFactor(2));
          stopIdx = floor(stopIdx ./ PPA.volSplFactor(2));
        end

        cropRange = startIdx:stopIdx;
      else
        cropRange = 1:PPA.nZ; % nZ is number of samples of proc Volume...
        % thus it takes into account downsampling already...
      end

    end

    %---------------------------------------------------------------
    function xPlot = get.xPlot(PPA)

      if PPA.doVolDownSampling
        xPlot = PPA.x(1:PPA.volSplFactor(1):end);
      else
        xPlot = PPA.x;
      end

    end

    %---------------------------------------------------------------
    function yPlot = get.yPlot(PPA)

      if PPA.doVolDownSampling
        yPlot = PPA.y(1:PPA.volSplFactor(1):end);
      else
        yPlot = PPA.y;
      end

    end

    % volume processing settings, taken from GUI -------------------------------
    function doVolCropping = get.doVolCropping(PPA)
      doVolCropping = PPA.GUI.CropCheck.Value;
    end

    %---------------------------------------------------------------
    function doVolDownSampling = get.doVolDownSampling(PPA)
      doVolDownSampling = PPA.GUI.DwnSplCheck.Value;
    end

    %---------------------------------------------------------------
    function volSplFactor = get.volSplFactor(PPA)
      volSplFactor(1) = PPA.GUI.DwnSplFactorEdit.Value;
      volSplFactor(2) = PPA.GUI.DepthDwnSplFactorEdit.Value;
    end

    %---------------------------------------------------------------
    function volMedFilt = get.volMedFilt(PPA)
      volMedFilt(1) = PPA.GUI.MedFiltX.Value;
      volMedFilt(2) = PPA.GUI.MedFiltY.Value;
      volMedFilt(3) = PPA.GUI.MedFiltZ.Value;
    end

    %---------------------------------------------------------------
    function doVolPolarity = get.doVolPolarity(PPA)
      doVolPolarity = PPA.GUI.PolarityCheck.Value;
    end

    %---------------------------------------------------------------
    function volPolarity = get.volPolarity(PPA)

      switch PPA.GUI.PolarityDropDown.Value
        case 'Positive'
          volPolarity = 1;
        case 'Negative'
          volPolarity = 3;
        case 'Absolute'
          volPolarity = 4;
        case 'Envelope'
          volPolarity = 2;
      end

    end

    %---------------------------------------------------------------
    function doVolMedianFilter = get.doVolMedianFilter(PPA)
      doVolMedianFilter = PPA.GUI.MedFiltCheck.Value;
    end

    %---------------------------------------------------------------
    function centers = get.centers(PPA)
      centers(1, 1) = mean(minmax(PPA.xPlot));
      centers(1, 2) = mean(minmax(PPA.yPlot));

      if ~isempty(PPA.zPlot)
        centers(1, 3) = mean(minmax(PPA.zPlot));
      else
        centers(1, 3) = 0;
      end

    end

    %---------------------------------------------------------------
    function nXF = get.nXF(PPA)
      nXF = size(PPA.procProj, 1);
    end

    function nYF = get.nYF(PPA)
      nYF = size(PPA.procProj, 2);
    end

    function nZF = get.nZF(PPA)
      nZF = size(PPA.procVol, 3);
    end

    function dR = get.dR(PPA)
      dR = mean(diff(PPA.x)) * 1e3; % in micron

      if PPA.doVolDownSampling
        dR = dR .* PPA.volSplFactor(1);
      end

      if PPA.doImInterpolate
        dR = dR ./ PPA.imInterpFct;
      end

    end

    % Image processing settings from GUI ---------------------------------------
    function doImSpotRemoval = get.doImSpotRemoval(PPA)
      doImSpotRemoval = PPA.GUI.SpotRemovalCheckBox.Value;
    end

    function imSpotLevel = get.imSpotLevel(PPA)
      imSpotLevel = PPA.GUI.imSpotRem.Value;
    end

    function doImInterpolate = get.doImInterpolate(PPA)
      doImInterpolate = PPA.GUI.InterpolateCheckBox.Value;
    end

    function imInterpFct = get.imInterpFct(PPA)
      imInterpFct = PPA.GUI.imInterpFct.Value;
    end

    %---------------------------------------------------------------
    % function frangiFilt = get.frangiFilt(PPA)
    %   % make sure to calculate frangi fitlered image...
    %   if isempty(PPA.frangiFilt)
    %     PPA.Apply_Frangi();
    %   else
    %     frangiFilt = PPA.frangiFilt;
    %   end

    % end

  end

end
