-- TODO: Move to config file even if this is device specific
-- NOTE: Config section
-- NOTE: See https://nodemcu.readthedocs.io/en/dev/modules/gpio/
local buttonPin = 3
local relaisPin = 6
local powerIndicatorPin = 7
-- NOTE: a very big debounce time since no multi presses or long holds are implemented at the moment. See https://en.wikipedia.org/wiki/Switch#Contact_bounce
local buttonDebounceTimeInMilliseconds = 300
local relaisStateOnPowerOn = 0

local relaisState = relaisStateOnPowerOn

gpio.mode(buttonPin,gpio.INT)
gpio.mode(relaisPin,gpio.OUTPUT)
gpio.mode(powerPin,gpio.OUTPUT)

-- TODO: Could be signalling something else
gpio.write(powerPin, gpio.LOW)

if relaisStateOnPowerOn == 0 then
    gpio.write(relaisPin, gpio.LOW)
else
    gpio.write(relaisPin, gpio.HIGH)
end

local lastWhen = 0

local function handleButtonPress ()
    if relaisState == 0 then
        gpio.write(relaisPin, gpio.HIGH)
        relaisState = 1
    else
        gpio.write(relaisPin, gpio.LOW)
        relaisState = 0
    end

    -- TODO: Signal state over MQTT
end

local function interrupt(level, when, eventCount)
    gpio.trig(buttonPin, "none", interrupt)
    
    print("- when: "..when)

    if when >= (lastWhen + (buttonDebounceTimeInMilliseconds*1000)) then
        lastWhen = when
        handleButtonPress ()
    end
    
    gpio.trig(buttonPin, "up", interrupt)
end

-- TODO: subscribe to MQTT

gpio.trig(buttonPin, "up", interrupt)