------------------------------------------------------------------------------------------------------------------------
-- Model Title: Op-amp, 3-pin, Ideal
-- Entity Name: opamp_3pin_ideal
-- Author: Mike Donnelly, Mentor Graphics
-- Created: 2014/10/02
-- Last update:
------------------------------------------------------------------------------------------------------------------------
-- Description: Operational amplifier (op-amp) with 3 pins and minimal parasitic effects
--
-- This model provides the basic characteristics of an op-amp, including user specified open-loop gain "AVOL" and
-- gain bandwidth product "GBWP". The model provides single-pole frequency roll-off. The user can also specify the
-- input resistance "Rin" and output resistance "Rout".
--
-- Because this model does not provide power pins nor any type of rail voltage limiting, it is primarily used in circuit
-- design applications for early concept exploration and device requirements definition. For more accurate modeling of
-- in-circuit constraints and device parasitic effects, a datasheet characterizable op-amp model is also available.
--
-- The internal quantity "power_output", while not necessary for implementing the opamp behavior, can be viewed in the
-- simulation results and provides useful design information about the power that is being delivered to the external
-- electrical circuit.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.math_real.all;
use IEEE.electrical_systems.all;
use IEEE.energy_systems.all;

entity opamp_3pin_ideal is

   generic (Rin  : resistance := 1.0e6;    -- Input resistance [Ohm]
            Rout : resistance := 100.0;    -- Output resistance [Ohm]
            AVOL : real       := 100.0e3;  -- Open loop gain [no units]
            GBWP : real       := 1.0e6);     -- Gain-Bandwidth Product [Hz]
            
  port (terminal in_pos, in_neg, output : electrical);

end entity opamp_3pin_ideal;


architecture default of opamp_3pin_ideal is

  constant freq_pole : real        := GBWP / AVOL;         -- Single pole low-pass filter (LPF) frequency [Hz]
  constant w_pole    : real        := math_2_pi*freq_pole; -- LPF radian frequency [radians/sec]
  constant num       : real_vector := (0 => AVOL);         -- LaPlace transfer function numerator coefficients
  constant den       : real_vector := (1.0, 1.0/w_pole);   -- LaPlace transfer function denominator coefficients

  quantity v_in across i_in through in_pos to in_neg;
  quantity v_out across i_out through output;
  quantity power_output : power; 

begin

  i_in  == v_in / Rin;
  v_out == v_in'ltf(num, den) + i_out*Rout;
  
  --- For information only
  power_output == -1.0*v_out*i_out;

end architecture default;