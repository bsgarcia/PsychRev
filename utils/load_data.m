
% Load data function
function [con, con2, cho, out, nsubs] = load_data(type, cond)
    
    switch type
        %% -------------------- Load experimental data --------------- %
        case {'experiment', 'exp', 'experiments'}
            
            %%  Experiment 1 data extraction
            cd data_exp1
            nsubs = 0;
            subjects1 = [1:50]
            for sub = subjects1 %or number of subjects with data for 3 sessions
                nsubs = nsubs + 1;
                fprintf('Subject %d\n', nsubs);

                resultname = strcat('exp1_', num2str(sub));
                load(resultname);

                con{nsubs} = data(:, 3); % 1 to 4 as per condition
                cho{nsubs} = data(:, 7) / 2 + 1.5; % 1 for left, 2 for right
                out{nsubs} = (data(:, 8) - 0.5) .* 2; % -1 1
            end
            cd ..

            %%  Experiment 2 data extraction

            cd data_exp2
            subjects2 = [1:35]; % controls

            for sub = subjects2 %or number of subjects with data for 3 sessions
                nsubs = nsubs + 1;
                fprintf('Subject %d\n', nsubs);

                resultname = strcat('exp2_', num2str(sub));
                load(resultname);

                con{nsubs} = data(:, 3); % 1 to 4 as per condition
                cho{nsubs} = data(:, 5) / 2 + 1.5; % 1 for left, 2 for right
                out{nsubs} = (data(:, 8)) .* 2; % -1 1
            end
            cd ..

            %% Experiment 2 data extraction
            cd data_exp3
            subjects3 = [1:20]; % controls

            for sub = subjects3 %or number of subjects with data for 3 sessions
                nsubs = nsubs + 1;
                fprintf('Subject %d\n', nsubs);

                resultname = strcat('Test', num2str(sub), '_Session1');
                load(resultname);

                con{nsubs} = data(:, 4);
                con2{nsubs} = data(:, 4); % 1 to 4 as per condition
                cho{nsubs} = data(:, 6) + 1; % 1 for left, 2 for right
                out{nsubs} = (data(:, 8) - .5) .* 2; % -1 1


                resultname = strcat('Test', num2str(sub), '_Session2');
                load(resultname);

                con{nsubs} = [con{nsubs}; data(:, 4) + 4]; % 1 to 4 as per condition
                con2{nsubs} = [con2{nsubs}; data(:, 4)];
                cho{nsubs} = [cho{nsubs}; data(:, 6) + 1]; % 1 for left, 2 for right
                out{nsubs} = [out{nsubs}; (data(:, 8) - .5) .* 2]; % -1 1

            end
            cd ..
            
        %% -------------------- Load simulation data --------------- %

        case {'sim', 'simulations', 'simulation'}

            if ~exist('cond', 'var')
                error('You should specify a condition');
            end
                
            switch cond
                case 'risk'
                    disp('risk');
                case 'statusquo1'
                    disp('t');
                case 'statusquo2'
                    disp('t');
                otherwise
                    error(['You should specify a valid condition '...
                           '(i.e. risk, statusquo1, statusquo2)']);
            end
    end
            
end
