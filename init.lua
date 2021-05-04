firstWifiConnection = true

mqttClient=nil
mqttConnected=false
minutesSinceStart=0

dofile("config.lua")
dofile("wifi.lua")
dofile("http.lua")
dofile("mqtt.lua")
dofile("devicespecific.lua")

function onFirstWifiConnection()
  if firstWifiConnection then
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

function timerExpired()
  print("timer expired. minutesSinceStart: "..minutesSinceStart)

  if isWifiConnected() then
    onFirstWifiConnection()

    if mqttConnected then
      sendMqttTeleMessage()
      
      timer:interval(timerIntervalInSeconds)
      
      minutesSinceStart = minutesSinceStart + 1

      if minutesSinceStart > restartIntervalInMinutes then        
        print("RESTARTING DEVICE AFTER '"..restartIntervalInMinutes.."' MINUTES.")

        -- TODO: call device specific code to save/reload things (for example relais state) or deprecate this feature
        node.restart()        
      end
    end
  end
  
  print ("")
end

connectToWifi()

timer = tmr.create()
timer:alarm(startupTimerIntervalInSeconds, 1, timerExpired)
