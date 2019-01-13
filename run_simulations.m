% This script runs the simulations
close all

addpath './simulation'
addpath './computation'
addpath './utils'

data = load('fit_exp/parameters.mat');
fit_params = data.parameters;

%% -------------------- Define common parameters --------------------- %
%% both 
% Define array of conditions
conds = repelem(1:4, 48);
tmax = length(conds);  % 4 * 48 trials

%% -------------------- Define params status quo conditions -----------%
% when reversal occurs
t_reversal = containers.Map(...
    {'statusquo1', 'statusquo2'},...
    {[72, 112, 128, 156, 168, 180], [60, 120, 180]});

% rewards are always the same
r = containers.Map(...
    {'statusquo1', 'statusquo2'},...
    {repelem({{[-1, 1], [-1, 1]}}, tmax), ...
    repelem({{[-1, 1], [-1, 1]}}, tmax)});

% define probabilities
p = containers.Map({'statusquo1', 'statusquo2'},...
    {repelem({{[0.25, 0.75], [0.75, 0.25]}}, tmax),...
    repelem({{[0.25, 0.75], [0.75, 0.25]}}, tmax)});

% apply reversals to probabilities
k = keys(t_reversal);
for i = 1:length(k)
    temp_t_reversal = t_reversal(k{i});
    for t = 1:tmax
        if ismember(t, temp_t_reversal)
            ptemp = p(k{i});
            rtemp = r(k{i});
            for t2 = t:tmax
                ptemp{t2} = flip(ptemp{t2});
                rtemp{t2} = flip(rtemp{t2});
            end
            p(k{i}) = ptemp;
            r(k{i}) = rtemp;
        end
    end
    clear ptemp;
    clear rtemp;
end

%% -------------------- Define params risk condition --------------------%
ncond = length(unique(conds));
rewards = cell(ncond, 1, 1);
probs = cell(ncond, 1, 1);

% AB
rewards{1} = {[0, 0], [-1, 1]};
probs{1} = {[0.75, 0.25], [0.25, 0.75]};
% CD
rewards{2} = {[0, 0], [-1, 1]};
probs{2} = {[0.75, 0.25], [0.75, 0.25]};
% EF
rewards{3} = {[0, 0], [-1, 1]};
probs{3} = {[0.75, 0.25], [0.5, 0.5]};
% GH
rewards{4} = {[0, 0], [-1, 1]};
probs{4} = {[0.25, 0.75], [0.75, 0.25]};

r_risk = repelem({{}}, tmax);
p_risk = repelem({{}}, tmax);

for t = 1:tmax
    r_risk{t} = rewards{conds(t)};
    p_risk{t} = probs{conds(t)};
end

% add risk rewards and probs to map object
r('risk') = r_risk;
p('risk') = p_risk;

%% ----------------  run simulations ---------------------------- % 
% get new keys
k = keys(r);
% declare progression bar
w = waitbar(0, 'Running condition');
for i = 1:length(k)
    waitbar(i/length(k), w, sprintf('Running condition %s', k{i})); 
    
    sim_params = containers.Map(...
        {'tmax', 'p', 'r', 'conds'},...
        {tmax, p(k{i}), r(k{i}), conds}...
    );
    
    data = simulation(fit_params, sim_params);
    save(sprintf('data_sim/%s', k{i}), 'data');
    clear data;
end


