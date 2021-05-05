firstWifiConnection = true

mqttClient=nil
mqttConnected=false
minutesSinceStart=0
powerIndicatorPin = 4

dofile("config.lua")
dofile("wifi.lua")
dofile("http.lua")
dofile("mqtt.lua")
dofile("devicespecific.lua")

gpio.mode(powerIndicatorPin,gpio.OUTPUT)

function setPowerIndicatorOn()
  powerIndicatorState = 1
  gpio.write(powerIndicatorPin, gpio.LOW)
end

function setPowerIndicatorOff()
  powerIndicatorState = 0
  gpio.write(powerIndicatorPin, gpio.HIGH)
end

setPowerIndicatorOn()

function onFirstWifiConnection()
  if firstWifiConnection then
    setPowerIndicatorOn()

    print "- doing first WIFI connection stuff"
    
    timer:stop()

    download(otaBase..'init.lua', 'init.lua', function()
      download(otaBase..'config.lua', 'config.lua', function()
        download(otaBase..'http.lua', 'http.lua', function ()
          download(otaBase..'wifi.lua', 'wifi.lua', function ()
            download(otaBase..'mqtt.lua', 'mqtt.lua', function ()
              download(otaBase..'devicespecific.lua', 'devicespecific.lua', function ()
                connectToMqttIfNeeded()
                timer:start()
              end)
            end)
          end)
        end)
      end)
    end)
  end
end

function togglePowerIndicatorState()
  if powerIndicatorState == 0 then
    setPowerIndicatorOn()
  else
    setPowerIndicatorOff()
  end
end

function timerExpired()
  print("timer expired. minutesSinceStart: "..minutesSinceStart)

  if isWifiConnected() then
    onFirstWifiConnection()

    if mqttConnected then
      sendMqttTeleMessage()

      setPowerIndicatorOff()
      
      timer:interval(timerIntervalInSeconds)
      
      minutesSinceStart = minutesSinceStart + 1

      if (restartIntervalInTimerIntervals > 0 and minutesSinceStart > restartIntervalInTimerIntervals and devicespecificCanRestart()) then
        print("RESTARTING DEVICE AFTER '"..restartIntervalInTimerIntervals.."' timers elapsed.")

        node.restart()
      end
    end
  else
    togglePowerIndicatorState()
  end
  
  print ("")
end

print("mqttPublishTopic: "..mqttPublishTopic)
print("mqttSubscriptionTopic: "..mqttSubscriptionTopic)

connectToWifi()

timer = tmr.create()
timer:alarm(startupTimerIntervalInSeconds, 1, timerExpired)
