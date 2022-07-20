------------------------------------------------------------------------------------------------------------------------
--Model Title: Solar Panel - Variable
--Entity Name: solar_panel_variable
-- Author: Mike Donnelly
-- Created: 4/27/2017 11:17 am
-- Last update:
------------------------------------------------------------------------------------------------------------------------
-- Description: Solar Panel with rated current, voltage and power, with variable relative-irradiance input
-- 
-- This model provides the electrical current vs. voltage relationship of a solar panel, but
-- also includes a continuous quantity input to specify the instantaneous relative solar 
-- irradiance level. That is, the relative irradiance can have values between 0.0 and 1.0,
-- representing zero irradiance (full shade) to nominal (full sun) levels, respectively. 
-- This value can be changed during simulation, to model time-varying solar irradiance.
--
-- The user can adjust the critical sizing parameters to make the model match panels of
-- various power and current capability. These parameter values are specified for two different
-- irradiance levels, the nominal level and the 20%-of-nominal level, indicated by "_20pct" 
-- appended to each parameter name. For example, the nominal open-circuit voltage is specified 
-- by "Voc", and the open circuit voltage at 20%-of-nominal irradiance is specified by  "Voc_20pct". 
-- The other sizing parameters include: Short-circuit current ("Isc", "Isc_20pct") and Maximum
-- Power Output ("Pmax", "Pmax_20pct"). The user can specify the panel's maximum power point
-- voltage using ("Vmp", "Vmp_20pct"). This allows the model to represent the the voltage shift of
-- the maximum power point vs. irradiance.
--
-- These parameters define two distinct current vs. voltage curves, and the model interpolates
-- between them for relative irradiance levels in the range [0.2 to 1.0]. For relative-irradiance
-- levels below 0.2, the model simply reduces the current of the 20% curve in proportion. This
-- model also includes a leakage resistance "Rleak" that provides an internal bypass current
-- path between terminals p and n.
--
-- The internal quantity "power_output", while not necessary for implementing the solar panel 
-- behavior, can be viewed in the simulation results and provides useful design information 
-- about the instantaneous power being produced.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.ELECTRICAL_SYSTEMS.all;
use IEEE.energy_systems.all;

entity solar_panel_variable is

  generic (Voc : voltage := 21.0;                  -- Open-circuit voltage [V]
                  Isc : current  := 4.0;                    -- Short-circuit current [A]
                  Pmax : power := 60.0;               -- Maximum power output [Watts]
                  Vmp : voltage := 17.0;                -- Voltage at maximum power point [V]
                  Voc_20pct : voltage := 19.0;      -- Open-circuit voltage at 20% of the nominal solar irradiance level [V]
                  Isc_20pct : current  := 1.0;         -- Short-circuit current at 20% of the nominal solar irradiance level [A]
                  Pmax_20pct : power := 12.0;    -- Maximum power output at 20% of the nominal solar irradiance level [Watts]
                  Vmp_20pct : voltage := 14.0;    -- Voltage at maximum power point at 20% of the nominal solar irradiance level [V]
                  Rleak : resistance := 1.0e6);      -- Panel bypass or leakage resistance [Ohm]
  
  port (quantity relative_irradiance : in  real;
            terminal p, n  : electrical);

  begin
 
  assert Vmp < Voc
    report "Vmp must be less than Voc"
    severity error;
    
  assert Pmax/Vmp < Isc
    report "The maximum power point current, Pmax/Vmp, must be less than Isc"
    severity error;
    
  assert Vmp_20pct < Voc_20pct
    report "Vmp_20pct must be less than Voc_20pct"
    severity error;
    
  assert Pmax_20pct/Vmp_20pct < Isc_20pct
    report "The maximum power point current at 20% irradiance, Pmax_20pct/Vmp_20pct, must be less than Isc_20pct"
    severity error;

end entity solar_panel_variable;

architecture default of solar_panel_variable is    
  quantity vout across i through p to n;
  quantity x, y : real; -- Scaled versions of vout and iout (for nominal irradiance)
  constant xm : real := Vmp/Voc;
  constant ym : real := (Pmax/Vmp)/Isc;
  constant k1 : real := -1.0*ym/xm;

  quantity x_20pct, y_20pct : real; -- Scaled versions of vout and iout (for 20% irradiance)
  constant xm_20pct : real := Vmp_20pct/Voc_20pct;
  constant ym_20pct : real := (Pmax_20pct/Vmp_20pct)/Isc_20pct;
  constant k1_20pct : real := -1.0*ym_20pct/xm_20pct;
  
  function limit_xf( xm, ym : real ) return real is
    variable xf, result     : real;
  begin
     xf := xm - 3.0*(1.0 - ym)*xm/ym;
    if xf < 0.0 then
      result := 0.0;
    else
      result := xf;
    end if;
    return result;
  end function limit_xf;
   
  constant xf : real := limit_xf(xm, ym);
  constant a1 : real := 1.0 - ym;
  constant b1 : real := -1.0*k1*(xm - xf) + (ym - 1.0);
  constant k2 : real := 0.5*(2.0*ym/(1.0 - xm)**2 + 4.0*(ym - ym*(1.0 - xm)/xm)/(1.0 - xm)**2)*(xm -  1.0);
  constant a2 : real := k1 * (1.0 - xm) + ym;
  constant b2 : real := -1.0*k2*(1.0 - xm) - ym;

  constant xf_20pct : real := limit_xf(xm_20pct, ym_20pct);
  constant a1_20pct : real := 1.0 - ym_20pct;
  constant b1_20pct : real := -1.0*k1_20pct*(xm_20pct - xf_20pct) + (ym_20pct - 1.0);
  constant k2_20pct : real := 0.5*(2.0*ym_20pct/(1.0 - xm_20pct)**2 + 4.0*(ym_20pct - ym_20pct*(1.0 - xm_20pct)/xm_20pct)/(1.0 - xm_20pct)**2)*(xm_20pct -  1.0);
  constant a2_20pct : real := k1_20pct * (1.0 - xm_20pct) + ym_20pct;
  constant b2_20pct : real := -1.0*k2_20pct*(1.0 - xm_20pct) - ym_20pct;      
      
  quantity iout : current ;
  quantity power_output : power;
 
  begin
  
  procedural is
  begin
    x := vout / Voc;
    if x < xf then
       y := 1.0;
    elsif x < xm then
      y := (1.0 - (x - xf)/(xm - xf)) + ((x - xf)/(xm - xf))*ym + ((x - xf)/(xm - xf))*(1.0 - (x - xf)/(xm - xf))*(a1*(1.0 - (x - xf)/(xm - xf)) + b1*((x - xf)/(xm - xf)));
    elsif x < 1.0 then
      y := (1.0 - (x - xm)/(1.0 - xm))*ym + ((x - xm)/(1.0 - xm))*(1.0 - (x - xm)/(1.0 - xm))*(a2*(1.0 - (x - xm)/(1.0 - xm)) + b2*((x - xm)/(1.0 - xm)));
    else  -- x >= 1.0
      y := k2*(x - 1.0);
    end if;
  
    x_20pct := vout / Voc_20pct;
    if x_20pct < xf_20pct then
       y_20pct := 1.0;
    elsif x_20pct < xm_20pct then
      y_20pct := (1.0 - (x_20pct - xf_20pct)/(xm_20pct - xf_20pct)) + ((x_20pct - xf_20pct)/(xm_20pct - xf_20pct))*ym_20pct + ((x_20pct - xf_20pct)/(xm_20pct - xf_20pct))*(1.0 - (x_20pct - xf_20pct)/(xm_20pct - xf_20pct))*(a1_20pct*(1.0 - (x_20pct - xf_20pct)/(xm_20pct - xf_20pct)) + b1_20pct*((x_20pct - xf_20pct)/(xm_20pct - xf_20pct)));
    elsif x_20pct < 1.0 then
      y_20pct := (1.0 - (x_20pct - xm_20pct)/(1.0 - xm_20pct))*ym_20pct + ((x_20pct - xm_20pct)/(1.0 - xm_20pct))*(1.0 - (x_20pct - xm_20pct)/(1.0 - xm_20pct))*(a2_20pct*(1.0 - (x_20pct - xm_20pct)/(1.0 - xm_20pct)) + b2_20pct*((x_20pct - xm_20pct)/(1.0 - xm_20pct)));
    else  -- x_20pct >= 1.0
      y_20pct := k2_20pct*(x_20pct - 1.0);
    end if;
    
    if relative_irradiance >= 1.0 then -- Clip at maximum output current for given voltage
      iout := Isc*y - vout/rleak;
    elsif relative_irradiance > 0.2 then  -- interpolation between 20% and 100%
      iout := (relative_irradiance/0.8 - 0.25)*Isc*y + ((1.0 - relative_irradiance)/0.8)*Isc_20pct*y_20pct - vout/rleak;
    elsif relative_irradiance > 0.0 then  -- scale linearly  below 20%
      iout := (relative_irradiance/0.2)*Isc_20pct*y_20pct - vout/rleak;
    else -- relative_irradiance <= 0.0, no solar-generated current
       iout := -1.0*vout/rleak;
    end if;
  end procedural;
  
  i == -1.0*iout;
      
  --- For information only
  power_output == vout*iout;

end architecture default;