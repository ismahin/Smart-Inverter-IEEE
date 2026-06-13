function lf = bfs_loadflow_ieee33(net, Pnet_pu, Qnet_pu, options)
%BFS_LOADFLOW_IEEE33 Backward/forward sweep load flow for IEEE 33-bus.
%
% Pnet_pu and Qnet_pu are net demand at each bus. Positive values consume
% power, while negative values inject power into the feeder.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~isfield(options, 'maxIter'), options.maxIter = 100; end
if ~isfield(options, 'tol'), options.tol = 1e-7; end

Pnet_pu = Pnet_pu(:);
Qnet_pu = Qnet_pu(:);
validateattributes(Pnet_pu, {'numeric'}, {'numel', net.nBus, 'finite'});
validateattributes(Qnet_pu, {'numeric'}, {'numel', net.nBus, 'finite'});

from = net.branch(:, 1);
to = net.branch(:, 2);
Z = net.branch(:, 5) + 1i * net.branch(:, 6);

V = ones(net.nBus, 1);
V(net.slackBus) = 1 + 0i;
Ibranch = zeros(net.nBranch, 1);
converged = false;

for iter = 1:options.maxIter
    Vprev = V;
    S = Pnet_pu + 1i * Qnet_pu;
    Iload = conj(S ./ V);
    Iload(net.slackBus) = 0;

    for k = net.nBranch:-1:1
        downstreamBranches = find(from == to(k));
        Ibranch(k) = Iload(to(k)) + sum(Ibranch(downstreamBranches));
    end

    V(net.slackBus) = 1 + 0i;
    for k = 1:net.nBranch
        V(to(k)) = V(from(k)) - Z(k) * Ibranch(k);
    end

    if max(abs(V - Vprev)) < options.tol
        converged = true;
        break;
    end
end

Ploss_pu = sum((abs(Ibranch).^2) .* real(Z));
Qloss_pu = sum((abs(Ibranch).^2) .* imag(Z));

lf.V = V;
lf.Vmag = abs(V);
lf.Vangle = angle(V);
lf.Ibranch = Ibranch;
lf.iter = iter;
lf.converged = converged;
lf.Ploss_pu = Ploss_pu;
lf.Qloss_pu = Qloss_pu;
lf.Ploss_kW = Ploss_pu * net.baseMVA * 1000;
lf.Qloss_kVAr = Qloss_pu * net.baseMVA * 1000;
end
