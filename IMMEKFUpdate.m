function [X_Filter,P_Filter, innovation_store, S_store, X_IMM, P_IMM, modeProbs]= IMMEKFUpdate(X_IMM,P_IMM,IMU_meas,IMU_noise,GPS_meas,GPS_noise,transMatrix,modeProbs,EKF_update,dt)

%Determine number of models
m = size(X_IMM,2);

%Number of states
n = size(X_IMM,1);

%Number of measurements
if ~isempty(GPS_meas)
    measurement = GPS_meas(2:3);
end

 innovation_store = [];
 S_store = [];

%*****Interacting/Mixing*****
c_j = zeros(1,m);
for j = 1:m
    for i = 1:m
        c_j(j) = c_j(j) + transMatrix(i,j)*modeProbs(i);
    end
end

modeProbs_ij = zeros(m,m);
for i = 1:m
    for j = 1:m
        modeProbs_ij(i,j) = 1/c_j(j)*transMatrix(i,j)*modeProbs(i);
    end
end

%Calculate mixed state and covariance
X0j = zeros(n,m);
for j = 1:m
    for i = 1:m
        X0j(:,j) = X0j(:,j) + X_IMM(:,i)*modeProbs_ij(i,j);
    end
end

P0j = zeros(n,n,m);
for j = 1:m
    for i = 1:m
        P0j(:,:,j) = P0j(:,:,j) + modeProbs_ij(i,j)*(P_IMM(:,:,i) + (X_IMM(:,i)-X0j(:,j))*(X_IMM(:,i)-X0j(:,j))');
    end
end

for i = 1:m
    
    [X0j(:,i),P0j(:,:,i)] = EKFpredict(X0j(:,i),P0j(:,:,i),dt,IMU_meas(1,:),IMU_meas(2,:),IMU_noise);
    
    if EKF_update == 1
        %Perform Kalman filter updates on each filter and calculate likelihoods
        obsStates           = length(measurement);
        S_store             = zeros(obsStates,m);
        innovation_store    = zeros(obsStates,m);
        
        [X0j(:,i),P0j(:,:,i),S,innovation] = EKFupdate(X0j(:,i),P0j(:,:,i),GPS_meas,GPS_noise);
        measurementPred = X0j(1:2,i);
        lamda(i)        = GaussianDensity(measurement', measurementPred, S);
        
        S_store(:,i)            = diag(S);
        innovation_store(:,i)   = innovation;
    end
    
end

if EKF_update == 1
    %Mode probability update
    c = 0;
    for j = 1:m
        c = c + lamda(j) * c_j(j);
    end
    
    for j = 1:m
        modeProbs(j) = 1/c * lamda(j) * c_j(j);
    end
end

X_IMM = X0j;
P_IMM = P0j;

%Estimate and Covariance Combination
X_Filter = zeros(n,1);
for j = 1:m
    X_Filter = X_Filter + X_IMM(:,j) * modeProbs(j);
end

P_Filter = zeros(n,n);
for j = 1:m
    P_Filter = P_Filter +  modeProbs(j) * (P_IMM(:,:,j) + (X_IMM(:,j)-X_Filter)*(X_IMM(:,j)-X_Filter)');
end