function Handle_Export_Controls(PPA)

  if PPA.Is_Visible(PPA.ExportGUI)
    hasVol = ~isempty(PPA.procVol);

    PPA.ExportGUI.ExpVolMat.Enable = hasVol;
    % TODO VTK export function needs to be implemented
    % PPA.ExportGUI.ExpVolVtk.Enable = hasVol;
    PPA.ExportGUI.ExpVolWrk.Enable = hasVol;

    hasMap = ~isempty(PPA.procProj);
    PPA.ExportGUI.ExpImMat.Enable = hasMap;
    PPA.ExportGUI.ExpWrkIm.Enable = hasMap;

    PPA.ExportGUI.ExpImMat.Enable = hasMap;

    PPA.ExportGUI.ExpOverview.Enable = hasMap;
    PPA.ExportGUI.ExpOverJpg.Enable = hasMap;
    PPA.ExportGUI.ExpOverPdf.Enable = hasMap;
    PPA.ExportGUI.ExpOverPng.Enable = hasMap;
    PPA.ExportGUI.ExpOverTiff.Enable = hasMap;

    PPA.ExportGUI.ExpNative.Enable = hasMap;
    PPA.ExportGUI.ExpNativeJpg.Enable = hasMap;
    PPA.ExportGUI.ExpNativeTiff.Enable = hasMap;
    PPA.ExportGUI.ExpNativePng.Enable = hasMap;

    hasDeptMap = ~isempty(PPA.depthImage);
    PPA.ExportGUI.ExpDepthMap.Enable = hasDeptMap;

    PPA.ExportGUI.StartBatchProcessButton.Enable = (hasMap || hasVol);
  end

end