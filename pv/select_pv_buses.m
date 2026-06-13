function pvBuses = select_pv_buses(option)
%SELECT_PV_BUSES Return configurable PV interconnection buses.

if nargin < 1 || isempty(option), option = 'default'; end

switch lower(option)
    case 'default'
        pvBuses = [6 14 18 25 30 33];
    case 'end_buses'
        pvBuses = [18 22 25 30 32 33];
    case 'stress_end_buses'
        pvBuses = [18 25 30 31 32 33];
    otherwise
        if isnumeric(option)
            pvBuses = option(:)';
        else
            error('Unknown PV bus selection option: %s', option);
        end
end
end
