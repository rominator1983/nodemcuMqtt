-- TODO: consider sending "stat" too for SONOFF devices with POWER
mqttTopic = "tele/outdoor/temperature"
mqttServerIP = "192.168.7.15"
wifiSSID = "your SSID here"
wifiPassword = "your password here"

-- NOTE: Must serve init.lua, config.lua, http.lua and wifi.lua (for example http://server/init.lua)
otaBase = "http://server/"

mqttServerUserName = "your user name here"
mqttServerPassword = "your password here"
mqttKeepAliceInSeconds = 60

utcOffsetInSeconds = 3600
dayLightSavingsOffsetInSeconds = 3600

timerIntervalInSeconds = 60000

startupTimerIntervalInSeconds = 1000

restartIntervalInMinutes = 240