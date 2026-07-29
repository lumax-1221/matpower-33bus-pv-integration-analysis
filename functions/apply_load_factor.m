function mpc = apply_load_factor(mpc, loadFactor)
%APPLY_LOAD_FACTOR Scale active and reactive load from the supplied case.

define_constants;
mpc.bus(:, PD) = mpc.bus(:, PD) * loadFactor;
mpc.bus(:, QD) = mpc.bus(:, QD) * loadFactor;
end

