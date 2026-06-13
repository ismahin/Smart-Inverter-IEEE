function profile = create_irradiance_profile(profileType, dtHours)
%CREATE_IRRADIANCE_PROFILE Create normalized 24-hour solar irradiance.

if nargin < 1 || isempty(profileType), profileType = 'clear_sky'; end
if nargin < 2 || isempty(dtHours), dtHours = 1; end

t = (0:dtHours:(24 - dtHours))';
solar = sin(pi * (t - 6) / 12);
clearSky = max(0, solar).^1.35;

switch lower(profileType)
    case 'clear_sky'
        values = clearSky;
    case 'partial_cloud'
        cloud = 1 ...
            - 0.45 * exp(-((t - 11.0) / 1.0).^2) ...
            - 0.30 * exp(-((t - 14.5) / 0.9).^2);
        values = clearSky .* max(0.25, cloud);
    case 'low_irradiance'
        values = 0.45 * clearSky;
    otherwise
        error('Unknown irradiance profile type: %s', profileType);
end

profile.time_h = t;
profile.irradiance = min(max(values(:), 0), 1);
profile.type = profileType;
profile.dtHours = dtHours;
end
