function response = calculate_response_time(time_h, Vseries, net)
%CALCULATE_RESPONSE_TIME Quasi-static voltage settling response indicator.
%
% This is not an EMT transient settling time. It counts time steps required
% for all monitored voltages to return within [Vmin,Vmax] after a
% quasi-static violation caused by load/PV profile changes.

time_h = time_h(:);
inside = all(Vseries >= net.Vmin & Vseries <= net.Vmax, 2);
dt = median(diff(time_h));
if isempty(dt) || isnan(dt), dt = 1; end

maxSteps = 0;
episodes = 0;
k = 1;
while k <= numel(inside)
    if ~inside(k)
        episodes = episodes + 1;
        j = k;
        while j <= numel(inside) && ~inside(j)
            j = j + 1;
        end
        maxSteps = max(maxSteps, j - k);
        k = j;
    else
        k = k + 1;
    end
end

response.violationEpisodes = episodes;
response.maxSettlingSteps = maxSteps;
response.maxSettlingHours = maxSteps * dt;
response.indicator = maxSteps;
end
