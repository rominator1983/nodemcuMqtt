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

            -- TODO: configure sub-topic
            mqttClient:subscribe("cmnd/"..mqttTopic.."/POWER",0, function (client)
                print("- subscribed to '"..mqttTopic.."' successfully.")
            end)

            mqttClient:on("message", function(client, topic, message)
                devicespecificMqttMessageHandler(message)
            end)

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
  
function createMqttPayload(formattedTime, rssi)
    -- TODO: Add more device specific information as tasmota does too?
    return "{\n\"Time\": \""..formattedTime.."\",\n\"Wifi\": {\n\"RSSI\": \""..rssi.."\"\n}\n"..createDeviceSpecificMqttPayload().."}"
end

function sendMqttTeleMessage()

    -- TODO: away!
    local temperature, humidity = "NULL","NULL"
  
    local formattedTime = getFormattedTime()
    local rssi = wifi.sta.getrssi()
    if rssi==nil then
      rssi="NULL"
    end

    local mqttPayload = createMqttPayload(formattedTime, rssi)
    -- NOTE: If WIFI is missing this will probably trigger a restart

    -- TODO: topic would be "SENSOR" so let this be configured
    local mqttSendResult = mqttClient:publish("tele/"..mqttTopic.."/STATE", mqttPayload, 0, 0, function(client)
      print("- sent telemetry over MQTT")
      end)
      
    if mqttSendResult==false then
      print("- error sending telemetry over MQTT. Reconnecting to MQTT")
      mqttClient:close()
      mqttClient = nil
      timer:interval(startupTimerIntervalInSeconds)
    end
end
  