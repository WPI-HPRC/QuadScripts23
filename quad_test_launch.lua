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

local roll
--local velocity = Vector3f()
--local acceleration = Vector3f_ud() --says Vector3f_ud() in the docs so might be an issue, try with this first 

local target_drop_height = 15240 -- random number that will get changed, right now it should be 500m since the alt reads in cm 
local copter_brake_mode_num = 17 
local AUTO_MODE = 3
local THROW_MODE = 18
local battery_threshold = 12 -- need to get the actual battery threshold 
local detach_servo_position = 10 -- need to get read number for this 
local servo_release_output = 1000 -- need to get real number for this
local servo_detach_output = 1000 -- need to get real number for this 
local quad_accel_threshold = 9.8 -- do we want to use gravity or a lower number 
local rc_script_start_switch = 1200
local rc_script_start_channel = 11
local rc_start_switch = 1500 -- get real value 
local rc_start_channel = 8 -- get real value 
local rc_prerelease_switch = 1500 -- get real value
local rc_prerelease_channel = 7 -- get real value

local state = 1
--need to check position of print statements 
function rocket_flight()
    gcs:send_text(0, "Rocket Flight Stage")
    if rc:get_pwm(rc_start_channel) >= rc_start_switch then
        --state = prerelease
        state = state + 1
        gcs:send_text(0, "Switching stages")
    end
    return state 
end

-- releases the arms and waits for second signal
function prerelease()
    gcs:send_text(0, "Pre-release Stage")
    if not arming:is_armed() then
        arming:arm()
        --state = abort
        --state = 0 --should there be an abort stage for every state? 

        --servo:set_output(servo_release_output, PWM) may cause errors since no values, drops arms
        --state = checking
        state = state + 1
        gcs:send_text(0, "Switching stages")

    else
        state = 0
    end
    return state
end

-- checks battery voltage, rc connection, and GPS lock before moving to the next state
function checking()
    gcs:send_text(0, "Checking Stage")
    if -- battery:voltage(instance) < battery_threshold or
        --rc:has_valid_input() == false or -- do we need this cuz it would throw an error anyway (Ask Cam)
        gps:status(instance) == GPS.NO_GPS -- just to make sure that you have a GPS lock  
    then
            --state = abort
            state = 0
    --the following code is experimental for notification of second switch, look at release script for original--
    else
        gcs:send_text(0,"FLIP SWITCH C")
    end
    
    if rc:get_pwm(rc_prerelease_channel) >= rc_prerelease_switch then
        --state = ready
        state = state + 1
        gcs:send_text(0, "Switching stages")

    else
        state = 0 --abort 
    end 
    return state 
    
end

-- checks whether the drone is at the proper height to be dropped
function ready()
    gcs:send_text(0, "Ready Stage")
    if ahrs:healthy() then --make sure a home is set 
        local home = ahrs:get_home()
        local home_alt = home:alt()
        local position = ahrs:get_position()
        local altitude = position:alt()
        local final_alt = altitude - home_alt
        if final_alt < target_drop_height then --need to be corrected for location 
            --state = detach
            state = state + 1
            gcs:send_text(0, "Switching stages")
        end
        --gcs:send_text(5, string.format("Altitude: %.1f", altitude))
    end
    return state 
    
end 

-- detaches the quad by commanding the servo that releases the quad body
function detach()
    gcs:send_text(0, "Detach Stage")
    --servo:set_output(servo_release_output, PWM) this might throw an error during launch 
    --if ahrs:get_accel() < quad_accel_threshold then
        --state = released
        if not arming:is_armed() then
            arming:arm()
        end
        state = state + 1
        gcs:send_text(0, "Switching stages")
    --end
    return state 
end

-- quad performs stabilization after entering free fall
function released()
    -- throw mode part 
    -- descends to 500 feet 
    gcs:send_text(0, "Released Stage")
    if not arming:is_armed() then
        arming:arm()
    
    else
        vehicle:set_mode(THROW_MODE)

        if ahrs:healthy() then --make sure a home is set 
            local home = ahrs:get_home()
            local home_alt = home:alt()
            local position = ahrs:get_position()
            local altitude = position:alt()
            local final_alt = altitude - home_alt
            if final_alt < 12192 then --needs to correct for location 
                arming:disarm()
            end
        end
    end
    return 
end

-- code will end up here if something's gone terribly wrong (but it won't)
function abort()
    gcs:send_text(0, "Abort")
    vehicle:set_mode(copter_brake_mode_num) -- just don't do anything, abort if quad has not been released
    if ahrs:healthy() then --make sure a home is set 
        local home = ahrs:get_home()
        local home_alt = home:alt()
        local position = ahrs:get_position()
        local altitude = position:alt()
        local final_alt = altitude - home_alt
        if final_alt < 12192 then --needs to correct for location 
            arming:disarm()
        end
    end
    return  
end

--function abort_free_fall() --we still don't know what is going in here 
    --gcs:send_text(0, "Abort Free Fall")
--end

function update()
    if rc:get_pwm(rc_script_start_channel) >= rc_script_start_switch then
    --if not arming:is_armed() then--or not vehicle:get_mode() ~= AUTO_MODE then --check logic 
        --arming:arm()
        --vehicle:set_mode(AUTO_MODE)
         -- test to see if we can arm through software 

    --elseif arming:is_armed() then --and vehicle:get_mode() ~= AUTO_MODE then
        --if necessary log data here- test if we need a command to 
        --SRV_Channels:set_output_pwm_chan_timeout(channel, pwm, timeout)--set motors off, not sure if this is the most ideal command to use 
        local acceleration = ahrs:get_accel():z()
        local velocity = ahrs:get_velocity_NED() 
        --state = 1 --1 is rocket_flight

        --returns orientation 
        roll = math.deg(ahrs:get_roll())
        if (roll > math.abs(90)) then
            gcs:send_text(0, "I am upside down")
        end

        if acceleration and velocity then 

            --if statements that print stages based on data, not sure what those baselines are...
            if acceleration > 0 then 
                gcs:send_text(0, "Launch detected")

            elseif acceleration < 0 then --check signs since drone is upsidedown 
                gcs:send_text(0, "Motor Burnout")
            end 

            if velocity:z() <= 0 then --also check signs here 
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

rocket_flight()
prerelease()
checking()
ready()
detach()
released()

return update()