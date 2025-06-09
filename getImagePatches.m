% This function returns the image patches centered around the electrode.
% Required Inputs:
% imageFileName - full file name of the image
% electrodeList: list of electrodes for which patches are needed.
% subjectName: 'alpaH' or 'kesariH'. The RF data is assumed to be save in the data folder in the parent directory
% Optional Inputs:
% folderSourceString - location of the parent directory where the data folder containing RF information is kept
% patchSizeDeg - patch size (half the length of the side) in degrees. We take +-patchSizeDeg around the center of the RF.
% plottingDetails.displayPlotsFlag - set to 1 if you want to display the image and the patches
% plottingDetails.hPlotImage - plot handle where image will be displayed
% plottingDetails.hImagePatches - plot handles of the image patches. Must be of the same size as electrodeList
% monitorSpecifications - details of the monitor. Needed to convert from pixel to degrees space. 
% viewingDistanceCM - viewing distance in centimeters. 

function [patchData,imageAxesDeg] = getImagePatches(imageFileName,electrodeList,subjectName,folderSourceString,patchSizeDeg,plottingDetails,monitorSpecifications,viewingDistanceCM)

if ~exist('folderSourceString','var');  folderSourceString='';          end
if ~exist('patchSizeDeg','var');        patchSizeDeg=[];                end
if ~exist('plottingDetails','var'); plottingDetails=[];                 end
if ~exist('monitorSpecifications','var'); monitorSpecifications=[];     end
if ~exist('viewingDistanceCM','var'); viewingDistanceCM=[];             end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Take default values %%%%%%%%%%%%%%%%%%%%%%%%%
numElectrodes = length(electrodeList);

if isempty(folderSourceString); folderSourceString = fileparts(pwd);    end
if isempty(patchSizeDeg);       patchSizeDeg=4;                         end
if isempty(plottingDetails)
    displayPlotsFlag=1;
    if numElectrodes==1
        hImagePatches = subplot('Position',[0.75 0.5 0.2 0.45]);
    else
        hImagePatches = getPlotHandles(numElectrodes,1,[0.75 0.05 0.2 0.9]);
    end
    colorNames = jet(numElectrodes);
else
    displayPlotsFlag = plottingDetails.displayPlotsFlag;
    if displayPlotsFlag
        hImagePatches = plottingDetails.hImagePatches;
        colorNames = plottingDetails.colorNames;
        if length(hImagePatches) ~= numElectrodes
            error('Number of image patch plothandles must be equal to the number of electrodes');
        end
    end
end
if isempty(monitorSpecifications)
   [~,~,monitorSpecifications] = getMonitorDetails;
end
if isempty(viewingDistanceCM)
    [~,~,~,viewingDistanceCM] = getMonitorDetails;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get Image Details
inputImage = imread(imageFileName); % Get input image
[xAxisDeg,yAxisDeg] = getImageInDegrees(inputImage,monitorSpecifications,viewingDistanceCM); % Get relevant dimensions in degrees

% Get RF stats
rfData = load(fullfile(folderSourceString,'data','rfData',subjectName,[subjectName 'Microelectrode' 'RFData.mat']));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get Patch Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xResDeg = xAxisDeg(2)-xAxisDeg(1); xPosToTake = round(patchSizeDeg/xResDeg);
yResDeg = yAxisDeg(2)-yAxisDeg(1); yPosToTake = round(patchSizeDeg/yResDeg);
imageAxesDeg.xAxisDeg = xResDeg * (-xPosToTake:xPosToTake);
imageAxesDeg.yAxisDeg = yResDeg * (-yPosToTake:yPosToTake);
patchData = cell(1,numElectrodes);

for i=1:numElectrodes
    rfTMP = rfData.rfStats(electrodeList(i));
    mAzi = rfTMP.meanAzi;
    mEle = rfTMP.meanEle;
    xCenterPos = find(xAxisDeg>=mAzi,1);
    yCenterPos = find(yAxisDeg>=-mEle,1);
    patchData{i} = inputImage(yCenterPos-yPosToTake:yCenterPos+yPosToTake,xCenterPos-xPosToTake:xCenterPos+xPosToTake,:);
    
    if displayPlotsFlag
        xCenterDeg = xAxisDeg(xCenterPos);
        yCenterDeg = yAxisDeg(yCenterPos);
        
        paramsStimulus = rfTMP.params;
        paramsStimulus(1) = xCenterDeg;
        paramsStimulus(2) = yCenterDeg;
        [~,~,boundaryXStimulus,boundaryYStimulus] = gauss2D(paramsStimulus);

        % Show Patches in a separate window
        image([-patchSizeDeg patchSizeDeg],[-patchSizeDeg patchSizeDeg],patchData{i},'Parent',hImagePatches(i));
        hold(hImagePatches(i),'on');
        plot(hImagePatches(i),0,0,'color',colorNames(i,:),'marker','+','markersize',5);
        paramsStimulus(1) = 0;
        paramsStimulus(2) = 0;
        [~,~,boundaryXStimulus,boundaryYStimulus] = gauss2D(paramsStimulus);
        plot(hImagePatches(i),boundaryXStimulus,boundaryYStimulus,'color',colorNames(i,:));
        axis(hImagePatches(i),'tight');
        set(hImagePatches(i),'YTick',[-patchSizeDeg 0 patchSizeDeg],'YTickLabel',[patchSizeDeg 0 -patchSizeDeg]);
        set(hImagePatches(i),'XTick',[-patchSizeDeg 0 patchSizeDeg],'XTickLabel',[-patchSizeDeg 0 patchSizeDeg]);
        axis(hImagePatches(i),'tight');
    end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xAxisDeg,yAxisDeg] = getImageInDegrees(inputImage,monitorSpecifications,viewingDistanceCM)

% Check if the dimensions of the image match the resolution of the monitor.
% This is when a screenshot of the image displayed by the monitor is saved.
imageXRes=size(inputImage,2);
imageYRes=size(inputImage,1);

if ~(isequal(monitorSpecifications.xRes,imageXRes) && isequal(monitorSpecifications.yRes,imageYRes))
    % Not a screenshot. Need to resize the image. Deal with this later
    error('Not a screenshot');
else
    [xAxisDeg,yAxisDeg] = getMonitorDetails(monitorSpecifications,viewingDistanceCM);
end
end