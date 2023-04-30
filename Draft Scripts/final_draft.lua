--This is the current draft for the final script--
    --Includes integration of release script and cube mission script

--Current questions/unknowns that Colette can think of for testing, etc: 
    --Will arming for an instant in check_ready() trigger throwmode prematurely? 
    --Does the servo function act as an adequate timer for the quad release? 
    --To many RC switches? 
    --DOES THROW MODE EVEN WORK?? 
    --Switching to servo manual then switching back into the state machine
    --Mildly concerned about rc switches interferring with eachother 
    --Given current block diagram, what should our abort stage look like? 
    --Also mildly concered about using alt for nose_release
    --Does delaring alt in update vs functions change anything

--Flight Mode Numbers--
local GUIDED_MODE = 4
local THROW_MODE = 18
local LAND_MODE = 9 
local BRAKE_MODE = 17 

--Threshold Constants--
local target_drop_height = 15240 --500ft expressed in cm 
local main_deploy_alt = 0 --Needs to be set 
local quad_accel_threshold = 9.8 -- Correct value TBD

--RC Channel Values--
local rc_channel_S1 = 0 --Starts the script: flipped upon launch
local rc_channel_S2 = 0 --Switches out of rocket_flight(): flipped at apogee 
local rc_channel_A = 0  --Switches to cameras to observe arm deploy: flipped at arm_release()
local rc_channel_C = 0  --Confirms go for drop if arm limit switch fails: flipped once visual confirmation received
local rc_channel_D = 0  --Switches to cameras to observe arm deploy: flipped at arm_release()
local rc_channel_F = 0  --Switches out of nose_release() to arm_release(): flipped upon confirmation of payload parachute inflation

local PWM_HIGH = 1900 --these may need to be reset based on more accurate threshold values
local PWM_NEUTRAL = 1500
local PWM_LOW = 1100

--Notes on Servo Control:
    --If S1 and S2 are in neutral position, control servos manually
    --If S1 and S2 are in low position, reset to initial state = 1, implies start S1 and S2 high
    --If S1 is high and S2 is low, start script
    --If S1 is low and S2 is high, reset to the saved state 

--Servo and Button Values--
local SERVO_CUBE_UPPER = 94
local SERVO_CUBE_LOWER = 95
local SERVO_NOSECONE = 96 
local SERVO_SCREW = 97
local SERVO_ARM = 98

local servo_channel_upper = SRV_Channels:find_channel(SERVO_CUBE_UPPER) 
local servo_channel_lower = SRV_Channels:find_channel(SERVO_CUBE_LOWER)   
local servo_channel_nosecone = SRV_Channels:find_channel(SERVO_NOSECONE)
local servo_channel_screw = SRV_Channels:find_channel(SERVO_SCREW)
local servo_channel_arm = SRV_Channels:find_channel(SERVO_ARM)

local ARM_BUTTON = 1

--General Declarations--
local state = 1
local saved_state 
local stage = 0
local altitude
local acceleration
local start_loc

--State Functions--

--Rocket Flight: 
    --In-flight state from launch to apogee
    --Switches to arm_release when S2 switch triggered
function rocket_flight()
    gcs:send_text(0, "Rocket Flight Stage")
    saved_state = state
        if rc:get_pwm(rc_channel_S2) >= PWM_HIGH then --change to when payload chutes are deployed 
            state = state + 1 
        else
            state = 0; --initial_abort()
        end
    return state 
end

--Nose-release: 
    --Releases the retention system from the nosecone
function nose_release(relative_alt)
    gcs:send_text(0, "Nose Release Stage")
    saved_state = state
    if((relative_alt <= main_deploy_alt) or rc_channel_F >= PWM_HIGH) then
        SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, 1100, 1000) --need to make sure this is set to the right value
        state = state + 1 
    end

    return state 
end

-- Arm-release: 
    --Releases the arms from the retention system 
    --Confirms release and switches states through button or RC switch
function arm_release()
    gcs:send_text(0, "Arm Release Stage")
    saved_state = state
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_arm, 1100, 1000) --make sure pwm value is correct
    
    if (button:get_button_state(ARM_BUTTON)) or rc_channel_F > PWM_HIGH then --we need to check how the button class decides that button is active 
        state = state + 1 
    else
        state = 0 --initial_abort()
    end 

    return state
end


-- Check-ready: 
    --Checks whether the drone is able to arm and is at the proper height to be dropped
function check_ready(relative_alt)

    gcs:send_text(0, "Ready Stage") 
    saved_state = state  

    local armSuccess = false
    arming:arm()

    if vehicle:is_armed() then --will this make throwmode initiate? 
        armSuccess = true
        arming:disarm()
    end

    if relative_alt < target_drop_height and armSuccess == true then 
        state = state + 1 
    else
        state = 0; --initial_abort()
    end
    return state   
end 

--Detach: 
    --Detaches the quad from the retention system through a timed lead screw
    --Arms the quad 
    --Fly child 
function detach(acceleration)
    gcs:send_text(0, "Detach Stage")
    saved_state = state
      
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_screw, 1100, 5000) --delays for 5 seconds
    arming:arm()

    if (acceleration < quad_accel_threshold) and vehicle:is_armed() then
        gcs:send_text(0, "Switching stages") 
        state = state + 1
    else
        state = 0 --initial_abort()

    end     

    return state 
end

-- Released: 
    --Quad stabilizes and switches to guided mode to begin the cube mission 
function released(relative_alt)
    gcs:send_text(0, "Released Stage")
    saved_state = state

    if not arming:is_armed() then --ensures drone is still armed 
        arming:arm()
    end

    if arming:is_armed() then -- This will need to be changed once cube mission incorporated 
        state = state + 1 --once cube mission integrated, this will switch the into another state that begins the cube mission, auto
    else
        state = -1 --secondary_abort
    end
    
    return state 
end

-- Initial Abort: 
    --Abort stage if drone still attached to the retention system
    --Just disarms
function initial_abort()
    gcs:send_text(0, "Initial Abort")
    arming:disarm()
    return state 
end

-- Secondary Abort: 
    --Abort state if the drone is in free fall or during cube mission
    --May be better to just switch to manual 
function secondary_abort() 
    gcs:send_text(0, "Secondary Abort")
    vehicle:set_mode(BRAKE_MODE) --this is not correct
    vehicle:set_mode(LAND_MODE)
    return state 

end

function update()

    --Initialize and Update values--
    if ahrs:healthy() then
        local position = ahrs:get_position()
        local home = ahrs:get_home()
        if position and home then
            altitude = position:alt() - home:alt() 
        end

        acceleration = ahrs:get_accel() --check correct 
    end
    

    --RC Switch Settings--
    if rc:get_pwm(rc_channel_S1) <= PWM_LOW and rc:get_pwm(rc_channel_S2) <= PWM_LOW then --reset switch 
        state = 1; 
    end

    if rc:get_pwm(rc_channel_S1) <= PWM_LOW and rc:get_pwm(rc_channel_S2) >= PWM_HIGH then --reset switch 
        state = saved_state; 
    end

    --Script for State Machine Begins--
    if not vehicle:get_mode() == THROW_MODE then --check that vehicle is in throw mode 
        vehicle:set_mode(THROW_MODE) 
    
    elseif rc:get_pwm(rc_channel_S1) >= PWM_HIGH and rc:get_pwm(rc_channel_S1) <= PWM_LOW then --check syntax

        --State Machine--
        if state == 1 then 
            rocket_flight()
        elseif state == 2 then --2 is nose_release
            nose_release(altitude)
        elseif state == 3 then --2 is arm_release
            arm_release()
        elseif state == 4 then --3 is checking
            checking()
        elseif state == 5 then --4 is ready
            check_ready(altitude)
        elseif state == 6 then --5 is detach 
            detach(acceleration)
        elseif state == 7 then --6 is released                
            released(altitude)
        elseif state == 8 then
            gcs:send_text(0, "Execute cube mission")
            if (stage == 0) then          
                if (vehicle:get_mode() == GUIDED_MODE) then    --  to Guided mode
                  local curr_loc = ahrs:get_location()
                  if curr_loc then
                        start_loc = curr_loc          -- record start location
                      end
                  stage = stage + 3
                end
                
              elseif (stage >= 3 and stage <= 11) then   -- fly a triangle using velocity controller 
                local curr_loc = ahrs:get_location()
                local target_vel = Vector3f()           -- create velocity vector
                if (start_loc and curr_loc) then
                  local dist_NED = start_loc:get_distance_NED(curr_loc) 
        
                  --Fly to first point (N) at 2m/s
                  if (stage == 3) then
                    target_vel:x(3)
                    if (dist_NED:x() >= 10) then
                      stage = stage + 1
                    end
                  end
        
                  --Descends and drops cube 1
                  if (stage == 4) then
                    target_vel:z(3)
                    if (dist_NED:z() >= 2) then 
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drops when PWM is high
                      gcs:send_text(0, "Cube 1 Dropped")
                      stage = stage + 1
                    end
                  end
        
                  --Ascends and resets servos
                  if (stage == 5)then
                    target_vel:z(-3)
                    if (dist_NED:z() <= 1) then
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 500) --reset lower servo quickly
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000) --drop upper cube
                      stage = stage + 1
                    end
                  end
        
                  --Fly to second point SE at 2m/s
                  if (stage == 6) then
                    target_vel:x(-3)
                    target_vel:y(3) 
                    if (dist_NED:y() >= 8.6 and dist_NED:x() <= 5 ) then
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1100, 1000) --resets upper servo
                      stage = stage + 1
                    end
                  end

                   --Descends and drops cube 2
                  if (stage == 7)then
                    target_vel:z(3)
                    if (dist_NED:z() >= 2) then
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drop second cube 
                      gcs:send_text(0, "Cube 2 Dropped")
                      stage = stage + 1
                    end
                  end
                  
                  --Ascends
                  if (stage == 8)then
                    target_vel:z(-3)
                    if (dist_NED:z() <= 1) then
                      stage = stage + 1
                    end
                  end
        
                  -- Fly to third point SW at 2m/s
                  if (stage == 9) then
                    target_vel:x(-3) 
                    target_vel:y(-3)
                    if (dist_NED:y() <= 1 and dist_NED:x() <=1) then
                      stage = stage + 1
                    end
                  end
        
                --Descends and drops cube 3
                  if (stage == 10)then
                    target_vel:z(3)
                    if (dist_NED:z() >= 2) then
                      gcs:send_text(0, "Cube 3 Dropped")
                      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000)
                      stage = stage + 1
                    end
                  end
        
                  -- Ascends once again
                  if (stage == 11)then
                    target_vel:z(-3)
                    if (dist_NED:z() <= 1) then
                      stage = stage + 1
                    end
                  end
        
                  -- sends velocity request
                  if (vehicle:set_target_velocity_NED(target_vel)) then   -- send target velocity to vehicle
                    gcs:send_text(0, "pos:" .. tostring(math.floor(dist_NED:x())) .. "," .. tostring(math.floor(dist_NED:y())) .. " sent vel x:" .. tostring(target_vel:x()) .. " y:" .. tostring(target_vel:y()))
                  else
                    gcs:send_text(0, "failed to execute velocity command")
                  end
                else
                  gcs:send_text(0, "position failed")
                end

              --Switches to land mode 
              elseif (stage == 12) then  
                vehicle:set_mode(LAND_MODE)
                stage = stage + 1
              end
        elseif state == 0 then --initial abort
            initial_abort() --state == 0
        elseif state == -1 then
            secondary_abort()
        
        end

    elseif rc:get_pwm(rc_channel_S1) == PWM_NEUTRAL and rc:get_pwm(rc_channel_S1) == PWM_NEUTRAL then
        if rc_channel_A >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, 1100, 1000) 
        end
        if rc_channel_D >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_arm, 1100, 1000)
        end
        if rc_channel_C >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_screw, 1100, 5000) 
        end
    end

    return update, 1000
end 

rocket_flight() 
nose_release(altitude)
arm_release()
checking()
check_ready(altitude)
detach(acceleration)
released(altitude)
initial_abort()
secondary_abort()


return update()