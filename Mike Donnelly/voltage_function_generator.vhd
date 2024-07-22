------------------------------------------------------------------------------------------------------------------------
-- Model Title: Voltage Function Generator
-- Entity Name: voltage_function_generator
-- Author: Mike Donnelly, Mentor Graphics
-- Created: 2015/02/13
-- Last update: 2018/04/27 Mike Donnelly, corrected handling for condition pulse_value < initial_value
------------------------------------------------------------------------------------------------------------------------
-- Description: Ideal electrical voltage source, supports Constant, Sinusoidal, Pulse, Ramp, PWL and Noise functions
-- 
-- This model is an ideal voltage source, meaning it has zero Thevenin source impedance. It drives the differential 
-- voltage across its terminals, from pos to neg, with the user specified time-varying function or profile. 
--
-- The user can select one of the six function options available for the current simulation run, by assigning an 
-- integer value to the selection generic "select_function". The following mapping is used:
--
--      select_function Value      Function Type
--               1                 Constant (or "DC")
--               2                 Sine
--               3                 Pulse
--               4                 Ramp
--               5                 PWL (or Table Look-up)
--               6                 Noise (time-domain)
--  
-- For each function, one or more generic parameters specify the characteristics of the voltage profile, as follows:
--
-------- For Constant function (select_function = 1):
-- The value of the constant voltage output is specified by "voltage_level".
--
-------- For sine_function (select_function = 2):
-- The sinusoidal output is specified by the parameters "sine_frequency" and "peak_amplitude". The peak_amplitude is
-- defined as one-half of the peak-to-peak voltage swing. The user can specify the starting phase angle with the 
-- parameter "initial_phase", in degrees. The bias voltage is specified by "offset". Note that if initial_phase does not
-- equal 0.0 or a multiple of 180 degrees, then the voltage output during the DC solution will be non-zero even if 
-- offset = 0.0. The exponential damping or decay factor is given by "df". If df > 0.0, the sinusoidal voltage amplitude
-- will decay with factor e**(-1.0*t*df). The larger df, the faster the amplitude decays toward zero. Conversely, if 
-- df < 0.0, the amplitude will exponentially increase with time. For the default value df = 0.0, the sinusoidal 
-- amplitude is constant.
--
-------- For pulse_function (select_function = 3):
-- The initial and pulse voltage values are specified by "initial_value" and "pulse_value", respectively. The transition
-- times to go between these levels are specified by "transtime_initial_to_pulse" and "transtime_pulse_to_initial". The 
-- delay before the first pulse begins is specified by "start_delay". The pulse duration is specified by "pulse_width", 
-- and the cycle repetition time is specified by "pulse_period".
--
-------- For ramp_function (select_function = 4):
-- The lowest and highest ramp voltage levels are specified by "ramp_low_voltage" and "ramp_high_voltage", respectively.
-- The user can specify the ramp repetition period with the parameter "ramp_period". The time required for the ramp 
-- voltage to rise from ramp_low_voltage to ramp_high_voltage is specified with the parameter ramptime_low_to_high. 
--
----- For PWL_function (select_function = 5):
-- The piece-wise linear (PWL) voltage profile values are specified in the vector "voltage_data". These values are 
-- applied at the times specified in the corresponding vector "time_data". This model provides an option to make the 
-- profile repeat periodically, where the period is the last value in the time_data vector. To generate a periodic 
-- voltage, the user must set the boolean "periodic_on" to TRUE. Otherwise, if periodic_on is FALSE (the default value), 
-- then the voltage level simply remains at the last value in the voltage_data vector, for all time after the last value 
-- in time_data. If a periodic voltage is specified, it is recommended that the beginning and ending voltage_data values
-- be identical. This will prevent voltage discontinuities at the end of each period, and possible simulator convergence
-- problems.
--
----- For noise_function (select_function = 6):
-- The average or DC voltage is specified by "vn_dc", and the AC RMS voltage, within the bandwidth "noise_bw", is
-- specified by "vn_ac_rms". The noise_bw should be set to a value just above the highest frequency of interest for the
-- particular design application. The model will provide a noise spectrum that is relatively flat (< 4% drop-off) at 
-- frequencies below that value. If noise_bw is set to an excessively high value, it will make time domain simulations 
-- run more slowly than necessary. Note: If two or more noise function generators are used in a circuit, the user
-- should assign different "seed" values to the generics "seed1_init" and "seed2_init", so that the instantaneous
-- noise levels will be uncorrelated.
--
----- For AC Analysis with any of the above functions:
-- When used in "AC" or frequency_domain simulation, this model provides an AC stimulus with magnitude "ac_magnitude"
-- and with phase angle "ac_phase" specified in degrees.
--
-- The internal quantity "power_output", while not necessary for implementing the voltage source behavior, can be viewed
-- in the simulation results and provides useful design information about the power supplied to the external electrical
-- circuit.
------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.MATH_REAL.all;
use IEEE.electrical_systems.all;
use IEEE.energy_systems.all;

library MGC_AMS;
use MGC_AMS.conversion.all;
use MGC_AMS.pwl_functions.all;

entity voltage_function_generator is

  generic (select_function : integer := 1;  -- Generator Function Selector. (1 = Constant, 2 = Sine, 3 = Pulse, 4 = Ramp, 5 = PWL, 6 = Noise) [no units]
           --- generic to specify constant function generator
           voltage_level             : voltage       := 0.0;    -- Constant voltage level [V]
           --- generics to specify Sine function generator
           sine_frequency             : real          := 1.0;    -- Frequency [Hz]
           peak_amplitude             : voltage       := 1.0;    -- Peak voltage amplitude, one-half of peak-to-peak amplitude [V]
           offset                     : voltage       := 0.0;    -- Offset or bias voltage [V]
           initial_phase              : real          := 0.0;    -- Initial or starting phase angle at time = 0 [degree]
           df                         : real          := 0.0;    -- Damping factor [1/sec]
           --- generics to specify Pulse function generator
           initial_value              : voltage       := 0.0;    -- Initial value [V]
           pulse_value                : voltage       := 1.0;    -- Pulsed value [V]
           transtime_initial_to_pulse : real          := 1.0e-6; -- Time to transition from initial value to pulse value [sec]
           transtime_pulse_to_initial : real          := 1.0e-6; -- Time to transition from pulse value to initial value [sec]
           start_delay                : real          := 0.0;    -- Delay time to the start of the first pulse [sec]
           pulse_width                : real          := 0.5;    -- Duration of pulse [sec]
           pulse_period               : real          := 1.0;    -- Repetition period (NOTE: pulse_period must be > pulse_width + transtime_initial_to_pulse + transtime_pulse_to_initial) [sec]
           --- generics to specify Ramp function generator
           ramp_low_voltage           : voltage       := 0.0;    -- Lowest voltage value of ramp [V]
           ramp_high_voltage          : voltage       := 1.0;    -- Highest voltage value of ramp [V]
           ramptime_low_to_high       : real          := 0.5;    -- Time for voltage to transition from ramp_low_voltage to ramp_high_voltage. Note: Must be < ramp_period [sec]
           ramp_period                : real          := 1.0;    -- Ramp repetition time or period (NOTE: ramp_period must be > ramptime_low_to_high) [sec]
           --- generics to specify PWL function generator
           voltage_data               : real_vector   := (0.0, 0.0, 10.0,  10.0, 5.0,   5.0, 0.0);   -- Dependent data voltage vector [V]
           time_data                  : real_vector   := (0.0, 0.1,  0.101, 0.2, 0.201, 0.3, 0.301); -- Independent data time vector [sec]
           periodic_on                : boolean       := False;  -- When "True", repeats waveform with period equal to last time value in time_data vector [no units]
           --- generics to specify time-domain noise function generator
           vn_dc                      : voltage       := 0.0;    -- Average (DC) voltage value [Volts]
           vn_ac_rms                  : voltage       := 1.0;    -- "AC" RMS noise voltage value observed within the noise bandwidth [Volts]
           noise_bw                   : real          := 1.0e6;  -- Effective noise bandwidth over which the noise spectrum is flat [Hz]
	       seed1_init                 : positive      := 231;     -- Initial value of seed1. (1 <= seed1_init <= 2147483562)
           seed2_init                 : positive      := 71592;   -- Initial value of seed2. (1 <= seed2_init <= 2147483562)
           --- generics to specify source for AC Analysis
           ac_magnitude               : voltage       := 0.0;    -- AC magnitude [V]
           ac_phase                   : real          := 0.0);   -- AC phase [degree]

  port (terminal pos, neg : electrical);
    
end entity voltage_function_generator;

  
architecture default of voltage_function_generator is
  
  --- Common to all functions
  quantity v across i through pos to neg;
  quantity ac_spec : real spectrum ac_magnitude, math_2_pi*ac_phase/360.0;
  quantity power_output : power;   

  -- For Sine
  -- Function to set the maximum step size of the simulator to 20 steps per cycle.
  function calc_limit(local_frequency : real; local_select_function : integer) return real is
    variable lim : real;
  begin
    if local_frequency = 0.0 or local_select_function /= 2 then
      lim := 1.0e12;
    elsif local_frequency < 0.0 then
      lim := 1.0 / (-20.0 * local_frequency);
    else
      lim := 1.0 / (20.0 * local_frequency);
    end if;
    return lim;
  end function;
  constant sine_step_limit : real := calc_limit(sine_frequency, select_function);
  limit v : voltage with sine_step_limit;

  -- For Pulse
  signal   pulse_signal                    : voltage := initial_value;
  constant pulse_start_delay_time          : time    := real2time(start_delay);
  constant pulse_width_time                : time    := real2time(pulse_width);
  constant transtime_initial_to_pulse_time : time    := real2time(transtime_initial_to_pulse);
  constant pulse_period_time               : time    := real2time(pulse_period);
  constant pulse_inverted : real := sign(pulse_value - initial_value)*1.0;
  
  -- For Ramp
  signal   ramp_signal               : voltage := ramp_low_voltage;
  constant ramp_period_time          : time    := real2time(ramp_period);
  constant ramptime_low_to_high_time : time    := real2time(ramptime_low_to_high);
  constant ramptime_high_to_low      : real    := ramp_period - ramptime_low_to_high;
  
  -- For PWL
  constant pwl_n              : integer                   := time_data'LENGTH;
  signal   pwl_last_time      : real                      := 0.0;

  function NOW_mod_calc (NOW_real : real; periodic_on : boolean;  time_data : real_vector ) return real is 
    variable NOW_modulo : real := 0.0;
  begin 
  	if periodic_on = true then
      NOW_modulo := "Mod"(NOW_real,  time_data( time_data'right));
    else
      NOW_modulo := NOW_real;
    end if;
    return NOW_modulo;
  end function NOW_mod_calc;
  
  -- For Noise
  constant noise_ramp_time : real := 1.0/(10.0*noise_bw);   -- Use 10x sampling for flat (within 4%) noise spectrum within the noise_bw
  constant noise_sample_time : time := real2time(noise_ramp_time);
  constant vn_scale : real := Sqrt(5.055);  --- Note: 5.055 is the ratio of power within 1 x noise_bw vs. the full spectrum, for the sinc function with 10 x noise_bw sample rate
  
  signal v_noise : voltage := 0.0;

begin
    
  if select_function = 2 use
    if domain = quiescent_domain or domain = time_domain use
      v == offset + peak_amplitude*sin(math_2_pi *(sine_frequency*NOW + initial_phase/360.0))*EXP(-NOW*df);
    else
      v == ac_spec;
    end use;   
  elsif select_function = 3 use
    if domain = quiescent_domain or domain = time_domain use
      if pulse_inverted > 0.0 use
        v == pulse_signal'ramp(transtime_initial_to_pulse, transtime_pulse_to_initial);
      else  --- pulse_value < initial_value
        v == pulse_signal'ramp(transtime_pulse_to_initial, transtime_initial_to_pulse);
      end use;
    else
      v == ac_spec;
    end use;  
  elsif select_function = 4 use
    if domain = quiescent_domain or domain = time_domain use
      v == ramp_signal'ramp(ramptime_low_to_high, ramptime_high_to_low);
    else
      v == ac_spec;
    end use;  
  elsif select_function = 5 use
    if domain = quiescent_domain or domain = time_domain use
      v == pwl_dim1_flat(NOW_mod_calc(NOW, periodic_on,  time_data),  time_data, voltage_data);
    else
      v == ac_spec;
    end use;
  elsif select_function = 6 use
    if domain = quiescent_domain or domain = time_domain use
      v == vn_dc + v_noise'ramp(noise_ramp_time, noise_ramp_time);
    else
      v == ac_spec;
    end use;
  else  -- default to constant function, select_function = 1
    if domain = quiescent_domain or domain = time_domain use
      v == voltage_level;
    else
      v == ac_spec;
    end use;
  end use;

  --- For information only
  power_output == -1.0*v*i;
  
  -------------- Pulse (special process)
  CreatePulseEvent : process
  begin
  	if select_function = 3 then
      wait until domain = time_domain;
    else
      wait; -- forever
    end if;
    wait for pulse_start_delay_time;
    loop
      pulse_signal <= pulse_value;
      wait for pulse_width_time + transtime_initial_to_pulse_time;
      pulse_signal <= initial_value;
      wait for (pulse_period_time - pulse_width_time - transtime_initial_to_pulse_time);
    end loop;
  end process CreatePulseEvent;
  
  -------------- Ramp (special process)
  CreateRampEvent : process
  begin
  	if select_function = 4 then
      wait until domain = time_domain;
    else
      wait; -- forever
    end if;
    loop
      ramp_signal <= ramp_high_voltage;
      wait for ramptime_low_to_high_time;
      ramp_signal <= ramp_low_voltage;
      wait for (ramp_period_time - ramptime_low_to_high_time);
    end loop;
  end process CreateRampEvent;

  -------------- PWL (special process and break statement)
  -- Process to extract exact time points, used in break to force sharp corners
  pwl_time_sync : process is
    variable count : integer := 0;
  begin
    if select_function = 5 then
      wait until domain = time_domain;
    else
      wait; -- forever
    end if;
    periodic : loop
      if  time_data(0) > 0.0 then
        wait for real2time( time_data(0));
         pwl_last_time <=  time_data(0);
      end if;
      count := 0;
      while count <  time_data'right loop
         pwl_last_time <=  time_data(count);
        wait for (time_data(count + 1) - time_data(count));
        count     := count + 1;
      end loop;
      if not periodic_on then
        exit; -- exit periodic loop and wait forever
      end if;
    end loop periodic; 
    wait;     -- forever
  end process pwl_time_sync;

  break on  pwl_last_time;  -- force analog time step at pwl transition points

  -------------- Noise (special process)
  Create_v_noise_sequence : process
    variable seed1 : positive := seed1_init;
    variable seed2 : positive := seed2_init;
    variable rn_uniform1, rn_uniform2 : real := 0.5; -- Two uniformly distributed random numbers that vary between 0.0 and 1.0
    variable rn_normal : real := 0.0;                -- Normally distributed random number with mean 0.0 and variance 1.0
  begin
  	if select_function = 6 then
      wait until domain = time_domain;
    else
      wait; -- forever
    end if;
    loop
      wait for noise_sample_time;			
      uniform(seed1, seed2, rn_uniform1);
      uniform(seed1, seed2, rn_uniform2);
      rn_normal := Sqrt(-2.0*log(rn_uniform1))*Cos(2.0*Math_pi*rn_uniform2); -- Box-Mueller transform from uniform to normal distribution
      v_noise <= vn_scale*vn_ac_rms*rn_normal;
    end loop;
  end process Create_v_noise_sequence;

end architecture default;