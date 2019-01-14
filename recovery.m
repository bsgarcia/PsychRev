% This function find the best fitting model/parameters
close all

addpath './simulation'
addpath './computation'
addpath './utils'

%% Set  variables
condlabels = {'risk', 'statusquo1', 'statusquo2'};
nmodel = 6;
whichmodel = 1:nmodel;
nparam = 5;
tmax = 4*48;
models = containers.Map(whichmodel,...
    {'QLearning', 'Asymmetric', 'AsymmetricPessimistic', 'Perseveration', ...
    'Priors', 'Full'});

% 1: basic df=2
% 2: asymmetric neutral df=3
% 3: asymmetric pessimistic df=3
% 4: perseveration df=3
% 5: priors df=3
% 6: full df=5

options = optimset( ...
        'Algorithm', ...
        'interior-point', ...
        'Display', 'off', ...
        'MaxIter', 2000, ...
        'MaxFunEval', 2000);
    
w = waitbar(0, 'Get data');

    
% iterate on conditions
for i = 1:length(condlabels)


    [lpp, parameters] = getdata(...
        condlabels{i}, nmodel, whichmodel, nparam, options, w);

    [bicmatrix, xlabels, ylabels] = computepercentagewinning(...
        lpp, whichmodel, nmodel, models, length(lpp(1, 1, :)), tmax);
    
    figure;
    h = heatmap(xlabels, ylabels, bicmatrix);
    ylabel('Simulation using model x');
    xlabel('Fitted model');
    title(sprintf('Condition %s', condlabels{i}));

end

%% ---------------------- functions -------------------------------- % 

function [bicmatrix, xlabels, ylabels] = computepercentagewinning(...
    lpp, whichmodel, nmodel, models, subjecttot, tmax)
    
%     for fittedmodel = whichmodel
%         for datamodel = whichmodel
%             lpp(fittedmodel, datamodel, :) = randi([1, 50], 1, 105);
%         end
%     end
    nfpm = [2, 3, 3, 3, 3, 5];

    bic = zeros(nmodel, nmodel, subjecttot);
    bicmatrix = zeros(nmodel, nmodel);

    for fittedmodel = whichmodel
        bic(fittedmodel, :, :) = -2 * -lpp(fittedmodel, :, :)...
            + nfpm(fittedmodel) * log(tmax);
        disp(bic(fittedmodel, fittedmodel, :));
        
        for sub = 1:subjecttot
            [mini, argmin] = min(bic(fittedmodel, :, sub));
             bicmatrix(fittedmodel, argmin) = bicmatrix(fittedmodel, argmin) + 1;
        end
        
        xlabels{fittedmodel} = models(fittedmodel);
        ylabels{fittedmodel} = models(fittedmodel);
    end
    
    bicmatrix = bicmatrix ./ (subjecttot/100);
end

function [lpp, parameters] = getdata(str, nmodel, whichmodel, nparam,...
    options, w)
    try
        data = load(sprintf('fit_sim/%s', str));
        lpp = data.data('lpp');
        parameters = data.data('parameters');
        waitbar(100, w, 'Done');
        
    catch
        [lpp, parameters] = runfit(str, nmodel, whichmodel, nparam,...
            options, w);
    end
end

function [lpp, parameters] = runfit(str, nmodel, whichmodel, nparam,...
    options, w)
    [
        con, ...
        con2, ...
        cho, ...
        out, ...
        nsubs, ...
        ] = load_data('sim', str);

    subjecttot = nsubs;
    parameters = repelem({zeros(subjecttot, nparam, nmodel)}, nmodel);
    lpp = zeros(nmodel, nmodel, subjecttot);
    report = repelem({zeros(subjecttot, nmodel)}, nmodel);
    gradient = repelem({cell(subjecttot, nmodel)}, nmodel);
    hessian = repelem({cell(subjecttot, nmodel)}, nmodel);

    for nsub = 1:subjecttot
        for fittedmodel = whichmodel
            for datamodel = whichmodel
                [
                    p, ...
                    l, ...
                    rep, ...
                    grad, ...
                    hess, ...
                    ] = fmincon( ...
                            @(x) ...
                            getpost( ...
                                x, ...
                                con{nsub}(:, :, datamodel), ...
                                cho{nsub}(:, :, datamodel), ...
                                out{nsub}(:, :, datamodel), ...
                                fittedmodel ...
                            ), ...
                        [1, .5, .5, 0, 0], ...
                        [], [], [], [], ...
                        [0, 0, 0, -2, -1], ...
                        [Inf, 1, 1, 2, 1], ...
                        [], ...
                        options ...
                    );

                parameters{fittedmodel}(nsub, :, datamodel) = p;
                lpp(fittedmodel, datamodel, nsub) = l;
                report{fittedmodel}(nsub, datamodel) = rep;
                gradient{fittedmodel}{nsub, datamodel} = grad;
                hessian{fittedmodel}{nsub, datamodel} = hess;

            end
        end

        waitbar( ...
            nsub/subjecttot, ... % Compute progression
            w, ...
            sprintf('Fitting subject %d for cond %s ', nsub, str) ...
        );

    end
    data = containers.Map({'parameters', 'lpp'},....
            {parameters, lpp}...
        );

    save(sprintf('fit_sim/%s', str), 'data');
end

%     tmax = length(con{1}(:, :, datamodel));
%     nfpm = [2, 3, 3, 3, 3, 5];
%     
%     aic = cell(nmodel, 1, 1);
%     bic = cell(nmodel, 1, 1);
%     aicpost = cell(nmodel, 1, 1);
%     bicpost = cell(nmodel, 1, 1);
%     aicout = cell(nmodel, 1, 1);
%     bicout = cell(nmodel, 1, 1);
% 
%     %% to correct
%     for fittedmodel = whichmodel
%         for datamodel = whichmodel
%             
%             [
%                 aic{fittedmodel}(1:subjecttot, datamodel),...
%                 bic{fittedmodel}(1:subjecttot, datamodel),...
%             ] = aicbic(...
%                     -lpp{fittedmodel}(1:subjecttot, datamodel),....
%                     ones(subjecttot, 1, 1)*nfpm(fittedmodel),... % nparams
%                     ones(subjecttot, 1, 1)*tmax... % nobs
%             );
%             
%             %
%             [
%                 aicpost{fittedmodel},...
%                 aicout{fittedmodel},...
%             ] = VBA_groupBMC(aic{fittedmodel}(1:subjecttot, datamodel));
%         
%             
%         
%             [
%                 bicpost{fittedmodel},...
%                 bicout{fittedmodel},...
%             ] = VBA_groupBMC(bic{fittedmodel}(1:subjecttot, datamodel));
% 
% 
%             %bic{fittedmodel}(1:subjecttot, datamodel) = ...
%                 %-2 * -lpp{fittedmodek}(1:subjecttot, datamodel)...
%                 %+ nfpm(datamodel) * log(tmax);
%             
%             %aic{fittedmodel}(1:subjecttot, datamodel) = ...
%                 %-2 * -lpp{fittedmodek}(1:subjecttot, datamodel)...
%                 %+ nfpm(datamodel) * log(tmax);
%             %bic(86:105, n) = -2 * -lpp(86:105, n) + nfpm(n) * log(96*2);
%             % l2 is already positive
%             % aic(:,n)=lpp(:,n)+2*nfpm(n);
%             %
%         end
%     end
%     
%     %% Plot
%     
%     tbl = table();
%     h = heatmap(tbl,'Smoker','SelfAssessedHealthStatus','ColorVariable','Age');
    
%end

