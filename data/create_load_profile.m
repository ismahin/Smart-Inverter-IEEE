function profile = create_load_profile(profileType, dtHours)
%CREATE_LOAD_PROFILE Create normalized 24-hour load profile.

if nargin < 1 || isempty(profileType), profileType = 'mixed'; end
if nargin < 2 || isempty(dtHours), dtHours = 1; end

t = (0:dtHours:(24 - dtHours))';
h = t;

residential = 0.62 ...
    + 0.16 * exp(-((h - 7.5) / 2.2).^2) ...
    + 0.42 * exp(-((h - 19.5) / 3.0).^2) ...
    - 0.08 * exp(-((h - 3.0) / 2.2).^2);
commercial = 0.55 + 0.55 ./ (1 + exp(-(h - 8))) - 0.42 ./ (1 + exp(-(h - 18)));

switch lower(profileType)
    case 'residential'
        values = residential;
    case 'commercial'
        values = commercial;
    case 'low_daytime'
        daytimeDip = 0.48 - 0.18 * exp(-((h - 12.5) / 3.2).^2);
        eveningRecovery = 0.22 * exp(-((h - 20.0) / 3.0).^2);
        values = daytimeDip + eveningRecovery;
    otherwise
        values = 0.65 * residential + 0.35 * commercial;
end

if strcmpi(profileType, 'low_daytime')
    values = min(max(values, 0.30), 0.85);
else
    values = min(max(values, 0.60), 1.20);
end
profile.time_h = t;
profile.multiplier = values(:);
profile.type = profileType;
profile.dtHours = dtHours;
end
