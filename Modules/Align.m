function handles = Align(handles)

% Help for the Align module:
% Category: Image Processing
%
% SHORT DESCRIPTION:
% Aligns two or three images relative to each other. Particularly useful to
% align microscopy images acquired from different color channels.
% *************************************************************************
%
% For two or three input images, this module determines the optimal
% alignment among them.  This works whether the images are correlated or
% anti-correlated (bright in one = bright in the other, or bright in one =
% dim in the other). This is useful when the microscope is not perfectly
% calibrated because, for example, proper alignment is necessary for
% primary objects to be helpful to identify secondary objects. The images
% are cropped appropriately according to this alignment, so the final
% images will be smaller than the originals by a few pixels if alignment is
% necessary.
% 
% Settings:
%
% After entering the names of the images to be aligned as well as the 
% aligned image name(s), choose whether to display the image produced by 
% this module by selecting "yes" in the appropriate menu. Lastly, select 
% the method of alignment. There are two choices, one is based on mutual 
% information while the other is based on the cross correlation. When using
% the cross correlation method, the second image should serve as a template
% and be smaller than the first image selected.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Authors:
%   Anne E. Carpenter
%   Thouis Ray Jones
%   In Han Kang
%   Ola Friman
%   Steve Lowe
%   Joo Han Chang
%   Colin Clarke
%   Mike Lamprecht
%   Peter Swire
%   Rodrigo Ipince
%   Vicky Lay
%   Jun Liu
%   Chris Gang
%
% Website: http://www.cellprofiler.org
%
% $Revision$

%%%%%%%%%%%%%%%%%
%%% VARIABLES %%%
%%%%%%%%%%%%%%%%%
drawnow

[CurrentModule, CurrentModuleNum, ModuleName] = CPwhichmodule(handles);

%textVAR01 = What did you call the first image to be aligned? (will be displayed as blue) 
%infotypeVAR01 = imagegroup
Image1Name = char(handles.Settings.VariableValues{CurrentModuleNum,1});
%inputtypeVAR01 = popupmenu

%textVAR02 = What do you want to call the aligned first image?
%defaultVAR02 = AlignedBlue
%infotypeVAR02 = imagegroup indep
AlignedImage1Name = char(handles.Settings.VariableValues{CurrentModuleNum,2});

%textVAR03 = What did you call the second image to be aligned? (will be displayed as green) 
%infotypeVAR03 = imagegroup
Image2Name = char(handles.Settings.VariableValues{CurrentModuleNum,3});
%inputtypeVAR03 = popupmenu

%textVAR04 = What do you want to call the aligned second image?
%defaultVAR04 = AlignedGreen
%infotypeVAR04 = imagegroup indep
AlignedImage2Name = char(handles.Settings.VariableValues{CurrentModuleNum,4});

%textVAR05 = What did you call the third image to be aligned? (will be displayed as red) 
%choiceVAR05 = Do not use
%infotypeVAR05 = imagegroup
Image3Name = char(handles.Settings.VariableValues{CurrentModuleNum,5});
%inputtypeVAR05 = popupmenu

%textVAR06 = What do you want to call the aligned third image?
%defaultVAR06 = Do not use
%infotypeVAR06 = imagegroup indep
AlignedImage3Name = char(handles.Settings.VariableValues{CurrentModuleNum,6});

%textVAR07 = This module calculates the alignment shift and stores it as a measurement. Do you want to actually shift the images and crop them to produce the aligned images? 
%choiceVAR07 = Yes
%choiceVAR07 = No
AdjustImage = char(handles.Settings.VariableValues{CurrentModuleNum,7});
%inputtypeVAR07 = popupmenu

%textVAR08 = Should this module use Mutual Information or Normalized Cross Correlation to align the images?  If using normalized cross correlation, the second image should be the template and smaller than the first.
%choiceVAR08 = Mutual Information
%choiceVAR08 = Normalized Cross Correlation
AlignMethod = char(handles.Settings.VariableValues{CurrentModuleNum,8});
%inputtypeVAR08 = popupmenu


%%%VariableRevisionNumber = 2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRELIMINARY CALCULATIONS & FILE HANDLING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Reads the images.
Image1 = CPretrieveimage(handles,Image1Name,ModuleName,'MustBeGray','CheckScale');

Image2 = CPretrieveimage(handles,Image2Name,ModuleName,'MustBeGray','CheckScale');

%%% Same for Image 3.
if ~strcmp(Image3Name,'Do not use')
    Image3 = CPretrieveimage(handles,Image3Name,ModuleName,'MustBeGray','CheckScale');
end

%%%%%%%%%%%%%%%%%%%%%%
%%% IMAGE ANALYSIS %%%
%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Aligns three input images.
if ~strcmp(Image3Name,'Do not use')
    %%% Aligns 1 and 2 (see subfunctions at the end of the module).
    [sx, sy] = autoalign(Image1, Image2, AlignMethod);
    Temp1 = subim(Image1, sx, sy);
    Temp2 = subim(Image2, -sx, -sy);
    %%% Assumes 3 is stuck to 2.
    Temp3 = subim(Image3, -sx, -sy);
    %%% Aligns 2 and 3.
    [sx2, sy2] = autoalign(Temp2, Temp3, AlignMethod);
    Results = ['(1 vs 2: X ', num2str(sx), ', Y ', num2str(sy), ...
        ') (2 vs 3: X ', num2str(sx2), ', Y ', num2str(sy2),')'];
    if strcmp(AdjustImage,'Yes') == 1
        AlignedImage2 = subim(Temp2, sx2, sy2);
        AlignedImage3 = subim(Temp3, -sx2, -sy2);
        %%% 1 was already aligned with 2.
        AlignedImage1 = subim(Temp1, sx2, sy2);
    end
else %%% Aligns two input images.
    [sx, sy] = autoalign(Image1, Image2, AlignMethod);
    Results = ['(1 vs 2: X ', num2str(sx), ', Y ', num2str(sy),')'];
    if strcmp(AdjustImage,'Yes') == 1
        AlignedImage1 = subim(Image1, sx, sy);
        AlignedImage2 = subim(Image2, -sx, -sy);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% DISPLAY RESULTS %%%
%%%%%%%%%%%%%%%%%%%%%%%
drawnow

%%% Determines the figure number to display in.
ThisModuleFigureNumber = handles.Current.(['FigureNumberForModule',CurrentModule]);
if any(findobj == ThisModuleFigureNumber)
    if strcmp(AdjustImage,'Yes')
        %%% For three input images.
        if (~strcmp(Image3Name,'Do not use') && all(size(Image1) == size(Image2)) && all(size(Image1) == size(Image3))),
            OriginalRGB(:,:,1) = Image3;
            OriginalRGB(:,:,2) = Image2;
            OriginalRGB(:,:,3) = Image1;
            AlignedRGB(:,:,1) = AlignedImage3;
            AlignedRGB(:,:,2) = AlignedImage2;
            AlignedRGB(:,:,3) = AlignedImage1;
        %%% For two input images.
        elseif all(size(Image1) == size(Image2)),
            OriginalRGB(:,:,1) = zeros(size(Image1));
            OriginalRGB(:,:,2) = Image2;
            OriginalRGB(:,:,3) = Image1;
            AlignedRGB(:,:,1) = zeros(size(AlignedImage1));
            AlignedRGB(:,:,2) = AlignedImage2;
            AlignedRGB(:,:,3) = AlignedImage1;
        else
            OriginalRGB = Image1;
            AlignedRGB = AlignedImage1;
        end
    end
    %%% Activates the appropriate figure window.
    CPfigure(handles,'Image',ThisModuleFigureNumber);
    if handles.Current.SetBeingAnalyzed == handles.Current.StartingImageSet
        CPresizefigure(OriginalRGB,'TwoByOne',ThisModuleFigureNumber)
        %%% Add extra space for the text at the bottom.
        Position = get(ThisModuleFigureNumber,'position');
        set(ThisModuleFigureNumber,'position',[Position(1),Position(2)-40,Position(3),Position(4)+40])
    end
    if strcmp(AdjustImage,'Yes')
        %%% A subplot of the figure window is set to display the original
        %%% image.
        subplot(5,1,1:2);
        CPimagesc(OriginalRGB,handles);
        title(['Input Images, cycle # ',num2str(handles.Current.SetBeingAnalyzed)]);
        %%% A subplot of the figure window is set to display the adjusted
        %%%  image.
        subplot(5,1,3:4);
        CPimagesc(AlignedRGB,handles);
        title('Aligned Images');
    end
    if isempty(findobj('Parent',ThisModuleFigureNumber,'tag','DisplayText'))
        displaytexthandle = uicontrol(ThisModuleFigureNumber,'tag','DisplayText','style','text', 'position', [0 0 200 40],'fontname','helvetica','backgroundcolor',[.7 .7 .9],'FontSize',handles.Preferences.FontSize);
    else
        displaytexthandle = findobj('Parent',ThisModuleFigureNumber,'tag','DisplayText');
    end
    set(displaytexthandle,'string',['Offset: ',Results])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE DATA TO HANDLES STRUCTURE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
drawnow

if strcmp(AdjustImage,'Yes')
    %%% Saves the adjusted image to the handles structure so it can be used
    %%% by subsequent modules.
    handles.Pipeline.(AlignedImage1Name) = AlignedImage1;
    handles.Pipeline.(AlignedImage2Name) = AlignedImage2;
    if strcmp(Image3Name,'Do not use') ~= 1
        handles.Pipeline.(AlignedImage3Name) = AlignedImage3;
    end
end

%%% Stores the shift in alignment as a measurement for quality control
%%% purposes.

%%% If three images were aligned:
if ~strcmp(Image3Name,'Do not use')
    fieldname = ['Align_',AlignedImage1Name,'_',AlignedImage2Name,'_',AlignedImage3Name,'Features'];
    handles.Measurements.Image.(fieldname) = {'ImageXAlign' 'ImageYAlign' 'ImageXAlignFirstTwoImages' 'ImageYAlignFirstTwoImages'};
    fieldname = ['Align_',AlignedImage1Name,'_',AlignedImage2Name,'_',AlignedImage3Name];
    handles.Measurements.Image.(fieldname){handles.Current.SetBeingAnalyzed} = [sx sy sx2 sy2];
else
    fieldname = ['Align_',AlignedImage1Name,'_',AlignedImage2Name,'Features'];
    handles.Measurements.Image.(fieldname) = {'ImageXAlign' 'ImageYAlign'};
    fieldname = ['Align_',AlignedImage1Name,'_',AlignedImage2Name];
    handles.Measurements.Image.(fieldname){handles.Current.SetBeingAnalyzed} = [sx sy];
end

% fieldname = ['ImageXAlign', AlignedImage1Name,AlignedImage2Name];
% handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {sx};
% fieldname = ['ImageYAlign', AlignedImage1Name,AlignedImage2Name];
% handles.Measurements.(fieldname)(handles.Current.SetBeingAnalyzed) = {sy};

%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTIONS %%%
%%%%%%%%%%%%%%%%%%%%

function [shiftx, shifty] = autoalign(in1, in2, method)
if (strcmp(method, 'Mutual Information')==1),
    [shiftx, shifty] = autoalign_mutualinf(in1, in2);
else
    [shiftx, shifty] = autoalign_ncc(in1, in2);
end

function [shiftx, shifty] = autoalign_ncc(in1, in2)
%%% XXX - should check dimensions
ncc = normxcorr2(in2, in1);
[i, j] = find(ncc == max(ncc(:)));
shiftx = j(1) - size(in2, 2);
shifty = i(1) - size(in2, 1);

function [shiftx, shifty] = autoalign_mutualinf(in1, in2)
%%% Aligns two images using mutual-information and hill-climbing.
best = mutualinf(in1, in2);
bestx = 0;
besty = 0;
%%% Checks which one-pixel move is best.
for dx=-1:1,
    for dy=-1:1,
        cur = mutualinf(subim(in1, dx, dy), subim(in2, -dx, -dy));
        if (cur > best),
            best = cur;
            bestx = dx;
            besty = dy;
        end
    end
end
if (bestx == 0) && (besty == 0),
    shiftx = 0;
    shifty = 0;
    return;
end
%%% Remembers the lastd direction we moved.
lastdx = bestx;
lastdy = besty;
%%% Loops until things stop improving.
while true,
    [nextx, nexty, newbest] = one_step(in1, in2, bestx, besty, lastdx, lastdy, best);
    if (nextx == 0) && (nexty == 0),
        shiftx = bestx;
        shifty = besty;
        return;
    else
        bestx = bestx + nextx;
        besty = besty + nexty;
        best = newbest;
    end
end

function [nx, ny, nb] = one_step(in1, in2, bx, by, ldx, ldy, best)
%%% Finds the best one pixel move, but only in the same direction(s) we
%%% moved last time (no sense repeating evaluations)
nb = best;
for dx=-1:1,
    for dy=-1:1,
        if (dx == ldx) || (dy == ldy),
            cur = mutualinf(subim(in1, bx+dx, by+dy), subim(in2, -(bx+dx), -(by+dy)));
            if (cur > nb),
                nb = cur;
                nx = dx;
                ny = dy;
            end
        end
    end
end
if (best == nb),
    %%% no change, so quit searching
    nx = 0;
    ny = 0;
end

function sub = subim(im, dx, dy)
%%% Subimage with positive or negative offsets
if (dx > 0),
    sub = im(:,dx+1:end);
else
    sub = im(:,1:end+dx);
end
if (dy > 0),
    sub = sub(dy+1:end,:);
else
    sub = sub(1:end+dy,:);
end

function H = entropy(X)
%%% Entropy of samples X
S = imhist(X,256);
%%% if S is probability distribution function N is 1
N=sum(sum(S));
if ((N>0) && (min(S(:))>=0))
    Snz=nonzeros(S);
    H=log2(N)-sum(Snz.*log2(Snz))/N;
else
    H=0;
end

function H = entropy2(X,Y)
%%% joint entropy of paired samples X and Y Makes sure images are binned to
%%% 256 graylevels
X = double(im2uint8(X));
Y = double(im2uint8(Y));
%%% Creates a combination image of X and Y
XY = 256*X + Y;
S = histc(XY(:),0:(256*256-1));
%%% If S is probability distribution function N is 1
N=sum(sum(S));
if ((N>0) && (min(S(:))>=0))
    Snz=nonzeros(S);
    H=log2(N)-sum(Snz.*log2(Snz))/N;
else
    H=0;
end

function I = mutualinf(X, Y)
%%% Mutual information of images X and Y
I = entropy(X) + entropy(Y) - entropy2(X,Y);