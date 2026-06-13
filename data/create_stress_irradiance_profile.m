function profile = create_stress_irradiance_profile(dtHours)
%CREATE_STRESS_IRRADIANCE_PROFILE Clear-sky high irradiance stress profile.

if nargin < 1 || isempty(dtHours), dtHours = 1; end
t = (0:dtHours:(24 - dtHours))';
solar = sin(pi * (t - 6) / 12);
values = max(0, solar).^1.10;
values(values > 0.85) = 1.0;

profile.time_h = t;
profile.irradiance = min(max(values(:), 0), 1);
profile.type = 'stress_clear_sky';
profile.dtHours = dtHours;
end
