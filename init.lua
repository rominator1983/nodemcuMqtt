-- TODO: Move to DHT device specific thingies.
-- NOTE: 9, 10, 11 are poisonous for uploading or serial console. 5 would be GPIO14. See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
dhtPin = 2 -- GPIO04
gpio.mode(dhtPin,gpio.INPUT)

firstWifiConnection = true

mqttClient=nil
mqttConnected=false
minutesSinceStart=0

dofile("config.lua")

function listap(t)
  for bssid,v in pairs(t) do
    local rssi = string.match(v, "[^,]*,([^,]*).*")
    print(bssid.." "..rssi.." raw: "..v)
  end
end

function connectToWifi()
  print ("MAC:"..wifi.sta.getmac())

  wifi.setmode(wifi.STATION)
  wifi.sta.getap(1, function(t)
    -- TODO: implement searching for the WIFI with the highest RSSI to connect to. see https://nodemcu.readthedocs.io/en/release/modules/wifi/#wifistagetap on listing WIFIs etc.
    listap(t)

    local stationConfig={}
    stationConfig.ssid=wifiSSID
    stationConfig.pwd=wifiPassword
    stationConfig.save=false
    stationConfig.auto=true
    wifi.sta.clearconfig()
    wifi.sta.config(stationConfig)
    wifi.sta.connect()  
  end)
end

function isWifiConnected()
  local rssi = wifi.sta.getrssi()

  if rssi==nil then
    print("- not connected to WIFI")
    return false
  else
    print("- wifi connected. rssi: "..rssi)
  end

  ip = wifi.sta.getip()
  if ip==nil then
    print("- got no ip")
    return false
  else
    print("- ip: "..ip)
    return true
  end
end

-- TODO: handle compilation and callbacks etc. Overwriting should ideally only happen if all things could get downloaded
function download(url,fileName)
  http.get(url, nil, function(code, data)
    if code==200 then
      print("- HTTP request for OTA succeeded. Writing '"..fileName.."'")
      
      if file.open(fileName, "w+") then
        file.write(data)
        file.close()
        print("- written '"..fileName.."'")
      else
        print("- error writing '"..fileName.."'")
      end
      
      firstWifiConnection = false
    else
      print("- HTTP request for '"..url.."' failed.")
    end
  end)
end

function onFirstWifiConnection()
  if firstWifiConnection then
    print "- doing first WIFI connection stuff"
    
    download(otaInit)
    -- TODO: Enable this
    --download(otaConfig)

  end
end

function connectToMqttIfNeeded()
  if mqttClient==nil or mqttConnected==false then    
    print("- connecting to MQTT")

    local clientID = 'client_' .. wifi.sta.getip()

    
    mqttClient = mqtt.Client(clientID, mqttKeepAliceInSeconds, mqttServerUserName, mqttServerPassword, "")
    mqttClient:lwt(mqttTopic, "offline", 0, 0)
    
    mqttClient:connect(mqttmqttServerIP, 1883, false, function(client)
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
    connectToMqttIfNeeded()
    
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
      if minutesSinceStart > 240 then
        node.restart()
      end
    end
  end
  
  print ("")
end

connectToWifi()

timer = tmr.create()
timer:alarm(startupTimerIntervalInSeconds, 1, timerExpired)
