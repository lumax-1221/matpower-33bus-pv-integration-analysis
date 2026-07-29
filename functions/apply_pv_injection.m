function mpc = apply_pv_injection(mpc, pvBus, penetration, basePload)
%APPLY_PV_INJECTION 在指定节点施加等效有功光伏注入。

define_constants;
if ~ismember(pvBus, mpc.bus(:, BUS_I))
    error('pvBus %d does not exist in the case.', pvBus);
end
if nargin < 4 || isempty(basePload)
    basePload = sum(mpc.bus(:, PD));
end
pvPower = penetration * basePload;
busIndex = find(mpc.bus(:, BUS_I) == pvBus, 1);
mpc.bus(busIndex, PD) = mpc.bus(busIndex, PD) - pvPower;
end
