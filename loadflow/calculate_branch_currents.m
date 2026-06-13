function Ibranch = calculate_branch_currents(net, V, Pnet_pu, Qnet_pu)
%CALCULATE_BRANCH_CURRENTS Accumulate radial branch currents for a voltage.

from = net.branch(:, 1);
to = net.branch(:, 2);
S = Pnet_pu(:) + 1i * Qnet_pu(:);
Iload = conj(S ./ V(:));
Iload(net.slackBus) = 0;
Ibranch = zeros(net.nBranch, 1);

for k = net.nBranch:-1:1
    downstreamBranches = find(from == to(k));
    Ibranch(k) = Iload(to(k)) + sum(Ibranch(downstreamBranches));
end
end
