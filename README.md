# physvalue  - Physical value computation in Lua


## Overview
Physical (or scientific) values (or quantities) are expressed as the 
numerical factor and a unit. If you do arithmetics with physical values
you must take into account both:
  * the number and
  * the unit.

This Lua module helps you to keep track of the units in your computation in lua scripts.


The general idea for this module has been taken from the project [**Lua Physics Calculator**](https://github.com/RussellSprouts/Lua-Physics-Calculator)
of [Ryan Russell](https://github.com/RussellSprouts) (thank you very much for all the cool ideas!).
You should have a look at the **Physics Calculator** if you want to calculate in a lua shell 
interactively - it's sensationally easy! If you plan to write a bigger Lua program and you like the OOP style
you might want to go with **physvalue**.

