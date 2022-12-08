-- Lua script to control the release mechanisms and timing of the quadcopter payload

local target_drop_height = 500 -- random number that will get changed
local copter_brake_mode_num = 2 -- need to get actual number for brake mode  
local battery_threshold = 12 -- need to get the actual battery threshold 
local detach_servo_position = 10 -- need to get read number for this 
local servo_release_output = 1000 -- need to get real number for this
local servo_detatch_output = 1000 -- need to get real number for this 
local quad_accel_threshold = 9.8 -- do we want to use gravity or a lower number 
local rc_start_switch = 1 -- get real value 
local rc_start_channel = 1 -- get real value 
local rc_prerelease_switch = 2 -- get real value
local rc_prerelease_channel = 2 -- get real value

enum rocketStates = {
    rocket_flight, prerelease, checking, ready, detatch, released, abort
}
local state = rocket_flight

-- drone stays in this mode while being calibrated, loaded, and launched until it receives the
-- signal to start the release process
function rocket_flight()
    if rc:get_pwm(rc_start_channel) == rc_start_switch then
        state = prerelease
    end
end

-- releases the arms and waits for second signal
function prerelease()
    servo.set_output(servo_release_output, PWM)

    if not arming:is_armed() then
        state = abort
    elseif rc:get_pwm(rc_prerelease_channel) == rc_prerelease_switch then
        state = checking
    end
end

-- checks battery voltage, rc connection, and GPS lock before moving to the next state
function checking()
    if battery:voltage(instance) < battery_threshold or
        rc:has_valid_input() == false or -- do we need this cuz it would throw an error anyway (Ask Cam)
        gps:status(instance) == GPS.NO_GPS -- just to make sure that you have a GPS lock  
        then
            state = abort
        else
            state = ready
    end
end

-- checks whether the drone is at the proper height to be dropped
function ready()
    if location:alt() < target_drop_height then
        state = detatch
    end
end 

-- detatches the quad by commanding the servo that releases the quad body
function detatch()
    servo.set_output(servo_release_output, PWM) 
    if ahrs:get_accel() < quad_accel_threshold then
        state = released
    end
end

-- quad performs stabilization after entering free fall
function released()
    -- throw mode part 
    -- descends to 500 feet 
end

-- code will end up here if something's gone terribly wrong (but it won't)
function abort()
    vehicle:set_mode(copter_brake_mode_num) -- just don't do anything 
end

-- main update function called by framework, controls the states of the drone
function update()

    if not arming:is_armed() then
        state = rocket_flight
    end

    if state = rocket_flight then 
        rocket_flight()
    elseif state = prerelease then 
        prerelease()
    elseif state = checking then 
        checking()
    elseif state = ready then 
        ready()
    elseif state = detatch then 
        detatch()
    elseif state = released then 
        released()
    else
        abort()
    end
end

return update()