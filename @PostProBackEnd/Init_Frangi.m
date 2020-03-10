function Init_Frangi(PPA)
  % Init_Frangi()
  % called before opening Frangi GUI make sure it's up to date...
  % specific volume currently handeled by PPA
  try

    % check if we have a Frangi GUI already...
    PPA.FraFilt = Frangi_Filter();
    PPA.FraFilt.raw = PPA.procProj;
    PPA.FraFilt.x = PPA.xPlotIm;
    PPA.FraFilt.y = PPA.yPlotIm;

    if isempty(PPA.FraFilt.GUI)
      PPA.FraFilt.Open_GUI();
    end

  catch ME
    PPA.Stop_Wait_Bar();
    rethrow(ME);
  end

end
