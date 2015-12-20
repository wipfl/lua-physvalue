--[[DEBUG]] package.path = package.path .. ';physvalue/src/?.lua;physvalue/test/?.lua'
EXPORT_ASSERT_TO_GLOBALS = true
require('luaunit')

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
  
  local c
  
  c = a+b
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'m')

  c = b+a
  assertEquals(c.value, 100.012)
  assertEquals(c.units.m,1)
  assertEquals(c.symbol,'mm')
  
  -- This is not allowed
  assertEquals(pcall(b*b + a), false)
  --assertError(1+a)
  assertError(b+5)
end
  
lu = LuaUnit.new()
lu:setOutputType("tap")
os.exit( lu:runSuite() )
