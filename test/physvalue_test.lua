--[[DEBUG]] package.path = package.path .. ';../src/?.lua'
EXPORT_ASSERT_TO_GLOBALS = true
require('luaunit')
require('math')
pv=require('physvalue')

TestPhysValue = {}

function TestPhysValue:test_getUnit()
  -- simple unit
  assertIsTable(pv._getUnit('m'))
  assertError((function() return pv._getUnit('dummy'); end)())
  -- combined unit.
  local v = pv._getUnit('m/s')
  assertEquals(v.value, 1)
  assertEquals(v.units.m,1)
  assertEquals(v.units.s,-1)
  assertEquals(v.symbol,nil)
  -- combined unit / not in base units.
  v = pv._getUnit('km/h')
  assertEquals(v.value, 1000/3600)
  assertEquals(v.units.m,1)
  assertEquals(v.units.s,-1)
  assertEquals(v.symbol,nil)
  
end

function TestPhysValue:test_UnitMatch()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 's')
  
  assertEquals(a:UnitMatch(pv._getUnit('km')), true)
  assertEquals(a:UnitMatch(pv._getUnit('mm')), true)
  assertEquals(a:UnitMatch(pv._getUnit('km*m/h*s/mm')), true)
  local c = a / b
  assertEquals(c:UnitMatch(pv._getUnit('km/h')), true)

  assertEquals(a:UnitMatch(b), nil)
end

function TestPhysValue:test_initialize()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 's')
  
  assertEquals(a.value, 100)
  assertEquals(a.units.m,1)
  assertEquals(a.symbol,'m')

  assertEquals(b.value, 12)
  assertEquals(b.units.s,1)
  assertEquals(b.symbol,'s')

  local c = pv:new('c', 34, 'm/s')
  assertEquals(c.value, 34)
  assertEquals(a.units.m,1)
  assertEquals(c.units.s,-1)
  assertEquals(c.symbol,'m/s')
 
  local d = pv:new('d', a)
  assertEquals(d.value, 100)
  assertEquals(d.units.m,1)
  assertEquals(d.symbol,'m')
  
end

function TestPhysValue:test_add()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'mm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function add(a,b) return a+b; end
  
  local ok, res, c
  
  c = a+b
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b+a
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  ok, res = pcall(add,b*b,a)
  assertFalse(ok)
  assertStrContains(res, 'Unmatching unit in add/sub')
  ok,res = pcall(add, 1, a)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
  ok,res = pcall(add, a, 5)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
end

function TestPhysValue:test_sub()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'mm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function sub(a,b) return a+b; end
  
  local ok, res, c
  
  c = a-b
  assertEquals(c.value, 100-0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b-a
  assertEquals(c.value, 0.012-100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  ok, res = pcall(sub,b*b,a)
  assertFalse(ok)
  assertStrContains(res, 'Unmatching unit in add/sub')
  ok, res = pcall(sub, 1, a)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
  ok, res = pcall(sub, a, 5)
  assertFalse(ok)
  assertStrContains(res, 'Adding/subtracting is allowed with PhysValue only')
end
  
function TestPhysValue:test_unm()
  local a = pv:new('a', 100, 'm')
  
 
  local c
  
  c = -a
  assertEquals(c.value, -100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = - -a
  assertEquals(c.value, 100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')
  
end
 
function TestPhysValue:test_mul()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'ms')
  local s = pv:new('s', 12, 'm/s')
  
  local c
  
  c = a*b
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  

  c = b*a
  assertEquals(c.value, 0.012*100)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  
  -- Multiplying with number keeps the symbol
  c = 0.012*a
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')

  c = a*0.012
  assertEquals(c.value, 100*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')
  
  -- Multiplying speed [m/s] with time [s] should remove the member units.s 
  c = s * b
  assertEquals(c.value, 12*0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,nil)
end
  
function TestPhysValue:test_div()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'ms')
  local s = pv:new('s', 12, 'm/s')
  
  local c
  
  c = a/b
  assertAlmostEquals(c.value, 100/0.012, 1e-12)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,-1)
  assertEquals(c.symbol,nil)
  

  c = b/a
  assertEquals(c.value, 0.012/100)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.s,1)
  assertEquals(c.symbol,nil)
  
  -- Dividing by number keeps the symbol
  c = a / 0.012
  assertAlmostEquals(c.value, 100/0.012, 1e-12)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')

  c = 0.012 / a
  assertEquals(c.value, 0.012/100)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,nil)
  
  -- Dividing speed [m/s] by length [m] should remove the member units.m 
  c = s / a
  assertEquals(c.value, 12/100)
  assertEquals(c.units.m,nil)
  assertEquals(c.units.s,-1)
  assertEquals(c.symbol,nil)
  
  -- Dividing by zero return math.huge
  c = a / 0
  assertEquals(c.value, math.huge)
  assertEquals(c.units.m,1)
  assertEquals(c.units.s,nil)
  assertEquals(c.symbol,'m')
 
end
  
function TestPhysValue:test_sqrt()
  local a = pv:new('a', -100, 'm')
  local b = pv:new('b', 12, 'ms')
  local s = pv:new('s', 144, 'm/s')
  
  
  local c
  
  c = s:sqrt()
  assertEquals(c.value, 12)
  assertEquals(c.units.m,0.5)
  assertEquals(c.units.s,-0.5)
  assertEquals(c.symbol,nil)
 
 
  c = b*b
  c = c:sqrt()
  assertEquals(b==c, true)
  
  local function _sqrt(v) return v:sqrt(); end
  
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_sqrt, a)
  assertFalse(ok)
  assertStrContains(res,'sqrt of negative values not supported.')
  
end

function TestPhysValue:test_cbrt()
  local a = pv:new('a', -100, 'm')
  local b = pv:new('b', 12, 'ms')
  local s = pv:new('s', 12*12*12, 'm/s')
  
  
  local c
  
  c = s:cbrt()
  assertAlmostEquals(c.value, 12, 1e-12)
  assertEquals(c.units.m,1/3)
  assertEquals(c.units.s,-1/3)
  assertEquals(c.symbol,nil)
 
  c = b*b*b
  c = c:cbrt()
  --assertEquals(b==c, true)
  -- b and c is not exactly equal (floating point rounding)
  -- We test if it is nearly equal
  
  assertAlmostEquals(c.value, b.value, 1e-12)
  assertAlmostEquals(c.units.s, b.units.s, 1e-12)
  

  local function _cbrt(a) return a:cbrt(); end
  
  local ok, res
  -- Square root of negative number is not supported.
  ok, res = pcall(_cbrt, a)
  assertFalse(ok)
  assertStrContains(res,'cbrt of negative values not supported.')
  
end


function TestPhysValue:test_pow()
  local d = pv:new('d', 0, 'N')
  local s = pv:new('s', 12, 'm/s')
  
  local c
  
  c = s^2
  assertEquals(c.value, 12*12)
  assertEquals(c.units.m,2)
  assertEquals(c.units.s,-2)
  assertEquals(c.symbol,nil)
  

  c = s^-2
  assertEquals(c.value, 1/(12*12))
  assertEquals(c.units.m,-2)
  assertEquals(c.units.s,2)
  assertEquals(c.symbol,nil)
  
  c = d^-1
  assertEquals(c.value, math.huge)
  assertEquals(c.units.m,-1)
  assertEquals(c.units.kg, -1)
  assertEquals(c.units.s,2)
  assertEquals(c.symbol,nil)
end
  
function TestPhysValue:test_eq()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 100, 's')
  
  local c = a
  assertEquals(a==a, true)
  assertEquals(c==a, true)
  assertEquals(c==1*a, true)
  assertEquals(c==(1+1e-12)*a, false)
  assertEquals(c~=(1+1e-12)*a, true)
  assertEquals(a==b, false)
  assertEquals(a~=b, true)
end

function TestPhysValue:test_lt()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 100, 's')
  
  local c = a
  assertEquals(a<a, false)
  assertEquals(a>a, false)
  assertEquals(c<a, false)
  assertEquals(c>a, false)
  assertEquals(c<(1+1e-12)*a, true)
  assertEquals(c>(1+1e-12)*a, false)
  assertEquals((1+1e-12)*a>c, true)
  assertEquals((1+1e-12)*a<c, false)
  
  function _lt(a,b) return a < b; end
  
  local ok, res
  ok, res = pcall(_lt,a,b)
  assertFalse(ok)
  assertStrContains(res, "Unmatching unit in compare <:")
end

function TestPhysValue:test_le()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 100, 's')
  
  local c = a
  assertEquals(a<=a, true)
  assertEquals(a>=a, true)
  assertEquals(c<=a, true)
  assertEquals(c>=a, true)
  assertEquals(c<=(1+1e-12)*a, true)
  assertEquals(c>=(1+1e-12)*a, false)
  assertEquals((1+1e-12)*a>=c, true)
  assertEquals((1+1e-12)*a<=c, false)
  
  function _le(a,b) return a <= b; end
  
  local ok, res
  ok, res = pcall(_le,a,b)
  assertFalse(ok)
  assertStrContains(res, "Unmatching unit in compare <=:")
  
end

function TestPhysValue:test_getBaseUnitString()
  local s = pv.u['N']:_getBaseUnitString()
  -- The resulting string does not guarantee the sequence of
  -- base units. So we have to check for any possible sequence.
  assertStrContains(s,"kg")
  assertStrContains(s,"m")
  assertStrContains(s,"s^-2")
  
  s=s:gsub('kg','',1)
  s=s:gsub('m','',1)
  s=s:gsub('s%^%-2','',1)
  
  assertStrMatches(s,'**')
end

function TestPhysValue:test_getUnitFactor()
  assertEquals(pv.u['mm']:_getUnitFactor('mm'), 0.001)
  assertEquals(pv.u['mm']:_getUnitFactor(), 0.001)
  local a = pv.u['m'] / pv.u['s']
  assertEquals(a:_getUnitFactor('km/h'), 1/3.6)
  
  local function getUnitFactor(p,unit) return p:_getUnitFactor(unit); end
  
  local ok, res
  
  ok, res = pcall(getUnitFactor, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(getUnitFactor, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(getUnitFactor, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
end

function TestPhysValue:test_getValue()
  assertEquals(pv.u['mm']:getValue('km'), 1e-6)
  local a = pv.u['m'] / pv.u['s']
  assertAlmostEquals(a:getValue('km/h'), 3.6, 1e-12)
  
  local function getValue(p,unit) return p:getValue(unit); end
  
  local ok, res
  
  ok, res = pcall(getValue, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(getValue, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(getValue, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
end

function TestPhysValue:test_setPrefUnit()
  local a = pv.u['km'] / pv.u['h']
  a:setPrefUnit('m/s')
  assertEquals(a.symbol,'m/s')
  local function setPrefUnit(p,unit) return p:setPrefUnit(unit); end
  
  local ok, res
  
  ok, res = pcall(setPrefUnit, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(setPrefUnit, a, nil)
  assertFalse(ok)
  assertStrContains(res,'No unit given.')
  
  ok,res = pcall(setPrefUnit, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')
  
  
end

function TestPhysValue:test_concat()
  local a = pv.u['m'] / pv.u['s']
  a:setPrefUnit('m/s')
  assertStrMatches((2*a)..'km/h','7.2 km/h')
  assertStrMatches('Speed: '..a, 'Speed: 1 m/s')
  
  local function concat(p,unit) return p..unit; end
  
  local ok, res
  
  ok, res = pcall(concat, a, 1)
  assertFalse(ok)
  assertStrContains(res,'No string unit: ')
  
  ok,res = pcall(concat, a, 'm/s^2')
  assertFalse(ok)
  assertStrContains(res,'Unmatching units in unit conversion: ')

end

function TestPhysValue:test_tostring()
  local a = pv.u['m'] / pv.u['s']
  a:setPrefUnit('m/s')
  assertStrMatches(tostring(a), '1 m/s')
end

function TestPhysValue:test_format()
  local vMax = pv:new('vMax', 4, 'm/s')
  assertEquals(vMax:format(), '4 m/s')
  assertEquals(vMax:format(nil, 'km/h'), '14.4 km/h')
  assertEquals(vMax:format('#is #vg #us', nil), 'vMax 4 m/s')
  assertEquals(vMax:format('#is #vg #us', 'km/h'), 'vMax 14.4 km/h')
  assertEquals(vMax:format('#is #vg #us', 'km/h'), 'vMax 14.4 km/h')
  vMax = pv:new('vMax', -1/3, 'm/s')
  assertEquals(vMax:format('#is #v12.9f #us', nil), 'vMax -0.333333333 m/s')
  assertAlmostEquals(tonumber(vMax:format('#v.13g', nil)), vMax.value, 1e-12)
  assertAlmostEquals(tonumber(pv.c.mProton:format('#v.13g', nil)), pv.c.mProton.value, 1e-12)
end

function TestPhysValue:test_toJson()
  local vMax = pv:new('vMax', 4, 'm/s')
  assertEquals(vMax:toJson(), '{ "type": "PhysValue", "id": "vMax", "value": 4, "unit": "m/s"}')
  assertEquals(vMax:toJson('km/h'), '{ "type": "PhysValue", "id": "vMax", "value": 14.4, "unit": "km/h"}')
  vMax = pv:new('vMax', -1/3, 'm/s')
  assertEquals(vMax:toJson('m/s'), '{ "type": "PhysValue", "id": "vMax", "value": -0.3333333333333, "unit": "m/s"}')
  assertEquals(pv.c.mProton:toJson(), '{ "type": "PhysValue", "id": "mProton", "value": 1.67492e-27, "unit": "kg"}')
  
end

function TestPhysValue:test_setId()
  local vMax = pv:new('vMax', 4, 'm/s')
  assertEquals(vMax:format('#is #vg #us', nil), 'vMax 4 m/s')
  assertEquals(vMax:setId('vMin'):format('#is #vg #us', nil), 'vMin 4 m/s')
end

lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
