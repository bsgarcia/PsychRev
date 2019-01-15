
function recovery()
    % main function that calls the others

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
    models = {'QLearning', 'Asymmetric', 'AsymmetricPessimistic', 'Perseveration', ...
        'Priors', 'Full'};

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
            %'UseParallel', true);

    % iterate on conditions
    for i = 1:length(condlabels)

        w = waitbar(0, 'Get data');
        
        try
            [lpp, parameters] = getdata(condlabels{i});
        catch
            [lpp, parameters] = runfit(condlabels{i}, nmodel, whichmodel, nparam,...
            options, w);
        end
        
        subjecttot = length(lpp(1, 1, :));

        [bic, aic] = computebicaic(lpp, tmax, nmodel, subjecttot, whichmodel);

        % set x and y labels
        xlabels = models;
        ylabels = models;

        % Compute the posterior probabilities
        bicmatrix = computeposterior(...
            bic, whichmodel, nmodel, models, subjecttot, condlabels{i});

        aicmatrix = computeposterior(...
            aic, whichmodel, nmodel, models, subjecttot, condlabels{i});
        
        % plot bic recovery for one condition
        plotheatmap(bicmatrix, xlabels, ylabels,...
            'Simulated data using model x', 'Fitted model',...
            sprintf('BIC Condition %s', condlabels{i}),...
            'mean of posterior probabilities');
        
        % plot bic recovery for one condition
        plotheatmap(aicmatrix, xlabels, ylabels,...
            'Simulated data using model x', 'Fitted model',...
            sprintf('AIC Condition %s', condlabels{i}),...
            'mean of posterior probabilities');
    end
end

%% ---------------------- Plot functions -------------------------------- % 

function plotheatmap(data, xlabels, ylabels, xaxislabel, yaxislabel, titlelabel,...
    cname)

    figure;
    h = heatmap(xlabels, ylabels, data);
    ylabel(yaxislabel);
    xlabel(xaxislabel);
    title(titlelabel);
    ax = gca;     %then ax becomes the handle to the heatmap
    axs = struct(ax);   %and ignore the warning
    c = axs.Colorbar;    %now you have a handle to the colorbar object    
    c.Label.String = cname;
    %set(c.Label, 'Rotation', -360+-90);

end

%% ---------------------- computation functions -------------------------------- % 

function [bic, aic] = computebicaic(lpp, tmax, nmodel, subjecttot, whichmodel)
    % 1: basic df=2
    % 2: asymmetric neutral df=3
    % 3: asymmetric pessimistic df=3
    % 4: perseveration df=3
    % 5: priors df=3
    % 6: full df=5
    nfpm = [2, 3, 3, 3, 3, 5];

    bic = zeros(nmodel, nmodel, subjecttot);
    aic = zeros(nmodel, nmodel, subjecttot);

    for fittedmodel = whichmodel
        bic(fittedmodel, :, :) = -2 * -lpp(fittedmodel, :, :)...
            + nfpm(fittedmodel) * log(tmax);
        
        aic(fittedmodel, :, :) = -2 * -lpp(fittedmodel, :, :)...
            + nfpm(fittedmodel);
       
    end
end

function matrix = computeposterior(...
    criterion, whichmodel, nmodel, models, subjecttot, cond)   
    for datamodel = whichmodel
        %set options
        %options.modelNames = models(whichmodel);
        options.figName = sprintf(...
            '%s condition, data generated using %s', cond, models{datamodel});
        options.DisplayWin = false;
        
        formatedmatrix(1:nmodel, 1:subjecttot) = -criterion(:, datamodel, :);
        
        [posterior, outcome] = VBA_groupBMC(formatedmatrix, options);
        for fittedmodel = whichmodel
            matrix(datamodel, fittedmodel) = mean(posterior.r(fittedmodel, :));
        end
    end
end

function bicmatrix = computepercentagewinning(...
    bic, whichmodel, nmodel, subjecttot)

    bicmatrix = zeros(nmodel, nmodel);
    for datamodel = whichmodel       
        for sub = 1:subjecttot
            [useless, argmin] = min(bic(:, datamodel, sub));
             bicmatrix(datamodel, argmin) = bicmatrix(datamodel, argmin) + 1;
        end
    end
    bicmatrix = bicmatrix ./ (subjecttot/100);
end

%% --------------------------- Get fit data functions ------------ % 

function [lpp, parameters] = getdata(str)
        data = load(sprintf('fit_sim/%s', str));
        lpp = data.data('lpp');
        parameters = data.data('parameters');
end

function [lpp, parameters] = runfit(str, nmodel, whichmodel, nparam,...
    options, w)
    [
        con, ...
        con2,....
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
        waitbar( ...
            nsub/subjecttot, ... % Compute progression
            w, ...
            sprintf('Fitting subject %d for cond %s ', nsub, str) ...
        );
        parfor fittedmodel = whichmodel
            templpp = [];
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
                templpp(datamodel) = l;
                report{fittedmodel}(nsub, datamodel) = rep;
                gradient{fittedmodel}{nsub, datamodel} = grad;
                hessian{fittedmodel}{nsub, datamodel} = hess;

            end
            lpp(fittedmodel, :, nsub) = templpp;
        end
    end
    data = containers.Map({'parameters', 'lpp'},....
            {parameters, lpp}...
    );
    save(sprintf('fit_sim/%s', str), 'data');
    close(w);
end
