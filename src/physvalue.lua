-------------------------------------
-- Provides a class for physical value arithmetics.
-- @module PhysValue

--[[DEBUG]] package.path = package.path .. ';physvalue/src/?.lua'
local class = require'middleclass'
local debug = require'debug'

------------------------------------- 
-- Holds the class structure of the module.
-- 
-- @type PhysValue  
local PhysValue = class('PhysValue')

function table.deep_copy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen an copy recursively.
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.deep_copy(k, s)] = table.deep_copy(v, s) end
  return res
end
--------------------------------------
-- Holds the prefixes of units with
-- their factors to baseunit
-- @table prefixes
prefixes = {
  k=1e3, -- kilo
  M=1e6, -- Mega
  G=1e9, -- Giga
  T=1e12,-- Tera
  da=1e1, -- deka
  h=1e2, -- hekto
  d=1e-1, -- dezi
  c=1e-2, -- centi
  m=1e-3, -- milli
  u=1e-6, -- micro  
  n=1e-9, -- nano
  p=1e-12 -- pico
}

--------------------------------------
-- holds the symbols of the baseunits
local baseunits = {}
--------------------------------------
-- holds all available units
local u = {}

--------------------------------------
--Publishes the units table
-- @field #table u 
PhysValue.u = u

--------------------------------------
-- holds all available constants
local c = {}

--------------------------------------
--Publishes the constants table
-- @field  [parent=#PhysValue] #table c 

PhysValue.c = c

-------------------------------------
-- Helper function inserts a BaseUnit
-- to the baseunits table and to the
-- unit table PhysValue.u
-- @param symbol the base unit string
local function BaseUnit(symbol)
  local bunit = PhysValue:new(nil, 1, nil)
  bunit.units = {[symbol]=1}
  bunit.symbol = symbol
  table.insert(baseunits, symbol)
  u[symbol] = bunit
end

-------------------------------------
-- Helper function gets a unit instance defined by a string
-- @param definition String definition of desired unit as
-- <ul>
-- <li>an existing unit symbol or</li>
-- <li>a formula combining already existing units</li>
-- </ul>
-- @return PhysValue instance of an unit
function PhysValue._getUnit(definition)
  if PhysValue.u[definition] then
    return PhysValue.u[definition]
  else
    -- Create a script that computes the given unit from units in table u
    local script, err = loadstring('function _(u) return '..string.gsub(definition,"([A-Za-z]+)", "u['%1']")..'; end')
    assert(script, 'Compiling of unit definition failed: '..tostring(definition)..' Err: '..tostring(err))
    -- Executing the script defines a global function '_'
    assert(pcall(script), 'Invalid unit definition: ' .. tostring(definition))
    -- Call global function '_'
    local ok, a = pcall(_, PhysValue.u)
    -- 
    assert(ok, 'Running of unit definition failed: ' .. tostring(definition))
    return a
  end
end
-------------------------------------
-- Helper function inserts a Unit (with 
-- all prefix combinations) to the table
-- PhysValue.u
-- @param symbol The unit string (only A-Z and a-z are allowed in string)
-- @param definition a string with a formula that
-- defines the unit from already existing
-- units.
-- (The unit names in the formula are automatically
-- prefixed by 'PhysValue.u.' to refence the units table.)
local function Unit(symbol, definition, withoutPrefix)
  local b = PhysValue._getUnit(definition)
  u[symbol] = b
  u[symbol].symbol = symbol
  if not withoutPrefix then
    for prefix,factor in pairs(prefixes) do
      u[prefix..symbol] = b*factor
      u[prefix..symbol].symbol = prefix..symbol
    end
  end
end


---------------------------------------
-- Checks if the unit of self and the unit of b match.
-- @param b Physical value to be checked against self
-- @usage if pv:UnitMatch(pv2)
function PhysValue:UnitMatch(b)
  for k,v in pairs(self.units)do
    if b.units[k]~=v and v~=0 then
      return nil
    end
  end
  for k,v in pairs(b.units)do
    if self.units[k]~=v and v~= 0 then
      return nil
    end
  end
  return true
end

---------------------------------------
-- Helper function: deep copies a physical
-- value.
-- The function avoids deep copy of the members
-- metatable and class
-- @param a Physical value to be copied
function PhysValue.deep_copy(a)
  if type(a) ~= 'table' then return a end
  local copy = {}
  local m = getmetatable(a)
  for k,v in pairs(a) do
    if k ~= 'metatable' and k ~= 'class' then
      copy[k] = table.deep_copy(v)
    else
      copy[k] = v
    end
  end
  setmetatable(copy,m)
  return copy  
end

-------------------------------------
-- Constructor: called in PhysValue.new().
-- @param id Identifier string
-- @param value  number Value of the variable in unit 'symbol' or
-- a PhysValue
-- @param symbol Unit string (must exist in table u)
-- (must be omitted of value is given as a PhysValue)
function PhysValue:initialize(id, value, symbol)
  if symbol then
    local a = PhysValue._getUnit(symbol)
    self.value = value * a.value
    self.units = a.units
    self.symbol = symbol
  elseif type(value) == 'table' then
    self.value = value.value or 0
    self.units = value.units or {}
    self.symbol = value.symbol or ''
  else
    self.value = value or 0
    self.units = {}
    self.symbol = ''
  end
  
  self.id = id
end

-------------------------------------
-- Add b to self.
-- @param b PhysValue to be added
-- @return #PhysValue Sum of self and b. 
function PhysValue:__add(b)
  local a = PhysValue.deep_copy(self)
  assert(type(b)=='table', 'Adding is allowed with PhysValue only')
  assert(a:UnitMatch(b), 'Unmatching unit in add: '..tostring(a)..' + '..tostring(b))
  a.value = a.value + b.value
  return a
end

-------------------------------------
-- Substract b from self.
-- @param b PhysValue to be subtractedformat
-- @return #PhysValue Difference of self and b. 
-- @usage pv1 = pv2 - pv3
function PhysValue:__sub(b)
  return self + -1*b
end

-------------------------------------
-- Unary minus of self.
-- @return #PhysValue Negative value of self.
-- @usage pv1 = -pv2
function PhysValue:__unm()
  return -1*self
end

-------------------------------------
-- Multiply self by b.
-- @param b Multiplicator (can be #PhysValue or #number)
-- @return #PhysValue self * b with correct unit
-- @usage pv1 = pv2 * pv3
--pv1 = pv2 * number3
function PhysValue:__mul(c)
  local a = PhysValue.deep_copy(self)
  local b = PhysValue.deep_copy(c)
  if type(a)=='number' then
    b.value = b.value * a
    return b
  elseif type(b)=='number' then
    a.value = a.value * b
    return a
  else
    for k,v in pairs(b.units or {}) do
      a.units[k] = (a.units[k]or 0) + v
      if a.units[k] == 0 then
        a.units[k] = nil
      end
    end
    a.value = a.value * b.value
    a.symbol = nil
    return a
  end
end

-------------------------------------
-- Power(b)
-- @param b Exponent (a #number)
-- @return #PhysValue self ^ b with correct unit
-- @usage pv1 = pv2^2
function PhysValue:__pow(b)
  assert(type(b)== 'number', "Exponent must be a number: "..tostring(b))
  local a = PhysValue.deep_copy(self)
  for k,v in pairs(a.units) do
    a.units[k] = v*b
  end
  if b ~= 1 then
    a.value = a.value^b
    a.symbol = nil
  end
  
  return a
end

-------------------------------------
-- Divide by b
-- @param b Divisor (can be #PhysValue or #number)
-- @return #PhysValue self / b with correct unit
-- @usage pv1 = pv2 / pv3
--pv1 = pv2 / number3
function PhysValue:__div(b)
  return self*b^-1
end

-------------------------------------
-- Square root
-- @return #PhysValue self ^ (1/2) with correct unit
-- @usage pv1 = pv2:sqrt()
function PhysValue:sqrt()
  assert(self.value >= 0, 'sqrt of negative values not supported.')
  return self ^ 0.5
end

-------------------------------------
-- Cubic root
-- @return #PhysValue self ^ (1/3) with correct unit
-- @usage pv1 = pv2:cbrt()
function PhysValue:cbrt()
  assert(self.value >= 0, 'cbrt of negative values not supported.')
  return self ^ (1/3)
end

-------------------------------------
-- Compare Equal self '==' b
-- @param b #PhysValue to be compared
-- @return true if self == b
-- @usage if pv1 == pv2 then ...
function PhysValue:__eq(b)
  assert(self:UnitMatch(b),'Unmatching unit in compare ==: '..tostring(self)..' & '..tostring(b))
  return self.value == b.value
end

-------------------------------------
-- Compare less than self '<' b
-- @param b #PhysValue to be compared
-- @return true if self < b
-- @usage if pv1 < pv2 then ...
--if pv1 > pv2 then ...
function PhysValue:__lt(b)
  assert(self:UnitMatch(b), 'Unmatching unit in compare <: '..tostring(self)..' & '..tostring(b))
  return self.value < b.value
end

-------------------------------------
-- Compare Less equal(b) '<='
-- @param b #PhysValue to be compared
-- @return true if self <= b
-- @usage if pv1 <= pv2 then ...
--if pv1 >= pv2 then ...
function PhysValue:__le(b)
  assert(self:UnitMatch(b), 'Unmatching unit in compare <=: '..tostring(self)..' & '..tostring(b))
  return self.value <= b.value
end

-------------------------------------
-- Get base unit string.
-- Returns the string representation of the base unit.
-- This is done without any chichi. To give an example:
-- a force is expressed as 'kg*m*s^⁻2' and not as
-- kg*m/s^2 or kg*m/s²
-- @return String representing the base unit
function PhysValue:_getBaseUnitString()
  local ustring
  for k,v in pairs(self.units) do
    if v~=0 then
      ustring = ustring and (ustring .. '*') or ''
      ustring = ustring..k..(v==1 and '' or '^'..v)
    end
  end
  return ustring or ""
end

-------------------------------------
-- Get base unit factor.
-- Returns the factor of the given unit to the base unit of
-- the same dimension.
-- @param symbol String representation of target unit 
-- (defaults to preferred unit of PhysValue given in Constructor)
-- @return #number giving the base unit factor
-- @usage PhysValue:new("",1,"km"):_getUnitFactor("mm")
--   returns 1e-3 
function PhysValue:_getUnitFactor(symbol)
  assert(type(symbol) == 'string', 'Unknown conversion unit: ' .. tostring(symbol))
  local b = PhysValue._getUnit(symbol)
  assert(self:UnitMatch(b), 'Unmatching units in unit conversion: '..self.symbol..' & '..symbol)
  return b.value
end


-------------------------------------
-- String concatanation (..)
-- Converts the PhysValue into a string using the
-- unit that is concatenated to self.
-- @param bString unit string to be converted to
-- @return String representation of the PhysValue
-- @usage a = PhysValue:new('',120,'s')
-- print(a..'min')
--   gives: '2 min'
function PhysValue:__concat(bString)
  assert(type(bString)=='string')
  return self:format(nil, bString)
end

-------------------------------------
-- String conversion.
-- Converts the PhysValue to a string using the
-- preferred unit that has been chosen in the 
-- constructor.
-- This function calls PhysValue:format
-- with the standard format '#vg #us'
-- @return String representation of the PhysValue
-- @usage a = PhysValue:new('',12,'km')
-- tostring(a)
--   returns '12 km'
function PhysValue:__tostring()
  return self:format()
end

-------------------------------------
-- String format. 
-- Formats the PhysValue to a string with a given format
-- and unit.
-- @param f Format string.
-- In the format string can be the following tokens that
-- are substituted by the fields of the PhysValue:
-- <ul>
-- <li> '#v'  substituted by the numerical value </li>
-- <li> '#u'  substituted by the unit</li>
-- <li> '#i'  substituted by the id (name)</li>
-- </ul>
-- all tokens will be replaced by a '%' character so that
-- the following characters define the format string for 
-- the string.format() function.
-- So the format string '#is: #v5.1f #us' will do the same like
-- string.format('%s: %5.1f %s', a.id, a.value, a.symbol)
-- @param symbol The unit string to which the PhysValue is
-- converted before formatting.
-- @return String according to given format.
-- @usage a = PhysValue:new('Distance',12470,'m')
-- a:format('#is: #v+12.2f [#us]', 'km')
--   gives 'Distance:       +12.47 [km]'
function PhysValue:format(f,symbol)
  f = f or "#vg #us"
  symbol = symbol or self.symbol
  local b
  local ustring = symbol
  local value = self.value
  local str
  if symbol then
    value = self.value / self:_getUnitFactor(symbol)
  else
    ustring = self:_getBaseUnitString()
  end
  str = string.gsub(f,"#v","%%")
  str = string.format(str,value)
  str = string.gsub(str,"#u","%%")
  str = string.format(str,ustring)
  str = string.gsub(str,"#i","%%")
  str = string.format(str,self.id)
  return str
end

-------------------------------------
-- Generate JSon string 
-- Converts the PhysValue to a Json string with the unit 
-- converted to the one given in the symbol string.
-- @param symbol The unit string to be converted to.
-- @return A Json string.
-- @usage PhysValue.mElectro:toJson('kg')
-- will return '{ "id": "mElectron", "value": 9.10939e-31, "unit": "kg"}'
function PhysValue:toJson(symbol)
  return self:format('{ "id": "#is", "value": #v20g, "unit": "#us"}', symbol)
end


--SI BASE UNITS
BaseUnit'm'
BaseUnit'kg'
BaseUnit's'
BaseUnit'A'
BaseUnit'K'
BaseUnit'mol'
BaseUnit'cd'
BaseUnit'rad'
BaseUnit'sr'

Unit('m', 'm')
Unit('g', '.001*kg')
Unit('s', 's')
Unit('A', 'A')
Unit('K', 'K')
Unit('mol', 'mol')
Unit('cd', 'cd')
Unit('rad', 'rad')
Unit('sr', 'sr')

--SI NAMED UNITS
Unit('Hz', '1/s')
Unit('N', 'kg*m/s^2')
Unit('Pa', 'N/m^2')
Unit('J', 'N*m')
Unit('W', 'J/s')
Unit('C', 'A*s')
Unit('V', 'W/A')
Unit('F', 'C/V')
Unit('Ohm', 'V/A')
Unit('S', 'A/V')
Unit('Wb', 'V*s')
Unit('T', 'Wb/m^2')
Unit('H', 'Wb/A')
Unit('lm', 'cd*sr')
Unit('lx', 'lm/m^2')
--Unit('Bq', '1/s')
--Unit('Gy', 'J/kg')
--Unit('Sv', 'J/kg') 
Unit('kat','mol/s')

--SI ACCEPTABLE UNITS
u.min = 60*u.s
u.hr = 60*u.min
u.day = 24*u.hr
u.deg = math.pi/180*u.rad
u.ha = 100*u.m*100*u.m
Unit('L', 'dm^3')
u.tonne = 1000*u.kg
u.Ang = 1e-10*u.m

--SI EXPERIMENTAL UNITS
u.eV = 1.60217733e-19*u.J
Unit('eV', 'eV')
u.amu = 1.6605402e-27*u.kg

-- Own units
Unit('bar','1000*hPa')

--CONVERSION UNITS
u.mi = 1609.344*u.m
u.ft = u.mi/5280
u.yd = 3*u.ft  
u.inch = u.ft/12  
u.lb = u.kg/2.20462262185  
u.lbf = 4.4482216152605*u.N  
u.hp = 746*u.W  

--PHYSICAL CONSTANTS
c.lightspeed = PhysValue:new('vlight', 2.99792458e8, 'm/s')
c.e = PhysValue:new('e', 1, 'eV/J*C')
c.G = PhysValue:new('G', 6.67259e-11, 'N*m^2/kg^2')
c.g_0 = PhysValue:new('gravityConstant', 9.80665, 'N/kg')
c.mass_e = PhysValue:new('mElectron', 9.10939e-31, 'kg')
c.mass_neutron = PhysValue:new('mNeutron', 1.67262e-27, 'kg')
c.mass_proton = PhysValue:new('mProton', 1.67492e-27, 'kg')
c.epsilon_0 = PhysValue:new('epsilon0', 8.854e-12, 'C^2/(N*m^2)')
c.k = 1/4*math.pi*c.epsilon_0
c.N_A = PhysValue:new('N_A', 6.02214129e23, '1/mol')

--x[[DEBUG
local function main()
  local gew1 = PhysValue:new("Gewicht1", -100, 'g')
  print(gew1)
  local pressure = PhysValue:new("Kraft", 100, 'bar')
  print(pressure..'kg/(m*s^2)')
  print(pressure..'hPa')
  print(u.hPa)
  print(gew1:toJson('mg'))
  print(gew1:format("#i8.8s: #v+8.2f #u-3.3s<-"))
  print(PhysValue.c.mass_e:format("#i8.8s: #v+12g #u-3.3s<-", 'g'))
  print(PhysValue.c.mass_e:toJson())
  --print(PhysValue.c.mass_e:toJson('N'))
  local a = PhysValue:new('Distance',12470,'m')
  print(a:format('#is: #v+12.2f [#us]', 'km'))
  local gew2 = PhysValue:new("Gewicht2", 0.102, 'kg')
  
  if (gew1 == gew2) then error('Alarm!') end
  if not (gew1 == gew1) then error('Alarm!') end
  if gew1 > gew2 then error('Alarm!') end
  if not (gew1 < gew2) then error('Alarm!') end
  
end


main()
--]]

return PhysValue
