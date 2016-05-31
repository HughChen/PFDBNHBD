function [onsetp,peakp,dicron] = delineator(abpsig,abpfreq)
% This program is intended to delineate the fiducial points of pulse waveforms
% Inputs:
%   abpsig: input as original pulse wave signals;
%   abpfreq: input as the sampling frequency;
% Outputs:
%   onsetp: output fiducial points as the beginning of each beat;
%   peakp: output fiducial points as systolic peaks;
%   dicron: output fiducial points as dicrotic notches;

% Its delineation is based on the self-adaptation in pulse waveforms, but
% not in the differentials.

% Reference:
%   BN Li, MC Dong & MI Vai (2010) 
%   On an automatic delineator for arterial blood pressure waveforms
%   Biomedical Signal Processing and Control 5(1) 76-81.

% LI Bing Nan @ University of Macau, Feb 2007
%   Revision 2.0.5, Apr 2009


%******* TODO: FIX THE BESSEL SO IT'S NOT NEEDED ******%
assert ( size(abpsig,1)>1 && size(abpsig,2)==1 && isreal ( abpsig ) && isa(abpsig, 'double'));
assert ( all(size(abpfreq)==[1 1]) && isreal ( abpfreq ) && isa(abpfreq, 'double'));


%Initialization
peakIndex=0;
onsetIndex=0;
dicroIndex=0;
stepWin=2*abpfreq;
closeWin=floor(0.1*abpfreq);    %invalide for pulse beat > 200BPM

sigLen=length(abpsig);

% remove signal mean
twind=10; % window of 10 seconds, 5 seconds overlap
N=sigLen;
W=abpfreq*twind;
pos=1;

while (pos+W <= N)                       % while enough signal left
    abpsig(pos:pos+W-1,1)=abpsig(pos:pos+W-1,1)-mean(abpsig(pos:pos+W-1));
    pos = pos + W/2;% next window
end
if(pos<N)
      abpsig(pos:N,1)=abpsig(pos:N,1)-mean(abpsig(pos:N,1));
end

%lowpass filter at first
coh=25;                     %cutoff frequency is 25Hz
coh=coh*2/abpfreq;
od=3;                       %3rd order bessel filter
% 

%     [B,A]=besself(od,coh);
if abpfreq==256
    B = [0,0,0,0.007450580596924];
    A = [1,0.475172030904172,0.094078524563998,0.007450580596924];
elseif abpfreq==250
    B = [0,0,0,0.008000000000000];
    A = [1,0.486576159645872,0.098648482973219,0.008000000000000];
elseif abpfreq==125
    B = [0,0,0,0.064000000000000];
    A = [1,0.973152319291744,0.394593931892875,0.064000000000000];
elseif abpfreq==75
    B = [0,0,0,0.296296296296296];
    A = [1,1.621920532152906,1.096094255257986,0.296296296296296];
else
    % default 250hz
[B,A] = besself(od,coh);
%    B = [0,0,0,0.008000000000000];
%    A = [1,0.486576159645872,0.098648482973219,0.008000000000000];
end
abpsig=filter(B,A,abpsig);
abpsig=10*abpsig;
abpsig = filtfilt(ones(1,5)/5,1,abpsig);

%Compute differentials
N = size(abpsig,1);
diff1 = 100*[abpsig(2,1) - abpsig(1,1);
    abpsig(2:N,1) - abpsig(1:N-1,1)];
diff1 = filtfilt(ones(1,5)/5,1,diff1);

if sigLen>12*abpfreq
    tk=10;
elseif sigLen>7*abpfreq
    tk=5;
elseif sigLen>4*abpfreq
    tk=2;
else
    tk=1;
end

%Seek avaerage threshold in original signal
if tk>1             %self-learning threshold with interval sampling
    tatom=floor(sigLen/(tk+2));
    tempTH = zeros(1,tk);
    for ji=1:tk       %search the slopes of abp waveforms
        sigIndex=ji*tatom;
        tempIndex=sigIndex+abpfreq;
        [tempMin,jk,tempMax,jl]=seeklocales(abpsig,sigIndex,tempIndex);
        tempTH(ji)=tempMax-tempMin;
    end
%     abpMaxTH=mean(tempTH);
    abpMaxTH=median(tempTH);
else
    [tempMin,jk,tempMax,jl]=seeklocales(abpsig,closeWin,sigLen);
    abpMaxTH=tempMax-tempMin;
end

abpMaxLT=0.4*abpMaxTH;

%Seek pulse beats by MinMax method
% diffIndex=1;
diffIndex=closeWin;             %Avoid filter distortion

peakp=nan(1,sigLen);        %Avoid initial error
onsetp=nan(1,sigLen);      %Avoid initial error
dicron=nan(1,sigLen);        %Avoid initial error
while diffIndex<sigLen
    tempMin=abpsig(diffIndex);   %Initialization
    tempMax=abpsig(diffIndex);
    tempIndex=diffIndex;
    tpeakp=diffIndex;        %Avoid initial error
    tonsetp=diffIndex;      %Avoid initial error

    while tempIndex<sigLen
        %If no pulses within 2s, then adjust threshold and retry
        if (tempIndex-diffIndex)>stepWin
%             tempIndex=diffIndex-closeWin;
            tempIndex=diffIndex;
            abpMaxTH=0.6*abpMaxTH;
            if abpMaxTH<=abpMaxLT
                abpMaxTH=2.5*abpMaxLT;
            end
            break;
        end

        if (diff1(tempIndex-1,1)*diff1(tempIndex+1,1))<=0  %Candidate fiducial points
            if (tempIndex+5)<=sigLen
                jk=tempIndex+5;
            else
                jk=sigLen;
            end
            if (tempIndex-5)>=1
                jj=tempIndex-5;
            else
                jj=1;
            end

            %Artifacts of oversaturated or signal loss?
            if (jk-tempIndex)>=5
                for ttk=tempIndex:jk
                    if diff1(ttk)~=0
                        break;
                    end
                end
                if ttk==jk
                    break;          %Confirm artifacts
                end
            end

            if diff1(jj,1)<0          %Candidate onset
                if diff1(jk,1)>0
                    [tempMini,tmin,ta,tb]=seeklocales(abpsig,jj,jk);
                    if abs(tmin-tempIndex)<=2
                        tempMin=tempMini;
                        tonsetp=tmin;
                    end
                end
            elseif diff1(jj,1)>0      %Candidate peak
                if diff1(jk,1)<0
                    [tc,td,tempMaxi,tmax]=seeklocales(abpsig,jj,jk);
                    if abs(tmax-tempIndex)<=2
                        tempMax=tempMaxi;
                        tpeakp=tmax;
                    end
                end
            end

            if ((tempMax-tempMin)>0.4*abpMaxTH)   %evaluation
                if ((tempMax-tempMin)<2*abpMaxTH)
                    if tpeakp>tonsetp
                        %If more zero-crossing points, further refine!
                        ttempMin=abpsig(tonsetp);
                        ttonsetp=tonsetp;
                        for ttk=tpeakp:-1:(tonsetp+1)
                            if abpsig(ttk)<ttempMin
                                ttempMin=abpsig(ttk);
                                ttonsetp=ttk;
                            end
                        end
                        tempMin=ttempMin;
                        tonsetp=ttonsetp;
                            
                        if peakIndex>0
                            %If pulse period less than eyeclose, then artifact
                            if (tonsetp-peakp(peakIndex))<(3*closeWin)
                                %too many fiducial points, then reset
                                tempIndex=diffIndex;                                
                                abpMaxTH=2.5*abpMaxLT;
                                break;
                            end
                            
                            %If pulse period bigger than 2s, then artifact
                            if (tpeakp-peakp(peakIndex))>stepWin
                                peakIndex=peakIndex-1;
                                onsetIndex=onsetIndex-1;
                                if dicroIndex>0
                                    dicroIndex=dicroIndex-1;
                                end
                            end

                            if peakIndex>0
                                %new pulse beat
                                peakIndex=peakIndex+1;
                                peakp(peakIndex)=tpeakp;
                                onsetIndex=onsetIndex+1;
                                onsetp(onsetIndex)=tonsetp;

                                tf=onsetp(peakIndex)-onsetp(peakIndex-1);

                                to=floor(abpfreq./20);   %50ms
                                tff=floor(0.1*tf);
                                if tff<to
                                    to=tff;
                                end
                                to=peakp(peakIndex-1)+to;

                                te=floor(abpfreq./2);   %500ms
                                tff=floor(0.5*tf);
                                if tff<te
                                    te=tff;
                                end
                                te=peakp(peakIndex-1)+te;

                                tff=seekdicrotic(diff1(to:te,1));
                                if tff==0
                                    tff=te-peakp(peakIndex-1);
                                    tff=floor(tff/3);
                                end
                                dicroIndex=dicroIndex+1;
                                dicron(dicroIndex)=to+tff;

                                tempIndex=tempIndex+closeWin;
                                break;
                            end
                        end
                        
                        if  peakIndex==0   %new pulse beat
                            peakIndex=peakIndex+1;
                            peakp(peakIndex)=tpeakp;
                            onsetIndex=onsetIndex+1;
                            onsetp(onsetIndex)=tonsetp;

                            tempIndex=tempIndex+closeWin;
                            break;
                        end
                    end
                end
            end
        end

        tempIndex=tempIndex+1;      %step forward
    end

%     diffIndex=tempIndex+closeWin;    %for a new beat
    diffIndex=tempIndex+1;
end


peakp=peakp(1:peakIndex);       
onsetp=onsetp(1:onsetIndex);   
dicron=dicron(1:dicroIndex);

if isempty(peakp),return;end
%Compensate the offsets of lowpass filter
sigLen=length(peakp);
tempp = zeros(1,sigLen);
for diffIndex=1:sigLen          %avoid edge effect
    tempp(diffIndex)=peakp(diffIndex)-od;
end
ttk=tempp(1);
if ttk<=0
    tempp(1)=1;
end 
peakp=tempp;

sigLen=length(onsetp);
for diffIndex=1:sigLen
    tempp(diffIndex)=onsetp(diffIndex)-od;
end
ttk=tempp(1);
if ttk<=0
    tempp(1)=1;
end 
onsetp=tempp;

if isempty(dicron),return;end
sigLen=length(dicron);
for diffIndex=1:sigLen
    if dicron(diffIndex)~=0
        tempp(diffIndex)=dicron(diffIndex)-od;
    else
        tempp(diffIndex)=0;
    end
end
dicron=tempp;


function [mini,minip,maxi,maxip]=seeklocales(tempsig,tempbegin,tempend)
tempMin=tempsig(tempbegin,1);
tempMax=tempsig(tempbegin,1);
minip=tempbegin;
maxip=tempbegin;
for j=tempbegin:tempend
    if tempsig(j,1)>tempMax
        tempMax=tempsig(j,1);
        maxip=j;
    elseif tempsig(j,1)<tempMin
        tempMin=tempsig(j,1);
        minip=j;
    end
end

mini=tempMin;
maxi=tempMax;

function [dicron]=seekdicrotic(tempdiff)
izcMin=0;
izcMax=0;
itemp=3;
tempLen=length(tempdiff)-3;

dicron=0;

tempdiff=filtfilt(ones(1,5)/5,1,tempdiff);
tzcMin = zeros(1,tempLen);
while itemp<=tempLen
    if (tempdiff(itemp,1)*tempdiff(itemp+1,1))<=0
        if tempdiff(itemp-2,1)<0
            if tempdiff(itemp+2,1)>=0
                izcMin=izcMin+1;
                tzcMin(izcMin)=itemp;
            end
        end

%         if tempdiff(itemp-2)>0
%             if tempdiff(itemp+2)<=0
%                 izcMax=izcMax+1;
%                 tzcMax(izcMax)=itemp;
%             end
%         end
    end

    itemp=itemp+1;
end
tzcMin = tzcMin(1:izcMin);

if izcMin==0     %big inflection
    itemp=3;
    tempMin=tempdiff(itemp,1);
    itempMin=itemp;
    
    while itemp<tempLen
        if tempdiff(itemp,1)<tempMin
            tempMin=tempdiff(itemp,1);
            itempMin=itemp;
        end
        itemp=itemp+1;
    end

    itemp=itempMin+1;
    while itemp<tempLen
        if tempdiff(itemp+1,1)<=tempdiff(itemp-1,1)
            dicron=itemp;
            return;
        end
        itemp=itemp+1;
    end
elseif izcMin==1
    dicron=tzcMin(izcMin);
    return;
else
    itemp=tzcMin(1);
    tempMax=tempdiff(itemp,1);
    itempMax=itemp;
    
    while itemp<tempLen
        if tempdiff(itemp,1)>tempMax
            tempMax=tempdiff(itemp,1);
            itempMax=itemp;
        end
        itemp=itemp+1;
    end

    for itemp=izcMin:-1:1
        if tzcMin(itemp)<itempMax
            dicron=tzcMin(itemp);
            return;
        end
    end
end

function [diap]=seekdiap(tempabp)
diap=0;

[tt,ti]=max(tempabp);
if ti==0
    diap=floor(length(tempabp)./2);
else
    diap=ti;
end

