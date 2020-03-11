function Setup_Vessel_Figures(PPA)
  progressbar('Setting up vessel figures');
  overlayAlpha = 0.5;

  % get to colorbar to use
  if isempty(PPA.MasterGUI)
    VesselFigs.cbar = gray(256);
  else
    VesselFigs.cbar = PPA.MasterGUI.cBars.Value;
  end

  % setup processing figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fHandle = figure('Name', 'Vessel Processing');
  fHandle.NumberTitle = 'off';
  fHandle.ToolBar = 'figure';
  fHandle.Colormap = VesselFigs.cbar;

  % make figure fill ~ half the screen and be next to GUI ---------------------
  set(fHandle, 'Units', 'Normalized', 'OuterPosition', [0 0 0.4 0.7]);
  % move figure over a little to the right of the vessel GUI
  fHandle.Units = 'pixels';
  % move figure next to the GUI
  fHandle.OuterPosition(1) = PPA.VesselGUI.UIFigure.Position(1) + ...
    PPA.VesselGUI.UIFigure.Position(3) - 5;
  % bottom pos = bot of GUI + height of GUI - height of figure
  fHandle.OuterPosition(2) = PPA.VesselGUI.UIFigure.Position(2) + ... 
    PPA.VesselGUI.UIFigure.Position(4) - fHandle.OuterPosition(4) + 30;
  VesselFigs.MainFig = fHandle; 

  % create flow-layout for processing steps to use available space as best as possible
  VesselFigs.TileLayout = tiledlayout('flow');
  VesselFigs.TileLayout.Padding = 'compact'; % remove uneccesary white space...

  % closing the processing figure also closes the GUI and vice-versa
  VesselFigs.MainFig.UserData = PPA.VesselGUI; % need that in Gui_Close_Request callback
  VesselFigs.MainFig.CloseRequestFcn = @Gui_Close_Request;
  progressbar(0.1);

  % setup subplots of processing figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Input Image ----------------------------------------------------------------
  emptyImage = nan(size(PPA.procProj));
  VesselFigs.InPlot = nexttile(VesselFigs.TileLayout);
  VesselFigs.InIm = imagesc(VesselFigs.InPlot,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  title('Input Image');
  progressbar(0.2);

  % Binarized Image ------------------------------------------------------------
  VesselFigs.BinPlot = nexttile(VesselFigs.TileLayout);
  VesselFigs.BinIm = imagesc(VesselFigs.BinPlot,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  title('Binarized Image');
  progressbar(0.3);

  % Cleaned Binarized Image ----------------------------------------------------
  VesselFigs.BinCleanPlot = nexttile(VesselFigs.TileLayout);
  VesselFigs.BinCleanIm = imagesc(VesselFigs.BinCleanPlot, emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  title('Cleaned Binarized Image');
  progressbar(0.4);

  % skeleton image with branches -----------------------------------------------
  VesselFigs.Skeleton = nexttile(VesselFigs.TileLayout);
  VesselFigs.SkeletonImBack = imagesc(VesselFigs.Skeleton,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  hold on;
  VesselFigs.SkeletonImFront = imagesc(VesselFigs.Skeleton, emptyImage);
  VesselFigs.SkeletonScat = scatter(VesselFigs.Skeleton,NaN, NaN);
  VesselFigs.SkeletonScat.LineWidth = 1.0;
  VesselFigs.SkeletonScat.MarkerEdgeAlpha = 0; 
  VesselFigs.SkeletonScat.MarkerFaceColor = Colors.DarkOrange; 
  VesselFigs.SkeletonScat.MarkerFaceAlpha = overlayAlpha; 
  VesselFigs.SkeletonScat.SizeData = 15; 
  hold off;
  title('Skeletonized Image');
  progressbar(0.5);

  % setup results figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fHandle = figure('Name', 'Vessel Analysis Results');
  fHandle.NumberTitle = 'off';
  fHandle.ToolBar = 'figure';
  fHandle.Colormap = VesselFigs.cbar;

  % make figure fill ~ half the screen and be next to GUI ---------------------
  set(fHandle, 'Units', 'Normalized', 'OuterPosition', [0 0 0.4 0.7]);
  % move figure over a little to the right of the vessel GUI
  fHandle.Units = 'pixels';
  % move figure next to the analysis
  fHandle.OuterPosition(1) = VesselFigs.MainFig.OuterPosition(1) + ...
    VesselFigs.MainFig.OuterPosition(3);
  % bottom pos same as the analysis figure as they are  the same size
  fHandle.OuterPosition(2) = VesselFigs.MainFig.OuterPosition(2);
  VesselFigs.ResultsFig = fHandle;

  % create flow-layout for processing steps to use available space as best as possible
  VesselFigs.ResultsTileLayout = tiledlayout(1,2);
  VesselFigs.ResultsTileLayout.Padding = 'compact'; % remove uneccesary white space...

  % closing the processing figure also closes the GUI and vice-versa
  VesselFigs.ResultsFig.UserData = PPA.VesselGUI; % need that in Gui_Close_Request callback
  VesselFigs.ResultsFig.CloseRequestFcn = @Gui_Close_Request;
  progressbar(0.6);

  % spline fitted with branches ------------------------------------------------
  VesselFigs.Spline = nexttile(VesselFigs.ResultsTileLayout);
  VesselFigs.SplineImBack = imagesc(VesselFigs.Spline,emptyImage);
  axis image;
  axis tight;
  axis off; % no need for axis labels in these plots
  % colormap(VesselFigs.cbar);
  hold on;
  VesselFigs.SplineScat = scatter(VesselFigs.Spline,NaN, NaN);
  VesselFigs.SplineScat.LineWidth = 1.0;
  VesselFigs.SplineScat.MarkerEdgeAlpha = 0;
  VesselFigs.SplineScat.MarkerFaceColor = Colors.DarkOrange;
  VesselFigs.SplineScat.MarkerFaceAlpha = overlayAlpha;
  VesselFigs.SplineScat.SizeData = 20;

  VesselFigs.SplineLine = line(VesselFigs.Spline,NaN, NaN);
  VesselFigs.SplineLine.LineStyle = '-';
  VesselFigs.SplineLine.Color = Colors.PureRed;
  VesselFigs.SplineLine.Color(4) = overlayAlpha;
  VesselFigs.SplineLine.LineWidth = 2;

  VesselFigs.LEdgeLines = line(VesselFigs.Spline,NaN, NaN);
  VesselFigs.LEdgeLines.LineStyle = '--';
  VesselFigs.LEdgeLines.Color = Colors.PureRed;
  VesselFigs.LEdgeLines.Color(4) = overlayAlpha;
  VesselFigs.LEdgeLines.LineWidth = 1.5;
  VesselFigs.REdgeLines = line(VesselFigs.Spline,NaN, NaN);
  VesselFigs.REdgeLines.LineStyle = '--';
  VesselFigs.REdgeLines.Color = Colors.PureRed;
  VesselFigs.REdgeLines.Color(4) = overlayAlpha;
  VesselFigs.REdgeLines.LineWidth = 1.5;
  hold off;
  title(VesselFigs.Spline,'Spline Fitted Image');
  legend(VesselFigs.Spline,{'Branch Points', 'Centerlines', 'Edges'});
  progressbar(0.7);

  VesselFigs.DataDisp = nexttile(VesselFigs.ResultsTileLayout);

  % link all the axis of both the processing and the results figures, so
  % that zooming/panning in one affects all the figures
  linkaxes([VesselFigs.Spline, ...
            VesselFigs.InPlot, ...
            VesselFigs.BinPlot, ...
            VesselFigs.BinCleanPlot ...
            VesselFigs.Skeleton ...
            ], 'xy');
  progressbar(0.8);
        
  PPA.VesselFigs = VesselFigs;
  progressbar(1);
end
