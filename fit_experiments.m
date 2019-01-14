% This function find the best fitting model/parameters
close all

addpath './simulation'
addpath './computation'
addpath './utils'

%% Load experiment data


[con, con2, cho, out, nsubs] = load_data('sim', ');


%% Optimization
subjecttot = nsubs;
nmodel = 6;
whichmodel = 1:nmodel;
nparam = 5;
parameters = zeros(subjecttot, nparam, nmodel);
lpp = zeros(subjecttot, nmodel);
report = zeros(subjecttot, nmodel);
gradient = cell(subjecttot, nmodel);
hessian = cell(subjecttot, nmodel);

models = containers.Map(...
    {'QLearning', 'Asymmetric', 'AsymmetricPessimistic', 'Perseveration'...
     'Priors', 'Full'}, whichmodel);
% 1: basic df=2
% 2: asymmetric neutral df=3
% 3: asymmetric pessimistic df=3
% 4: perseveration df=3
% 5: priors df=3
% 6: full df=5

options = optimset(...
    'Algorithm',...
    'interior-point',...
    'Display', 'off',...
    'MaxIter', 2000,...
    'MaxFunEval', 2000);

w = waitbar(0, 'Fitting subject');
for nsub = 1:subjecttot
    for model = whichmodel
        [
            p,...
            l,...
            rep,...
            grad,...
            hess,...
         ] = fmincon(...
                @(x) getpost(x, con{nsub}, cho{nsub}, out{nsub}, model),...
                [1, .5, .5, 0, 0],...
                [], [], [], [],...
                [0, 0, 0, -2, -1],...
                [Inf, 1, 1, 2, 1],...
                [],...
                options...
            );
        parameters(nsub, :, model) = p;
        lpp(nsub, model) = l;
        report(nsub, model) = rep;
        gradient{nsub, model} = grad;
        hessian{nsub, model}= hess;
        
      waitbar(...
          nsub/subjecttot,...  % Compute progression
          w,...
          sprintf('%s%d', 'Fitting subject ', nsub)...
      );
  
    end
end
save('fit_exp/parameters', 'parameters');

% nfpm=[2 3]; % number of free parameters

%% to correct
nfpm = [2, 3, 3, 3, 3, 5];
for n = whichmodel
    bic(1:85, n) = -2 * -lpp(1:85, n) + nfpm(n) * log(96);
    bic(86:105, n) = -2 * -lpp(86:105, n) + nfpm(n) * log(96*2);
    % l2 is already positive
    % aic(:,n)=lpp(:,n)+2*nfpm(n);
    %
end

%% ----------------------- Plots ----------------------------------
figure;
%% What is it?
bias1 = (parameters(:, 2, 2) - parameters(:, 3, 2)) ./ (parameters(:, 2, 2) ...
    + parameters(:, 3, 2));
bias2 = (parameters(:, 2, 3) - parameters(:, 3, 3)) ./ (parameters(:, 2, 3) ...
    + parameters(:, 3, 3));
perse = parameters(:, 4, 4);
prior = parameters(:, 5, 5);

subplot(1, 2, 1)
scatterCorr(bias1, perse, 2, 1);
subplot(1, 2, 2)
scatterCorr(bias1, prior, 2, 1);

%%
aaaa = [
    (parameters(:, 2, 6) - parameters(:, 3, 6)) ./ (parameters(:, 2, 6) +...
    parameters(:, 3, 6)), parameters(:, 4:5, 6)
];

%
figure;
BarsAndErrorPlot(...
    aaaa',...
    [0, 0, 0],...
    [0.5, 0.5, 0.5],...
    2,...
    0.5,...
    -1,...
    1,...
    -0.2,...
    14,...
    '',...
    '',...
    ''...
);

%%
figure;

subplot(1, 2, 1)

scatterCorr(...
    (parameters(:, 2, 6) - parameters(:, 3, 6))./(parameters(:, 2, 6)...
    + parameters(:, 3, 6)), parameters(:, 4, 6), 1, 1);

subplot(1, 2, 2)

scatterCorr(...
    (parameters(:, 2, 6) - parameters(:, 3, 6))./(parameters(:, 2, 6)...
    + parameters(:, 3, 6)), parameters(:, 5, 6), 1, 1);


%bestmodel=find(bicgroup==min(bicgroup));

%bestparameters(:,:)=parameters(:,:,bestmodel);

%% nex is the one to download anyxay

%parameters2(:,1,2)=1./parameters2(:,1,2);
parameters(:, 1, 2) = 1 ./ parameters(:, 1, 2);

figure;
BarsAndErrorPlotThree(...
    parameters(:, :, 2)',...
    [0, 0, 0],...
    [0.5, 0.5, 0.5],...
    2,...
    0.5,...
    0,...
    1,...
    -0.2,...
    14,...
    '', '', '', '', '', '');
hold on
%BarsAndErrorPlotThree(parameters2(:,:,2)',[0.5 0.5 0.5],[0 0 0],2,0.5,0,1,+0.2,14,'','','','','','');

%%
%figure;
%BarsAndErrorPlotTwo(ll',[0 0 0],[0.5 0.5 0.5],2,0.5,0,1,-0.2,14,'','','','','','');
%hold on
%BarsAndErrorPlotTwo(ll2',[0.5 0.5 0.5],[0 0 0],2,0.5,0,1,+0.2,14,'','','','','','');

[outcome, post] = VBA_groupBMC((-bic(:, [1, 2, 4, 5, 6]))');

%%

%figure;
%scatterCorr(parameters(:,2,2)-parameters(:,3,2),parameters2(:,2,2)-parameters2(:,3,2),1,[0 0 1]);
