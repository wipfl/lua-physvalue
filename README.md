# lua-physvalue  - Physical value computation in Lua


## Overview
Physical (or scientific) values (or quantities) are expressed as the 
numerical factor and a unit. If you do arithmetic with physical values
you must take into account both:
  * the number and
  * the unit.

This Lua module helps you to keep track of the units in your computation in lua 
scripts.


The general idea for this module has been taken from the project [**Lua Physics 
Calculator**](https://github.com/RussellSprouts/Lua-Physics-Calculator)
of [Ryan Russell](https://github.com/RussellSprouts) (thank you very much for 
all the cool ideas!).
You should have a look at the **Physics Calculator** if you want to calculate 
in a lua shell 
interactively - it's sensationally easy! If you plan to write a bigger Lua 
program and you like the OOP style
you might want to go with **physvalue**.

## Some examples
You can look at the file example.lua to have some simple examples.
But here is the computation for a bike tour:
```lua
pv=require('physvalue')

-- Define the start and end readings of the speedometer
myBestSpeed = pv:new('BestSpeed', 31.3, 'km/h')
travelStart = pv:new('Start', 12445.4, 'km')
travelEnd = pv:new('End', 12522.6, 'km')
-- The duration of the tour. We must add hours and minutes.
duration = pv:new('Duration', 7, 'h') + pv:new('', 43, 'min')

-- We can compute the average speed as we would do with numbers
averageSpeed = (travelEnd - travelStart) / duration
-- We set a name for the variable
averageSpeed:setId('Speed')

-- We print the variables formatted nicely                                        --Result
print(travelStart:format("#i-8s: #v12.2f #u-8s"))                                 --Start   :     12445.40 km      
print(travelEnd:format("#i-8s: #v12.2f #u-8s"))                                   --End     :     12522.60 km      
print((travelEnd-travelStart):setId('Distance'):format("#i-8s: #v12.2f #u-8s"))   --Distance:        77.20 km      
print(duration:format("#i-8s: #v12.2f #u-8s"))                                    --Duration:         7.72 h       
-- averageSpeed has the internally used SI units
print(averageSpeed:format("#i-8s: #v12.2f #u-8s"))                                --Speed   :         2.78 s^-1*m 
-- We add the desired unit for our output
print(averageSpeed:format("#i-8s: #v12.2f #u-8s", 'km/h'))                        --Speed   :        10.00 km/h     

-- We can compare physical values like numbers
if averageSpeed > myBestSpeed then
  myBestSpeed = averageSpeed
  print('New record!')
else
  -- String concatenation is simple
  print('You missed your best speed of ' .. myBestSpeed )                         --You missed your best speed of 31.3 km/h   
  -- Unit conversion takes place with string concatenation
  print('or ' .. (myBestSpeed .. 'm/s') .. ' in SI units.')                       --or 8.69444 m/s in SI units.
end
```

The output is the following:
```{r}
Start   :     12445.40 km      
End     :     12522.60 km      
Distance:        77.20 km      
Duration:         7.72 h       
Speed   :         2.78 s^-1*m             (this is OK but looks ugly!!)
Speed   :        10.00 km/h               (this looks better)
You missed your best speed of 31.3 km/h   
or 8.69444 m/s in SI units.
```
## Features
### Operators
The class PhysValue supports the Lua operators `+`, `-`, `*`, `/`, and `^` with their normal mathematical meanings.
The operator `..` converts a value into certain units. For example, `pv:new('', 1, 'mm')..'km'` will
give 1e-007 km, the number of kilometers in a millimeter.

### Additional Functions
The class define the following useful functions:

Function Name | Description
------------- | -----------
addUnit (symbol, definition, withoutPrefix)  | Helper function inserts a Unit (with all prefix combinations) to the table PhysValue.u
UnitMatch (b)  | Checks if the unit of self and the unit of b match.
deep_copy (a)  | Helper function: deep copies a physical value.
sqrt ()  | Square root
cbrt ()  | Cubic root
getValue (symbol)  | Get value in target unit.
setPrefUnit (unit)  | Set preferred display unit.
setId (id)  | Set variable id.
format (f, symbol)  | String format.
toJson (symbol)  | Generate JSon string.


### Available Units
Most of the SI units and other common units are available.
  * m - meters
  * g - grams
  * s - seconds
  * A - amperes
  * K - kelvin
  * mol - moles
  * cd - candela
  * rad - radians
  * sr - steradians
  * Hz - hertz
  * N - newtons
  * Pa - pascals
  * J - joules
  * W - watts
  * C - coulombs
  * V - volts
  * F - farrads
  * Ohm - ohms (Ω)
  * S - siemens
  * Wb - webers
  * T - teslas
  * H - henry
  * lm - lumens
  * lx - lux
  * kat - katal
  * min - minutes
  * hr - hours
  * day - days
  * deg - degrees (angle)
  * ha - hectares
  * L - liters
  * tonne - tonnes (metric)
  * Ang - Ångström (Å)
  * eV - elctron volts
  * Da - Dalton, former atomic mass units (amu)
  * mi - miles
  * ft - feet
  * inch - inches
  * lb - mass pounds
  * lbf - pounds force
  * hp - horsepower
  * bar - barometric pressure

### Supported prefixes
Most of the units can be prefixed with the following symbols:
  * k=1e3 - kilo
  * M=1e6 - Mega
  * G=1e9 - Giga
  * T=1e12,-- Tera
  * da=1e1 - deka
  * h=1e2 - hekto
  * d=1e-1 - dezi
  * c=1e-2 - centi
  * m=1e-3 - milli
  * u=1e-6 - micro  
  * n=1e-9 - nano
  * p=1e-12 - pico

### Physical Constants
The table *PhysValue.c* contains the following physical constants:
  * c=PhysValue:new('c', 2.99792458e8, 'm/s') - Speed of light in vacuum
  * e=PhysValue:new('e', 1, 'eV/J*C') - charge of electron
  * G=PhysValue:new('G', 6.67259e-11, 'N*m^2/kg^2') - Newtonian constant of gravity
  * g_0=PhysValue:new('g_0', 9.80665, 'N/kg') - Standard gravity accelaration on earth
  * mElectron=PhysValue:new('mElectron', 9.10939e-31, 'kg') - Mass of electron
  * mNeutron=PhysValue:new('mNeutron', 1.67262e-27, 'kg') - Mass of neutron
  * mProton=PhysValue:new('mProton', 1.67492e-27, 'kg') - Mass of proton
  * epsilon_0=PhysValue:new('epsilon0', 8.854e-12, 'C^2/(N*m^2)') - Electric constant (vacuum permittivity)
  * k=PhysValue:new('k', 8.987551787e9, 'N*m^2/C^2') - Coulomb's constant 1/(4*pi*epsilon_0)
  * N_A=PhysValue:new('N_A', 6.02214129e23, '1/mol') - Avogadro's number

## Caveats
### Temperature Unit conversion not implemented
There is currently no conversion of temperature units, e.g. no conversion from 
Kelvin to Celsius or Fahrenheit. The problem is that these units don't have a 
common zero point, i.e. 0 Kelvin is not 0 Celsius. This gives additional 
problems as one has to specify if a value is an absolute or a relative value (a 
difference). It is not impossible to add this feature but it is not done yet.

### Time conversion
A time can be expressed in hours or minutes or seconds but there is no 
possibility to convert a time value into a string in HH:MM:SS format e.g.. There 
are a lot other tools that can do this. Go ahead with these.

## Dependencies
The module uses [**middleclass**](https://github.com/kikito/middleclass) for 
object-orientation. The necessary file middleclass.lua is added to the 
repository for your convenience.
The unit tests are written with use of 
[**luaunit**](https://github.com/bluebird75/luaunit). The necessary file 
luaunit.lua is added to the repository for your convenience. 

## Documentation
The code is documented using [**ldoc**](http://stevedonovan.github.com/ldoc/). 
So have a look at the 
[**documentation**](https://htmlpreview.github.io/?https://github.com/wipfl/lua-physvalue/blob/master/doc/index.html).

## License
PhysValue is distributed under the MIT license.
