-------------------------------------------------------------------------------
-- Model Title: VHDL Default Title 
-- Entity Name: VHDL_Default_Title 
-- Author: My Name, Affiliation 
-- Created: 2015/06/07 
-- Last update: 
----------------------------------------------------------------------------------------------
-- Description: This description will appear as a tooltip when component is hovered in browser 
-- 
-- Additional description info can be placed here. It will also be available in the tooltip 
----------------------------------------------------------------------------------------------
 
library IEEE;
-- The 'use' clause allows direct access to items in a given library (e.g. for items related to a given technology type) 
use IEEE.electrical_systems.all;
 
-- The entity specifies how this model interfaces with the outside world 
entity model_template is
 
	-- Generics are the parameters that the user of the model can change from the schematic 
	-- An example of a generic called 'res' of type 'resistance' with units 'Ohm' is shown below 
	-- generic (
		-- res : resistance); -- Generic description [Ohm]
 
	-- Ports represent the pins for the model. These pins are used to connect to other models in the schematic 
	-- An example of two pins, p1 and p2, are specified below. These pins are of type terminal (which means they consist of 
	-- both across and through aspects, and will obey conservation laws). They are also of the electrical subtype (nature) 
	-- which means that the across aspect is voltage and the through aspect is current 
	-- port (
		-- terminal p1, p2 : electrical);
 
end entity model_template;
 
-- The architecture specifies the functionality of the model 
architecture default of model_template is
 
	-- 'Branch' quantities can be used to assign identifiers to across and through pin aspects so they can be used in equations
	-- In the example below, 'v' and 'i' are assigned as the respective across and through aspects for both p1 and p2 
	-- quantity v across i through p1 to p2;
 
begin
 
	-- Equation(s) that govern the model behavior
	-- Example below shows enforcement of Ohm's law using quantities 'v' and 'i', and generic 'res' 
		-- v == i*res;
 
end architecture default;
 
