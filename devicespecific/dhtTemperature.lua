-- TODO: Move to DHT device specific thingies.
-- NOTE: 9, 10, 11 are poisonous for uploading or serial console. 5 would be GPIO14. See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
dhtPin = 2 -- GPIO04

gpio.mode(dhtPin,gpio.INPUT)

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

function createMqttPayload()

    -- TODO: re-implement device specific
    --local temperature, humidity = readTemperatureAndHumidity()

    --return "{\n\"Temperature\": \""..temperature.."\",\n\"humidity\": \""..humidity.."\",\n\"Time\": \""..formattedTime.."\",\n\"Wifi\": {\n\"RSSI\": \""..rssi.."\"\n}\n}"
end
