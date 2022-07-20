------------------------------------------------------------------------------------------------------------------------
-- Model Title: Thermistor - NTC Type
-- Entity Name: thermistor_ntc
-- Author: Mike Donnelly
-- Created: 3/20/2017 4:18 pm
-- Last update:
------------------------------------------------------------------------------------------------------------------------
-- Description: Thermistor model with negative temperature coefficient (NTC)
--
-- This thermistor model has two electrical terminals and one thermal terminal. It interacts with an electrical circuit in
-- in the normal way, except that the electrical resistance is a function of the varying temperature observed at the
-- thermal connection. The thermal terminal must be connected to an external thermal network, which can include both 
-- static and dynamic thermal elements (e.g. thermal heat-transfer resistance and heat capacitance).
--
-- The user can specify the electrical resistance measured at 25 degC, using the generic parameter "resistance_25C". The
-- resistance variation is specified by the parameter "beta", such that the steady-state resistance vs. temperature is:
--
--   resistance_at_temp = resistance_25C*e^(-1.0*beta*(1.0/(25 + 273.15) - 1.0/temperature(K)))
--
-- As can be seen from this non-linear equation, the resistance value will decrease as the measured temperature (in Kelvin) 
-- increases above (25 + 273.15) = 298.15K, which is the calibration temperature of 25 degC. The minimum resistance 
-- is limited by the parameter "scale_for_min_r", which specifies the smallest allowed fraction of resistance_25C, with
-- the default value of 10%. For transients, the parameter "tau" specifies the thermal time constant of the
-- thermistor, to model its limited speed of response to fast temperature changes.
--
-- This model does include the self-heating effect of the thermistor. When there is current in the resistor, the R*I^2
-- "power_dissipated" creates a heat flow that is injected into the external thermal circuit, which may effect the 
-- measured temperature value.
--
-- The default parameter values for this model represent an Ametherm 1DC103J thermistor.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.electrical_systems.all;
use IEEE.math_real.all;
use IEEE.energy_systems.all;  -- Required to recognize type "power"
use IEEE.thermal_systems.all; -- Needed for type "temperature" (in K)

library SVWebLib;
use SVWebLib.thermal_c_systems.all;

library MGC_AMS;
use MGC_AMS.Conversion.all;  -- Provides "convert2Kelvin" function

entity thermistor_ntc is
  
  generic (resistance_25C  : resistance := 10.0e3; -- Electrical resistance at temperature 25 degC [Ohm]
           beta            : real       := 3965.0; -- Beta temperature coefficient [K]
           tau             : real       := 6.0;    -- Resistance time constant [sec]
           scale_for_min_r : real       := 0.1);   -- Scale factor for minimum resistance value (relative to resistance_25C) [no units]
  
  port (terminal p1, p2 : electrical;
        terminal therm  : thermal_c);

end entity thermistor_ntc;


architecture default of thermistor_ntc is

  quantity v across i through p1 to p2;
  quantity resistance_at_temp_fast, resistance_at_temp : resistance;
  quantity temperature_value across therm to thermal_c_ref;
  quantity power_dissipated through thermal_c_ref to therm;
  
  constant temp_25C_in_Kelvin : temperature := convert2kelvin(25.0, Celsius);

begin
  
  procedural is
    variable local_r : resistance;
  begin
    local_r := resistance_25C*exp(-1.0*beta*(1.0/temp_25C_in_Kelvin - 1.0/convert2kelvin(temperature_value, Celsius)));
    if local_r > scale_for_min_r*resistance_25C then
      resistance_at_temp_fast := local_r;
    else
      resistance_at_temp_fast := scale_for_min_r*resistance_25C;  --- The value (scale_for_min_r*resistance_cal) is the minimum resistance allowed
    end if;
  end procedural;

  resistance_at_temp == resistance_at_temp_fast - tau*resistance_at_temp'dot;
  v  == i*resistance_at_temp;
  power_dissipated == v*i;

end architecture default;