-- TODO: Move to config file even if this is device specific and maybe rename to something with powerDevice or similiar
-- NOTE: Config section
-- NOTE: See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
local buttonPin = 3
local relaisPin = 6
powerIndicatorPin = 7
-- NOTE: a very big debounce time since no multi presses or long holds are implemented at the moment. See https://en.wikipedia.org/wiki/Switch#Contact_bounce
local buttonDebounceTimeInMilliseconds = 300
local relaisStateOnPowerOn = 0
local autoPowerOffInSeconds = 1800

local relaisState = relaisStateOnPowerOn

local powerOffTimer = tmr.create()

gpio.mode(buttonPin,gpio.INT)
gpio.mode(relaisPin,gpio.OUTPUT)

-- TODO: read from flash?
if relaisStateOnPowerOn == 0 then
    gpio.write(relaisPin, gpio.LOW)
else
    gpio.write(relaisPin, gpio.HIGH)
end

function powerOn()
    gpio.write(relaisPin, gpio.HIGH)
    relaisState = 1

    if autoPowerOffInSeconds > 0 then
        powerOffTimer:alarm (autoPowerOffInSeconds *  1000, tmr.ALARM_SINGLE, function ()
            powerOff()
        end)
    end

    sendMqttTeleMessage()
end    

function powerOff()
    gpio.write(relaisPin, gpio.LOW)
    relaisState = 0
    sendMqttTeleMessage()
end    

local function handleButtonPress ()
    if relaisState == 0 then
        powerOn()
    else
        powerOff()
    end
end

local lastWhen = 0

local function interrupt(level, when, eventCount)
    gpio.trig(buttonPin, "none", interrupt)
    
    print("- when: "..when)

    if when >= (lastWhen + (buttonDebounceTimeInMilliseconds*1000)) then
        lastWhen = when
        handleButtonPress ()
    end
    
    gpio.trig(buttonPin, "up", interrupt)
end

function createDeviceSpecificMqttPayload()
    if relaisState == 0 then
        return ", \"POWER\": \"OFF\"\n"
    else
        return ", \"POWER\": \"ON\"\n"
    end
end

function devicespecificMqttMessageHandler(message)
    if message == "ON" or message == "true" then
        powerOn()
    end
    if message == "OFF" or message == "false" then
        powerOff()
    end

    if message == "restart" or message == "reset" then
        powerOff()
        node.restart()
    end
end

function devicespecificCanRestart()
    if relaisState == 0 then
        return 1
    else
        return 0
    end
end

gpio.trig(buttonPin, "up", interrupt)