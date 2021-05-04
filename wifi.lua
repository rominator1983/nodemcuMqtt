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
  