function [bestX, bestF, history] = custom_pso_fallback(objFun, lb, ub, options)
%CUSTOM_PSO_FALLBACK Small reproducible PSO implementation.

if nargin < 4, options = struct(); end
if ~isfield(options, 'SwarmSize'), options.SwarmSize = 12; end
if ~isfield(options, 'MaxIterations'), options.MaxIterations = 15; end
if ~isfield(options, 'Display'), options.Display = 'iter'; end

nVar = numel(lb);
nPop = options.SwarmSize;
maxIter = options.MaxIterations;
w = 0.72;
c1 = 1.49;
c2 = 1.49;

X = lb + rand(nPop, nVar) .* (ub - lb);
V = zeros(nPop, nVar);
pBest = X;
pBestF = inf(nPop, 1);

for i = 1:nPop
    pBestF(i) = objFun(X(i, :));
end
[bestF, idx] = min(pBestF);
bestX = pBest(idx, :);
history = table((0:maxIter)', nan(maxIter + 1, 1), ...
    'VariableNames', {'Iteration', 'BestObjective'});
history.BestObjective(1) = bestF;

for it = 1:maxIter
    for i = 1:nPop
        V(i, :) = w * V(i, :) ...
            + c1 * rand(1, nVar) .* (pBest(i, :) - X(i, :)) ...
            + c2 * rand(1, nVar) .* (bestX - X(i, :));
        X(i, :) = min(max(X(i, :) + V(i, :), lb), ub);
        f = objFun(X(i, :));
        if f < pBestF(i)
            pBestF(i) = f;
            pBest(i, :) = X(i, :);
            if f < bestF
                bestF = f;
                bestX = X(i, :);
            end
        end
    end
    history.BestObjective(it + 1) = bestF;
    if strcmpi(options.Display, 'iter')
        fprintf('Fallback PSO iter %d/%d best J = %.6g\n', it, maxIter, bestF);
    end
end
end
