mqttSubscriptionTopic = "cmnd/outdoor/temperature/POWER"
-- NOTE: should be "SENSOR" instead of "STATE" for sensory devices
mqttPublishTopic = "tele/outdoor/temperature/STATE"

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

startupTimerIntervalInSeconds = 500

-- NOTE: 0 means no restart
restartIntervalInTimerIntervals = 480