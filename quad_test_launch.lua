--Calibration on the ground (in manual mode) 
--Once calibrated, switch into auto for whole flight 
    --Command motors to be off 
    --Log data as soon as auto mode is activated (individual test: Check data log on SD)  

--Detect liftoff, motor burnout, apogee, landing + print to sd card 
--When in descent, when at specified alt 
    --Detect switch from cameron -decide for alternative event assuming ground fails
    --Run release checks (check for mode but not imperative)
    --Detect second switch, MAKE SURE THERE IS A WAY FOR CAM TO KNOW WHEN TO FLIP THE SWITCH- use print statement
    --Log these changes 

local altitude = Location()
local velocity = Vector3f()
local acceleration = Vector3f_ud() 

local target_drop_height = 500 -- random number that will get changed
local copter_brake_mode_num = 2 -- need to get actual number for brake mode  
local battery_threshold = 12 -- need to get the actual battery threshold 
local detach_servo_position = 10 -- need to get read number for this 
local servo_release_output = 1000 -- need to get real number for this
local servo_detach_output = 1000 -- need to get real number for this 
local quad_accel_threshold = 9.8 -- do we want to use gravity or a lower number 
local rc_start_switch = 1 -- get real value 
local rc_start_channel = 1 -- get real value 
local rc_prerelease_switch = 2 -- get real value
local rc_prerelease_channel = 2 -- get real value

local state 
--need to check position of print statements 
function rocket_flight()
    if rc:get_pwm(rc_start_channel) == rc_start_switch then
        --state = prerelease
        state = state + 1
        gcs:send_text(0, "Rocket Flight Stage")
    end
end

-- releases the arms and waits for second signal
function prerelease()
    if not arming:is_armed() then
        --state = abort
        state = 0 --should there be an abort stage for every state? 
    else 
        servo:set_output(servo_release_output, PWM)
        --state = checking
        state = state + 1
        gcs:send_text(0, "Pre-release Stage")
    end
end

-- checks battery voltage, rc connection, and GPS lock before moving to the next state
function checking()
    if battery:voltage(instance) < battery_threshold or
        rc:has_valid_input() == false or -- do we need this cuz it would throw an error anyway (Ask Cam)
        gps:status(instance) == GPS.NO_GPS -- just to make sure that you have a GPS lock  
    then
            --state = abort
            state = 0
    --the following code is experimental for notification of second switch, look at release script for original--
    else
        gcs:send_text(0,"Second Switch Ready")
    end
    
    if rc:get_pwm(rc_prerelease_channel) == rc_prerelease_switch then
        --state = ready
        state = state + 1
        gcs:send_text(0, "Checking Stage")

    else
        state = 0 --abort 
    end 
    
end

-- checks whether the drone is at the proper height to be dropped
function ready()
    if location:alt() < target_drop_height then
        --state = detach
        state = state + 1
        gcs:send_text(0, "Ready Stage")
    end
end 

-- detaches the quad by commanding the servo that releases the quad body
function detach()
    servo:set_output(servo_release_output, PWM) 
    if ahrs:get_accel() < quad_accel_threshold then
        --state = released
        state = state + 1
        gcs:send_text(0, "Detach Stage")
    end
end

-- quad performs stabilization after entering free fall
function released()
    -- throw mode part 
    -- descends to 500 feet 
    gcs:send_text(0, "Released Stage")
end

-- code will end up here if something's gone terribly wrong (but it won't)
function abort()
    vehicle:set_mode(copter_brake_mode_num) -- just don't do anything, abort if quad has not been released
    gcs:send_text(0, "Abort")
end

--function abort_free_fall() --we still don't know what is going in here 
    --gcs:send_text(0, "Abort Free Fall")
--end

function update()
    if not arming:is_armed() or not vehicle:get_mode() ~= AUTO_MODE then --check logic 
        vehicle:set_mode(AUTO_MODE)
        arming:arm() -- test to see if we can arm through software 

    elseif arming:is_armed() and vehicle:get_mode() ~= AUTO_MODE then
        --if necessary log data here- test if we need a command to 
        SRV_Channels:set_output_pwm_chan_timeout(channel, pwm, timeout)--set motors off, not sure if this is the most ideal command to use 
        altitude = alt()
        acceleration = ahrs:get_accel()
        velocity = ahrs:get_velocity_NED() 
        local vertical_velocity = velocity:z()
        state = 1 --1 is rocket_flight

        if acceleration and vertical_velocity and altitude then 

            

            --if statements that print stages based on data, not sure what those baselines are...
            if acceleration > 0 then 
                gcs:send_text(0, "Launch detected")

            elseif acceleration < 0 then --check signs since drone is upsidedown 
                gcs:send_text(0, "Motor Burnout")
            end 

            if vertical_velocity <= 0 then --also check signs here 
                gcs:send_text(0, "Apogee, begin descent and start release sequence")
        
                if state == 1 then 
                    rocket_flight()
                elseif state == 2 then --2 is prerelease
                    prerelease()
                elseif state == 3 then --3 is checking
                    checking()
                elseif state == 4 then --4 is ready
                    ready()
                elseif state == 5 then --5 is detach 
                    detach()
                elseif state == 6 then --6 is released
                    released()
                else
                    abort() --state == 0
                end

            end 
        end 
    end
    return update, 1000
end 

return update()