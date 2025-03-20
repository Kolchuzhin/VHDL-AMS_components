## Modeling partial differential equations in VHDL-AMS
[doi:10.1109/SOC.2003.1241540](https://doi.org/10.1109/SOC.2003.1241540)

## VHDL-AMS based modeling and simulation of mixed-technology microsystems: a tutorial
[doi:10.1016/j.vlsi.2005.12.002](https://doi.org/10.1016/j.vlsi.2005.12.002)

* Example 1: transmission line connected to an electrical circuit

pulse source(simple) GENERIC map (amplitude => 1.0, delay =>10.0е-9, duration => 10.0е-9)

transmission_line(behav) GENERIC map (Length => 0.5, L => 250.0е-9, С => 100.0е-12, N => 50)

WORK IN PROGRESS: https://explore.partquest.com/designs/vhdl-ams-model-transmission-line

* Example 3: MEMS filter

VS: ENTITY gaussian source(simple) GENERIC map (amplitude => 1.0, tau =>3.0е-9, Т => 0.25е-9)

WORK IN PROGRESS
