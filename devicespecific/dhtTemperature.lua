-- NOTE: 9, 10, 11 are poisonous for uploading or serial console. 5 would be GPIO14. See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
dhtPin = 2 -- GPIO04

gpio.mode(dhtPin,gpio.INPUT)

local function readTemperatureAndHumidity()
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

function createDeviceSpecificMqttPayload()

    local temperature, humidity = readTemperatureAndHumidity()

    return ", \"Temperature\": \""..temperature.."\",\n\"humidity\": \""..humidity.."\",\n"
end

function devicespecificMqttMessageHandler(message)
    if message == "restart" or message == "reset" then
        node.restart()
    end
end

function devicespecificCanRestart()
    return 1
end
