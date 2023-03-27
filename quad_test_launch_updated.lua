--Updated Test Launch Release Script (Following 3/18 Launch)--

--Add description here

local BRAKE_MODE = 17 
local AUTO_MODE = 3
local THROW_MODE = 18
local LAND_MODE = 0 --find value 

--Threshold Constants--
local target_drop_height = 15240 --500ft expressed in cm 
local battery_threshold = 12 -- need to get the actual battery threshold and decide if we are using it as a check 
local quad_accel_threshold = 9.8 -- do we want to use gravity or a lower number 

local detach_servo_position = 10 -- need to get reaL number for this 
local servo_release_output = 1000 -- need to get real number for this
local servo_detach_output = 1000 -- need to get real number for this 


--RC Values--
local rc_script_start_switch = 1200
local rc_script_start_channel = 11
local rc_start_switch = 1500 
local rc_start_channel = 8  
local rc_arm_release_switch = 1500 
local rc_arm_release_channel = 7 
local rc_state_reset_switch = 1500 
local rc_state_reset_channel = 0 -- get real value

--Servo Values--

--General Declarations--
local roll
--local velocity = Vector3f()
--local acceleration = Vector3f_ud() --says Vector3f_ud() in the docs so might be an issue, try with this first 
local state = 1

--Rocket Flight: exists in current state until Apogee then switches to arm_release when RC switch triggered--
function rocket_flight()

    gcs:send_text(0, "Rocket Flight Stage")

    --Gets acceleration, velocity--
    local acceleration = ahrs:get_accel():z()
    local velocity = ahrs:get_velocity_NED() 

    if acceleration and velocity then 

        --if statements that print stages based on data, not sure what those baselines are...
        if acceleration > 0 then --Find way to only print once
            gcs:send_text(0, "Launch detected")

        elseif acceleration < 0 then --check signs since drone is upsidedown 
            gcs:send_text(0, "Motor Burnout")
        end 

        if velocity:z() <= 0 then --check that this is instantaneous velocity
            --think the problem with the stages was due to velocity updating
            gcs:send_text(0, "Apogee, begin descent and start release sequence")
        end

        if rc:get_pwm(rc_start_channel) >= rc_start_switch then --change to when payload chutes are deployed 
            gcs:send_text(0, "Switching stages")
            state = state + 1 --switch state to arm_release

        else
            state = 0; --abort
            
        end
    end
    return state 
end

-- Arm-release: drops the arms from the retention system and waits for second signal either from button or rc to switch states
function arm_release()
    gcs:send_text(0, "Pre-release Stage")
    servo:set_output(servo_release_output, PWM) --Drops arms
    if button (limit switch) pressed || camera rc switch flipped then --edit to reflect, add camera stuff 
        gcs:send_text(0, "Switching stages")
        state = state + 1 --switch state to checking

    else
        state = 0 --abort
    end
    return state
end

-- Checking: checks battery voltage, rc connection, and GPS lock 
--and waits for pilot command before moving to the next state

--Whether or not we have tests here depends on testing 
function checking() --combine with arm release 
    gcs:send_text(0, "Checking Stage") --delete this/move to arm 
    if battery:voltage(instance) < battery_threshold or
        rc:has_valid_input() == false or -- do we need this cuz it would throw an error anyway (Ask Cam)
        gps:status(instance) == GPS.NO_GPS -- just to make sure that you have a GPS lock  
    then
        state = 0 --abort 
    
    else
        gcs:send_text(0,"FLIP SWITCH C")
    end
    
    if rc:get_pwm(rc_arm_release_channel) >= rc_arm_release_switch then
        
        gcs:send_text(0, "Switching stages") --Switches into ready state
        state = state + 1

    else
        state = 0 --abort 
    end 

    return state 
    
end

-- Ready: checks whether the drone is at the proper height to be dropped and can arm
function ready()
    gcs:send_text(0, "Ready Stage")
    if ahrs:healthy() then 

        --Initialize location (may need to do this at the top for cube mission)--
        local home = ahrs:get_home()
        local home_alt = home:alt()
        local position = ahrs:get_position()
        local altitude = position:alt()
        local final_alt = altitude - home_alt
        local armSuccess = false

        arming:arm()
        if vehicle:is_armed() then --will throwmode intiate here? Or will it be too fast? 
            armSuccess = true
            arming:disarm()
        end

        if final_alt < target_drop_height and armSuccess == true then 
            state = state + 1 --Switches into detach state
            gcs:send_text(0, "Switching stages")

        else
            state = 0; --abort
        end
        --gcs:send_text(5, string.format("Altitude: %.1f", altitude))
    end
    return state 
    
end 

--Detach: detaches the quad by commanding the servo that releases the quad body
function detach()
    gcs:send_text(0, "Detach Stage")
    servo:set_output(servo_release_output, PWM) --may need to change to timed
    --make sure none of these are blocking 

    --timer 
        -- time == something 
            --drone arms ; again will intiate throw mode too early 

    if ahrs:get_accel() < quad_accel_threshold then
       
        gcs:send_text(0, "Switching stages") 
        state = state + 1

    else
        state = 0 --abort

    end     

    return state 
end

-- Released: quad performs stabilization after entering free fall
function released()
    gcs:send_text(0, "Released Stage")

    if not arming:is_armed() then --ensures drone is still armed 
        arming:arm()
    

   else
        if ahrs:healthy() then --make sure a home is set 
            local home = ahrs:get_home()
            local home_alt = home:alt()
            local position = ahrs:get_position()
            local altitude = position:alt()
            local final_alt = altitude - home_alt
            if final_alt < 12192 then -- This will need to be changed once cube mission incorporated 
                state = state + 1 --once cube mission integrated, this will switch the into another state that begins the cube mission, auto
            end

        else
            state = 10; 
        end
    
    end
    return state 
end

-- Initial Abort: code will end up here if something's gone terribly wrong (but it won't)
function initial_abort()
    gcs:send_text(0, "Initial Abort")
    arming:disarm()
    return state 
end

-- Secondary Abort: abort state if the drone is in free fall or during cube mission
function secondary_abort() 
    gcs:send_text(0, "Secondary Abort")
    vehicle:set_mode(BRAKE_MODE)
    --delay
    vehicle:set_mode(LAND_MODE)
    return state 

end

function update()

    if not vehicle:get_mode() == THROW_MODE then
        vehicle:set_mode(THROW_MODE) 
    

    elseif rc:get_pwm(rc_script_start_channel) >= rc_script_start_switch and vehicle:get_mode() == THROW_MODE then --check syntax

        if rc:get_pwm(rc_state_reset_channel) >= rc_state_reset_switch then --reset switch 
            state = 1; 
        end

        --Returns orientation-- 
        roll = math.deg(ahrs:get_roll())
        if (roll > math.abs(90)) then
            gcs:send_text(0, "I am upside down")
        end 

        --State Machine--
        if state == 1 then --Figure out how to start once velocity is <0 and not constantly update
            rocket_flight()
        elseif state == 2 then --2 is arm_release
            arm_release()
        elseif state == 3 then --3 is checking
            checking()
        elseif state == 4 then --4 is ready
            ready()
        elseif state == 5 then --5 is detach 
            detach()
        elseif state == 6 then --6 is released                
            released()
        elseif state == 7 then
            gcs:send_text(0, "Routine finished")
        elseif state == 0 then --initial abort
            initial_abort() --state == 0
        elseif state == 10 then
            secondary_abort()
        
        end
    end
    return update, 1000
end 

rocket_flight()
arm_release()
checking()
ready()
detach()
released()
initial_abort()
secondary_abort()


return update()