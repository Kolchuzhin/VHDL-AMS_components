------------------------------------------------------------------------------------------------------------------------
-- Model Title: Stop, Translational
-- Entity Name: stop_t
-- Author: Mike Donnelly, Mentor Graphics
-- Created: 2015/02/27
-- Last update:
------------------------------------------------------------------------------------------------------------------------
-- Description: Ideal mechanical stop or travel-limit effect, with translational terminals
--
-- This model represents an ideal mechanical stop or travel-limiting hard-stop effect. This non-linear model provides a
-- force through its translational attachment connections (attach1 -> attach2), but only when the relative displacement
-- across those connections is outside the free-travel range (i.e. between "displacement_min" and "displacement_max").
-- Within the free-travel range, the model contributes no force to the external mechanical system.
--
-- When the relative displacement is outside of the free-travel range, then the model acts like a spring, implementing 
-- Hooke's Law by providing a restoring force that is proportional to the displacement beyond the travel limit. This
-- force value is scaled by the effective stiffness "k_stop". The model also provides a damping effect when in contact
-- with the travel limit, generating an opposing force that is proportional to the relative velocity. This damping 
-- force is scaled by "d_stop".
--
-- The internal quantities "power_input" and "energy_stored", while not necessary for representing the stop behavior, 
-- can be viewed in the simulation results to provide design information about the power input and the potential energy
-- stored in the stop.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.mechanical_systems.all;
use IEEE.ENERGY_SYSTEMS.all;

entity stop_t is

  generic (k_stop           : STIFFNESS    := 1.0e6;   -- Stiffness of stop [N/meter]
           displacement_max : DISPLACEMENT;            -- Maximum displacement [meter]
           displacement_min : DISPLACEMENT := 0.0;     -- Minimum displacement [meter]
           d_stop           : DAMPING      := 1.0e-9); a-- Damping or energy loss factor of stop [N/(meter/sec)]
  
  port (terminal attach1, attach2 : translational);

end entity stop_t;


architecture default of stop_t is

  quantity delta_length across force_value through attach1 to attach2;
  quantity velocity : velocity;
  quantity power_input : power;
  quantity energy_stored : energy;

begin
  
  --- Fundamental Behavior
  velocity == delta_length'dot;

  procedural is
  begin
    if delta_length > displacement_max then
      force_value   := k_stop * (delta_length - displacement_max) + (d_stop * velocity);
      energy_stored := 0.5*k_stop*(delta_length - displacement_max)**2;
    elsif delta_length > displacement_min then
      force_value   := 0.0;
      energy_stored := 0.0;
    else
      force_value   := k_stop * (delta_length - displacement_min) + (d_stop * velocity);
      energy_stored := 0.5*k_stop*(delta_length - displacement_min)**2;
    end if;
  end procedural;

  break on delta_length'above(displacement_min), delta_length'above(displacement_max);
  
  --- For information only
  power_input   == force_value*velocity;

end architecture default;
