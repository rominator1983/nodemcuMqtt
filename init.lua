-- TODO: Move to DHT device specific thingies.
-- NOTE: 9, 10, 11 are poisonous for uploading or serial console. 5 would be GPIO14. See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
dhtPin = 2 -- GPIO04
gpio.mode(dhtPin,gpio.INPUT)

firstWifiConnection = true

mqttClient=nil
mqttConnected=false
minutesSinceStart=0

dofile("config.lua")
dofile("wifi.lua")
dofile("http.lua")
dofile("devicespecific.lua")

function connectToMqttIfNeeded()
  if mqttClient==nil or mqttConnected==false then    
    print("- connecting to MQTT")

    local clientID = 'nodemcu' .. wifi.sta.getip()

    print("- clientID: "..clientID.." mqtt user name: '"..mqttServerUserName.."'")

    print("- feeding watchdog")
    tmr.wdclr()
    mqttClient = mqtt.Client(clientID, mqttKeepAliceInSeconds, mqttServerUserName, mqttServerPassword, "")

    print("- created client")
    mqttClient:lwt(mqttTopic, "offline", 0, 0)
    
    print("- lwt set, connecting to '"..mqttServerIP.."'")
    mqttClient:connect(mqttServerIP, 1883, false, function(client)
      mqttConnected = true      

      print("- connected to MQTT")
      sntp.sync()

      end,
      function(client, reason)
        print("- failed to connect to MQTT: " .. reason)
        mqttClient = nil
    end)
  else
    print("- already connected to MQTT")
  end
end

function onFirstWifiConnection()
  if firstWifiConnection then
    print "- doing first WIFI connection stuff"
    
    timer:stop()

    download(otaBase..'init.lua', 'init.lua', function()
      download(otaBase..'config.lua', 'config.lua', function()
        download(otaBase..'http.lua', 'http.lua', function ()
          download(otaBase..'wifi.lua', 'wifi.lua', function ()
            download(otaBase..'devicespecific.lua', 'devicespecific.lua', function ()
              connectToMqttIfNeeded()
              timer:start()
            end)
          end)
        end)
      end)
    end)
  end
end

function readTemperatureAndHumidity()
  local status, temperature, humidity, temp_dec, humi_dec = dht.readxx(dhtPin)
  if status == dht.OK then
    print("- DHT Temperature:"..temperature..";".."Humidity:"..humidity)
    return temperature,humidity
  elseif status == dht.ERROR_CHECKSUM then
    print("- DHT Checksum error." )
  else
    print("- DHT timed out." )
  end
  
  return "NULL","NULL"
end

function getFormattedTime()
  local utcTime = rtctime.get()
  
  if utcTime==nil or utcTime==0 then
    return "1970.01.01 00:00:00"
  end
  
  local decodedTime = rtctime.epoch2cal(utcTime)
  
  -- TODO: find a method for doing the time zone and daylight-savings better
  utcTime = utcTime + utcOffsetInSeconds

  -- NOTE: does not consider "last sunday of march/october" rule. So time will be 1 hour of for up to a week
  if (decodedTime["mon"] > 3 and decodedTime["mon"] < 11) then
    utcTime = utcTime + dayLightSavingsOffsetInSeconds
  end
  
  decodedTime = rtctime.epoch2cal(utcTime)
  
  -- TODO: Make format configurable and add en-US and en-GB as coments in config
  return decodedTime["year"].."-"..decodedTime["mon"].."-"..decodedTime["day"].."T"..decodedTime["hour"]..":"..decodedTime["min"]..":"..decodedTime["sec"]
end

function createMqttPayload(temperature, humidity, formattedTime, rssi)
  return "{\n\"Temperature\": \""..temperature.."\",\n\"humidity\": \""..humidity.."\",\n\"Time\": \""..formattedTime.."\",\n\"Wifi\": {\n\"RSSI\": \""..rssi.."\"\n}\n}"
end

function sendMqttMessage(temperature, humidity, formattedTime, rssi)
  local mqttPayload = createMqttPayload(temperature, humidity, formattedTime, rssi)
  -- NOTE: If WIFI is missing this will probably trigger a restart
  local mqttSendResult = mqttClient:publish(mqttTopic .. "/SENSOR", mqttPayload, 0, 0, function(client)
    print("- sent telemetry over MQTT")
    end)
    
  if mqttSendResult==false then
    print("- error sending telemetry over MQTT. Reconnecting to MQTT")
    mqttClient:close()
    mqttClient = nil
    timer:interval(startupTimerIntervalInSeconds)
  end
end

function timerExpired()
  print("timer expired. minutesSinceStart: "..minutesSinceStart)

  if isWifiConnected() then
    onFirstWifiConnection()
    
    if mqttConnected then
      local temperature, humidity = readTemperatureAndHumidity()
      local formattedTime = getFormattedTime()
      local rssi = wifi.sta.getrssi()
      if rssi==nil then
        rssi="NULL"
      end

      sendMqttMessage(temperature, humidity, formattedTime, rssi)
      
      timer:interval(timerIntervalInSeconds)
      
      minutesSinceStart = minutesSinceStart + 1

      if minutesSinceStart > restartIntervalInMinutes then
        print("RESTARTING DEVICE AFTER '"..restartIntervalInMinutes.."' minutes.")
        node.restart()
      end
    end
  end
  
  print ("")
end

connectToWifi()

timer = tmr.create()
timer:alarm(startupTimerIntervalInSeconds, 1, timerExpired)
