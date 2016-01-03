pv=require('physvalue')

local function computeSpeed()
  -- Define the start and end readings of the speedometer
  local myBestSpeed = pv:new('BestSpeed', 31.3, 'km/h')
  local travelStart = pv:new('Start', 12445.4, 'km')
  local travelEnd = pv:new('End', 12522.6, 'km')
  -- The duration of the tour. We must add hours and minutes.
  local duration = pv:new('Duration', 7, 'h') + pv:new('', 43, 'min')

  -- We can compute the average speed as we would do with numbers
  local averageSpeed = (travelEnd - travelStart) / duration
  -- We set a name for the variable
  averageSpeed:setId('Speed')

  -- We print the variables formatted nicely
  print(travelStart:format("#i-8s: #v12.2f #u-8s"))
  print(travelEnd:format("#i-8s: #v12.2f #u-8s"))
  print((travelEnd-travelStart):setId('Distance'):format("#i-8s: #v12.2f #u-8s"))
  print(duration:format("#i-8s: #v12.2f #u-8s"))
  -- averageSpeed has the internally used SI units
  print(averageSpeed:format("#i-8s: #v12.2f #u-8s"))
  -- We add the desired unit for our output
  print(averageSpeed:format("#i-8s: #v12.2f #u-8s", 'km/h'))

  -- We can compare physical values like numbers
  if averageSpeed > myBestSpeed then
    myBestSpeed = averageSpeed
    print('New record!')
  else
    -- String concatenation is simple
    print('You missed your best speed of ' .. myBestSpeed )
    -- Unit conversion takes place with string concatenation
    print('or ' .. (myBestSpeed .. 'm/s') .. ' in SI base units.')
  end
end

computeSpeed()