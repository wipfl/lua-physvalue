--[[DEBUG]] package.path = package.path .. ';physvalue/src/?.lua;physvalue/test/?.lua'
EXPORT_ASSERT_TO_GLOBALS = true
require('luaunit')
require('math')
pv=require('physvalue')

TestPhysValue = {}

function TestPhysValue:test_getUnit()
  -- simple unit
  assertIsTable(pv._getUnit('m'))
  assertError(pv._getUnit('dummy'))
  -- combined unit.
  local v = pv._getUnit('m/s')
  assertEquals(v.value, 1)
  assertEquals(v.units.m,1)
  assertEquals(v.units.s,-1)
  assertEquals(v.symbol,nil)
  -- combined unit / not in base units.
  v = pv._getUnit('km/hr')
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
  assertEquals(a:UnitMatch(pv._getUnit('km*m/hr*s/mm')), true)
  local c = a / b
  assertEquals(c:UnitMatch(pv._getUnit('km/hr')), true)

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
  
  local err, c
  
  c = a+b
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b+a
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  err = pcall(add,b*b,a)
  assertNotNil(err)
  err = pcall(add, 1, a)
  assertNotNil(err)
  err = pcall(add, a, 5)
  assertNotNil(err)
end

function TestPhysValue:test_sub()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'mm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function sub(a,b) return a+b; end
  
  local err, c
  
  c = a-b
  assertEquals(c.value, 100-0.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b-a
  assertEquals(c.value, 0.012-100)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed / we must do some voodoo to catch the assertion (see above)
  err = pcall(sub,b*b,a)
  assertNotNil(err)
  err = pcall(sub, 1, a)
  assertNotNil(err)
  err = pcall(sub, a, 5)
  assertNotNil(err)
end
  
function TestPhysValue:test_unm()
  local a = pv:new('a', 100, 'm')
  
  -- We define a local function / Otherwise the formulas that 
  -- we want to test for assertion are evaluated before assertError
  -- is invoked.
  local function sub(a,b) return a+b; end
  
  local err, c
  
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
  
  
  local err
  -- Square root of negative number is not supported.
  err, c = pcall(_sqrt, a)
  assertNotNil(err)
  
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
  
  local err
  -- Square root of negative number is not supported.
  err, c = pcall(_cbrt, a)
  assertNotNil(err)
  
end


function TestPhysValue:test_pow()
  local a = pv:new('a', 100, 'm')
  local b = pv:new('b', 12, 'ms')
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
  


lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
