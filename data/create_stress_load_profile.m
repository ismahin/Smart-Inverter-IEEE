function profile = create_stress_load_profile(dtHours)
%CREATE_STRESS_LOAD_PROFILE Low-load daytime profile for PV hosting stress.

if nargin < 1 || isempty(dtHours), dtHours = 1; end
t = (0:dtHours:(24 - dtHours))';
values = 0.53 - 0.03 * exp(-((t - 12.5) / 3.4).^2);
values = min(max(values, 0.50), 0.53);

profile.time_h = t;
profile.multiplier = values(:);
profile.type = 'stress_low_daytime';
profile.dtHours = dtHours;
end
