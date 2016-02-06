clear all
close all
rand('state',sum(100*clock)); %#ok<RAND>

load SpatialData

% BurstSize = geomean(BurstSizemRNA,1);
% BurstFreq = geomean(BurstFreqmRNA,1);
% 
BurstSize = BurstSizeDirectmean;
BurstFreq = BurstFreqDirectmean;
%load RecalcEncounterData
%load tempEncounterBurstData

kM = 40960;
kP = 0;
gammam = 1;
gammap = .1;
lambda = 0;

kON = 65;
kOFF = 195130;

kONArray = BurstFreq;
kOFFArray = 1./BurstSize;

%comparable numbers to cube 10% to 50% crowding
 VarArray = BurstSize;%[1,6,25]; %burst durations 
% %timebetween = [0.10594824,0.0866851,0.06852042]; %empty bursts removed
 timebetween = 1./BurstFreq; %empty bursts included
%VarArray = [4,5.5,7.5];%[1,6,25]; %burst durations 
%timebetween = [0.10594824,0.0866851,0.06852042]; %empty bursts removed
%timebetween = [1/65.8,1/65.9,1/66.2]; %empty bursts included

%comparable numbers for 50% crowding 2High to cube
% VarArray = [8.7,7.7,7.4];
% timebetween = [1/57.9,1/63.3,1/66.2];


Runs = 50;
tMax = 200;
dt = .1;
tspan = 0:dt:tMax;
tspan2 = length(tspan);

InitialProtein = 0;

Plasmids = 1;%[1,6,25];
BurstDurationTrack = zeros(100000,Runs);
BurstTimesTrack = zeros(100000,Runs);

for j = 1:length(VarArray)
%     kON = kONArray(j);
%     kOFF = kOFFArray(j);
    temp = VarArray(j);%*(10^-6);
    kON = 1/(timebetween(j)-temp);
    kOFF = 1/(temp);
    kONTrack(j) = kON;
    kOFFTrack(j) = kOFF;

for i = 1:Runs
    disp(i)
    PercO = kON/(kON + kOFF);
    
    ProteinStart = InitialProtein;%round(InitialProtein + randn*sqrt(InitialProtein));
    
    if Plasmids == 1
        if rand < kON/(kON + kOFF)
            x0 = [0, ProteinStart, 1, 0];
        else
            x0 = [0, ProteinStart, 0, 1];
        end
    else
        PlasmidsON = round(kON/(kON + kOFF) * Plasmids);
        x0 = [0, ProteinStart, PlasmidsON, Plasmids - PlasmidsON];
    end
    
    
    RxnMatrix = [ 1  0  0  0; %trascription
                  0  1  0  0; %translation
                 -1  0  0  0; %mRNA decay
                  0 -1  0  0; %protein decay
                  0  0 -1  1; %Burst OFF
                  0  0  1 -1];%Burst ON

     p = 1;
        Onflag = x0(3);
        mRNAperBurst = zeros(100000,1);

        MaxOutput = 100000; %Maximum size expected of the output file
        NumSpecies = size(RxnMatrix, 2);
        %T = zeros(MaxOutput, 1); %Time tracking
        %X = zeros(1, NumSpecies); %Species number tracking
        %T(1)     = 0;
        %X(1,:)   = x0;
        RxnCount = 1;
        T = 0; %Time
        Ttrack = zeros(length(tspan), 1); %Time tracking
        X = zeros(length(tspan), NumSpecies); %Species number tracking
        X(1,:)   = x0;
        xCurrent = x0;
        RecordTime = dt; %Recording time
        RecordCount = 2;
        OnTrack = 0;
        count = 1;
        OnDuration = zeros(MaxOutput,1);
        OnTimes = zeros(MaxOutput,1);
        %%%%%%%%%%%%%%%%%%%%%%
        %Gillespie Simulation%
        %%%%%%%%%%%%%%%%%%%%%%

        while T <= tMax

            % Calculate reaction propensities
            x = xCurrent;
            mRNA    = x(1);
            protein = x(2);
            StateON = x(3);
            StateOFF = x(4);
            
            %track burst dynamics
            if StateON == 1
                if OnTrack == 0
                    OnTrack = 1;
                    OnTimes(count) = T;
                    OnDuration(count) = T;
                else
                end
            elseif OnTrack == 1
                OnTrack = 0;
                OnDuration(count) = T - OnDuration(count);
                count = count + 1;
                
            end
                    
            
            a = [kM*StateON; kP*mRNA; gammam*mRNA; gammap*protein;
                kOFF*StateON; kON*StateOFF];

            % Compute tau and mu using random variables
            a0 = sum(a);
            r = rand(1,2);
            %tau = -log(r(1))/a0;
            tau = (1/a0)*log(1/r(1));

            %Store information if at time
            if T + tau > RecordTime
                X(RecordCount,:) = xCurrent;

                RecordCount = RecordCount + 1;
                RecordTime = RecordTime + dt;

            end
            %[~, mu] = histc(r(2)*a0, [0;cumsum(a(:))]);
            mu  = find((cumsum(a) >= r(2)*a0),1,'first');

            %find the next change in state before tau
            T   = T  + tau;
            xCurrent = xCurrent + RxnMatrix(mu,:);

        end


        % Record output
         X(RecordCount,:) = xCurrent;

        % Record output
        count = count - 1;
        mRNAData(:,i) = X(201:tspan2,1);
        GillespieData(:,i) = X(201:tspan2,2);
        BurstDurationTrack(:,i) = OnDuration;
        BurstTimesTrack(:,i) = OnTimes;
        BurstNumberTrack(i) = count;
    
end

BurstTimesBetweenTrack = diff(BurstTimesTrack,1);
% GillespieData = GillespieData(200:end,:);
len = length(GillespieData(:,1));
GillespieDataAvg = zeros(len,1); %Average curve of all Runs
mRNADataAvg = zeros(len,1); %Average curve of all Runs
for h = 1:len
    GillespieDataAvg(h) = sum(GillespieData(h,:))/Runs;
    mRNADataAvg(h) = sum(mRNAData(h,:))/Runs;
end
    
GillespieDataA = zeros(len,Runs);
mRNADataA = zeros(len,Runs);

for k = 1:Runs
    disp(k)
    SSlevelsArray(k) = mean(GillespieData(:,k));
    SSmRNAArray2(k) = mean(mRNAData(:,k));
    
    GillespieDataA(:,k) = GillespieData(:,k) - GillespieDataAvg;
    mRNADataA(:,k) = mRNAData(:,k) - mRNADataAvg;
    
    AutoArrayTemp = xcorr(GillespieDataA(:,k),'unbiased');%,length(tspan2)-1);
    AutomRNAArrayTemp = xcorr(mRNADataA(:,k),'unbiased');%,length(tspan2)-1);
    AutoArray(:,k) = AutoArrayTemp;
    VarienceArray(k) = AutoArrayTemp(len);
    Avgcv2(k) = AutoArrayTemp(len)/(SSlevelsArray(k))^2;
    AutomRNAArray(:,k) = AutomRNAArrayTemp;
    VariencemRNAArray(k) = AutomRNAArrayTemp(len);
    t50mRNAArray(k) = find(AutomRNAArrayTemp(len:end) < .5*AutomRNAArrayTemp(len),1,'first');
    AvgmRNAcv2(k) = AutomRNAArrayTemp(len)/(SSmRNAArray2(k))^2;

end
%%

AutoVar(:,j) = VarienceArray;
AvgSSVar = var(SSlevelsArray);
MeanSS = mean(SSlevelsArray);
Avgcv2Tot(:,j) = Avgcv2;
SSlevelsTot(:,j) = (SSlevelsArray);

AutomRNAVar(:,j) = VariencemRNAArray;
AvgmRNAcv2Tot(:,j) = AvgmRNAcv2;
SSmRNATot(:,j) = (SSmRNAArray2);
t50mRNATot(:,j) = t50mRNAArray;

BurstDurationTrackTot(:,:,j) = BurstDurationTrack;
BurstTimesTrackTot(:,:,j) = BurstTimesTrack;
BurstNumberTrackTot(:,j) = BurstNumberTrack;

end
% 
% AvgBurstFreq(:) = BurstFreq;
% AvgBurstSize(:) = BurstSize;
%%
% c = colormap(hsv(length(kONArray)));
% %c = colormap(hsv(length(VarArray)));
% for i = 1:length(kONArray)
%     hold on
%     plot(SSlevelsTot(:,i),Avgcv2Tot(:,i),'linestyle','none','marker','.',...
%         'markersize',10,'color',c(i,:));
% end
% set(gca,'XScale','log');
% set(gca,'YScale','log');
save 2StateEncounterData
%%

%c = colormap(hsv(length(kONArray)));
hold on
% for i = 1:7
%     plot(SSmRNAArray(:,i),cv2mRNAArray(:,i),'linestyle','none','marker','.',...
%         'markersize',8,'color','k');
% end

c = colormap(hsv(length(VarArray)));
for i = 1:length(VarArray)
    hold on
    plot(SSmRNATot(:,i),AvgmRNAcv2Tot(:,i),'linestyle','none','marker','o',...
        'markersize',6,'markerfacecolor',c(i,:),'markeredgecolor','k');
end

set(gca,'XScale','log');
set(gca,'YScale','log');
axis([7 30 .03 1])
set(gca,'fontsize',15)
xlabel('mRNA Abundance','FontSize',15)
ylabel('cv^2','FontSize',15)

title('cv^2 v Abundance From Encounters')
saveas(gcf,'mRNAcv2vAbundance2StateDirect.jpg')
saveas(gcf,'mRNAcv2vAbundance2StateDirect.svg')

