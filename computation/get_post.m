function post = get_post(params, s, a, r, model)

    %pbeta1 = log(gampdf(beta1,1.0262  ,  4.1363));
    %plr1   = log(betapdf(lr1, 0.2500  ,  1.3118));
    %plr2   = log(betapdf(lr2, 0.2500  ,  1.3118));

    p = get_p(model, params);
   
    p = -sum(p);

    l = get_lik(params, s, a, r, model);

    post = p + l;
end

function p = get_p(model, params)

    %% log prior of parameters
    beta1 = params(1); % choice temperature
    lr1 = params(2); % policy or factual learning rate
    lr2 = params(3); % counterfactual or fictif learning rate
    per = params(4); % context learning rate
    pri = params(5);

    %% the parameters based on the first optimzation
    pbeta1 = log(gampdf(beta1, 1.2, 5.0));
    plr1 = log(betapdf(lr1, 1.1, 1.1));
    plr2 = log(betapdf(lr2, 1.1, 1.1));
    pper = log(normpdf(per, 0, 1));
    ppri = log(normpdf(pri, 0, 1));

    switch model
        case 1
            p = [pbeta1, plr1];

        case {2, 3}

            p = [pbeta1, plr1, plr2];

        case 4

            p = [pbeta1, plr1, pper];

        case 5

            p = [pbeta1, plr1, ppri];

        case 6

            p = [pbeta1, plr1, plr2, pper, ppri];
    end
end
%pbeta1 = log(gampdf(beta1,1.2,14.0));
%plr1   = log(betapdf(lr1,2.0,5.2));
%plr2   = log(betapdf(lr2,0.03,0.41));

%pbeta1 = log(gampdf(beta1,1.33,16.01));
%plr1   = log(betapdf(lr1,2.1,9.0));
%plr2   = log(betapdf(lr2,0.3,0.46));
%plr3   = log(betapdf(lr3,0.01,0.02));

function lik = get_lik(params, s, a, r, model)

    beta1 = params(1); % choice temperature
    lr1 = 0; % first learning rate
    lr2 = 0;
    per = 0;
    pri = 0;

    % 1: basic df=2
    % 2: asymmetric neutral df=3
    % 3: asymmetric pessimistic df=3
    % 4: perseveration df=3
    % 5: priors df=3
    % 6: full df=5

    switch model
        case 1
            lr1 = params(2);
        case 2
            lr1 = params(2);
            lr2 = params(3);
        case 3
            lr1 = params(2);
            lr2 = params(3);
            pri = -1;
        case 4
            lr1 = params(2);
            per = params(4);
        case 5
            lr1 = params(2);
            pri = params(5);
        case 6
            lr1 = params(2);
            lr2 = params(3);
            per = params(4);
            pri = params(5);
    end

    % initial previous aice
    lik = 0;
    Q = zeros(8, 2) + pri; %  Q-values
    preva = zeros(8, 1);


    for i = 1:length(a)
        if not(ismember(a(i), [1, 2, 1.5]))
            error(sprintf('choice = %d', a(i)));
        end
            
        if (a(i)) ~= 1.5 % if a choice was performed in time at the first level

            lik = lik + beta1 * (Q(s(i), a(i)) + per * (a(i) == ...
                preva(s(i)))) - log([exp(beta1*(Q(s(i), 1) + per * ...
                (preva(s(i)) == 1))) + exp(beta1*(Q(s(i), 2) + per * (preva(s(i)) == 2)))]);
            
            switch model
            %lik = lik + beta1 * Q(s(i),a(i)) - log(sum(exp(beta1 * Q(s(i),:))));
                case 1 % rescorla wagner classique

                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = Q(s(i), a(i)) + lr1 * deltaI;
                    
                case 2 % asymmetric win stay and lose shift
                    
                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = Q(s(i), a(i)) + lr1 * deltaI * (deltaI > 0) + lr2 * deltaI * (deltaI < 0);
                
                case 3 % asymmetric win stay and lose shift
                    
                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = ...
                        Q(s(i), a(i)) + lr1 * deltaI * (deltaI > 0) + lr2 * deltaI * (deltaI < 0);
                    
                case 4
                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = Q(s(i), a(i)) + lr1 * deltaI;
                    
                case 5
                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = Q(s(i), a(i)) + lr1 * deltaI;
                    
                case 6 % asymmetric win stay and lose shift
                    
                    deltaI = r(i) - Q(s(i), a(i));
                    Q(s(i), a(i)) = Q(s(i), a(i)) + lr1 * deltaI * (deltaI > 0) + lr2 * deltaI * (deltaI < 0);
            end
        end
            preva(s(i)) = a(i);
    end
        % save the choice for the next round (perseverations)
    lik = -lik; % LL vector taking into account both the likelihood
end

