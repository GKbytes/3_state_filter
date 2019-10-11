function [X_GSF, P_GSF, w_GSF] = initialiseGSFEKF(x_init,P_init,N)

numberOfModels  = N;
D2R             = pi/180;
Vn_0            = x_init(1);
Ve_0            = x_init(2);

P_Filter        = P_init;

X_GSF           = zeros(3,numberOfModels);
increment       = (2*pi)/N;

P_GSF           = zeros(3,3,numberOfModels);

% initialise states with yaw evenly spaced and symmetrical about 0
for i = 1:N
    X_GSF(:,i)      = [Vn_0;Ve_0;-pi+increment/2 + (i-1)*increment];
    P_GSF(:,:,1)    = P_Filter;
    w_GSF(i)        = 1/(numberOfModels);
end
