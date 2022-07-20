------------------------------------------------------------------------------------------------------------------------
--Model Title: Peltier TEC
--Entity Name: Peltier_TEC
-- Author: Mike Donnelly
-- Created: 2/27/2017 11:59 am
-- Last update: 3/3/2017 Fixed error in polarity definition of Te_C
------------------------------------------------------------------------------------------------------------------------
-- Description: Peltier thermo-electric cooler model
--
-- This model is based on a technical paper: "Analysis of Thermoelectric Coolers by
-- a Spice-Compatible Equivalent-Circuit Model", by Simon Lineykin and Sam Ben-Yaakov
-- IEEE Power Electronics Letters, Vol 3, No. 2, June 2005. It directly implements the 
-- electro-thermal characteristics and interactions described in that reference paper,
-- including conductive heat transfer, Joule heating, Peltier cooling/heating and 
-- Seebeck electrical power generation. Where the reference went on to define an
-- electrical equivalent circuit or "macro-model" suitable for Spice simulators, this
-- model leverages VHDL-AMS's direct (native) expression of the energy conservation
-- behavior and equations.
--
-- The user can specify parameters that are typically provided on a manufacturer's
-- datasheet. These include the maximum differential temperature "DeltaTmax" that
-- the device can develop (i.e. under conditions of no net heat transfer). This occurs
-- when the emitting (hot) plate temperature is equal to "Temp_C_hot", and with 
-- applied voltage "Vmax" and current "Imax" at the electrical terminals (p to n). The
-- default parameter values are for a CUI CP60340 Peltier Module, which is capable
-- of providing approximately 30 Watts of cooling power transfer.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.ELECTRICAL_SYSTEMS.all;
use IEEE.THERMAL_SYSTEMS.all;

library SVWebLib;
use SVWebLib.THERMAL_C_SYSTEMS.all;

entity Peltier_TEC is

  generic (DeltaTmax    : real      := 75.0; -- Maximum temperature differential supported (when hot side is at temperature Temp_C_hot) [degC or K]
                 Temp_C_hot : real       := 50.0; -- Hot side temperature for which Delta_Tmax is supported [degC]
                 Vmax             : voltage := 8.6;   -- Voltage for temperature differential DeltaTmax [V]
                 Imax              : current := 6.0);  -- Current required to support differential temperature deltaTmax [A]
    
  port (terminal p, n : electrical;
            terminal th_absorbing, th_emitting : thermal_c);

end entity Peltier_TEC;

architecture default of Peltier_TEC is

  constant Temp_K_hot : temperature := Temp_C_hot + 273.15; -- Hot side temperature for which Delta_Tmax is supported [K]
  
  -- Direct parameter equations from the reference paper (13, 14 and 15)
  constant Rm                 : resistance     := (Vmax/Imax)*((Temp_K_hot - DeltaTmax)/Temp_K_hot); -- Electrical resistance [Ohms]
  constant theta_m        : real                 := (DeltaTmax/(Imax*Vmax))*(2.0*Temp_K_hot/(Temp_K_hot - DeltaTmax));  -- Thermal resistance [(degC or K)/Watt]
  constant alpha_m       : real                 := Vmax/Temp_K_hot; -- Seebeck coefficient [V/K]
  
  quantity v across i through p to n;
  quantity v_Seebeck : voltage;
  quantity q_Seebeck_a, q_Seebeck_e, q_i2Rm, q_conduction : heat_flow_tc;
  quantity Ta_K, Te_K : temperature;
  quantity deltaT across th_emitting to th_absorbing;
  quantity Ta_C across qa through th_absorbing to thermal_c_ref;
  quantity qe through thermal_c_ref to th_emitting;
  quantity Te_C across th_emitting to thermal_c_ref;

begin
  -- Electrical equation(s) (6)
  v_Seebeck == alpha_m*deltaT;
  v                  == v_Seebeck + i*Rm;
  
  Ta_K == Ta_C + 273.15;
  Te_K == Te_C + 273.15;
  
  q_Seebeck_a == alpha_m*Ta_K*i;
  q_Seebeck_e == alpha_m*Te_K*i;
  q_i2Rm == (Rm*i**2)/2.0;
  q_conduction == -1.0*deltaT/theta_m;  -- Conduction heat flow from absorbing to emitting. (-1.0 sign change due to polarity of deltaT, emitting to absorbing) 
  
  -- Thermal equations (1 and 2)
  qa == q_conduction + q_seebeck_a - q_i2Rm;
  qe == q_conduction + q_Seebeck_e + q_i2Rm;
  
end architecture default;