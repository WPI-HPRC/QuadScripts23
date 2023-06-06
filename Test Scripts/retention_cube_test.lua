--Tests modified retention script into cube mission to ensure clean transition--

--Flight Mode Numbers--
local GUIDED_MODE = 4
local THROW_MODE = 18
local LAND_MODE = 9 
local BRAKE_MODE = 17 

--Threshold Constants--
local target_drop_height = 15240 --500ft expressed in cm 
-- local main_deploy_alt = 0 --Needs to be set 
-- local quad_accel_threshold = 9.8 -- Correct value TBD

--RC Channel Values--
local rc_channel_S1 = 10 --Starts the script: flipped upon launch
local rc_channel_S2 = 11 --Switches out of rocket_flight(): flipped at apogee 
local rc_channel_B = 6  --not assigned
local rc_channel_E = 5 --manual nosecone switch
local rc_channel_F = 8  --Switches out of nose_release() to arm_release(): flipped upon confirmation of payload parachute inflation

local PWM_HIGH = 1800 --these may need to be reset based on more accurate threshold values
--Add thresholds for neutrals
local PWM_LOW = 1200

--Notes on Servo Control: (need to edit to make more accurate)
    --Start position: S1 and S2 down- this also resets state to 1 if reset is required
    --S1 up to enter rocket_flight
    --S2 (and still S1) up to leave rocket_flight at apogee
    --S1 neutral to enter manual mode 

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

local NOSECONE_PWM = 0 --set at IREC

local ARM_BUTTON = 1

--General Declarations--
local state = 1
local stage = 0
local start_loc

--State Functions--

--Rocket Flight: 
    --In-flight state from launch to apogee
    --Switches to arm_release when S2 switch triggered
function rocket_flight()
    gcs:send_text(0, "Rocket Flight Stage")
        if rc:get_pwm(rc_channel_S2) >= 1300 then --change to when payload chutes are deployed 
            state = state + 1 
        end
    return state 
end

--Nose-release: 
    --Releases the retention system from the nosecone
function nose_release()
    gcs:send_text(0, "Nose Release Stage")
    if ahrs:healthy() then
      local position = ahrs:get_position()
      local home = ahrs:get_home()
      if position and home then
          local relative_alt = position:alt() - home:alt() 
          if(relative_alt <= main_deploy_alt) then --change to RC
                  --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, NOSECONE_PWM, 1000) --need to make sure this is set to the right value
                  state = state + 1 
              end
      end
    end
    return state 
end

-- Arm-release: 
    --Releases the arms from the retention system 
    --Confirms release and switches states through button or RC switch
function arm_release()
    gcs:send_text(0, "Arm Release Stage")
    --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_arm, 1100, 1000) --make sure pwm value is correct
    
    if rc_channel_F > PWM_HIGH then --we need to check how the button class decides that button is active 
        state = state + 1 
    end

    return state
end


-- Check-ready: 
    --Checks whether the drone is able to arm and is at the proper height to be dropped
function check_ready()
  gcs:send_text(0, "Ready Stage") 

  if ahrs:healthy() then
    local position = ahrs:get_position()
    local home = ahrs:get_home()

    if position and home then

      local relative_alt = position:alt() - home:alt() 
      gcs:send_text(0, string.format("Relative ALt: %.1f", relative_alt))  
      local armSuccess = false

      gcs:send_text(0, "attempting arm")
      arming:arm()
    

      if arming:is_armed() then --will this make throwmode initiate? 
          armSuccess = true
          arming:disarm()
      end

      if  armSuccess == true then 
          state = state + 1 
          return state   
      end
    end

  end
    
end 

--Detach: 
    --Detaches the quad from the retention system through a timed lead screw
    --Arms the quad 
    --Fly child 
function detach()
    gcs:send_text(0, "Detach Stage")
      
    --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_screw, 1100, 5000) --delays for 5 seconds
    arming:arm()

    if (rc:get_pwm(rc_channel_E) > PWM_HIGH) and arming:is_armed() then
        gcs:send_text(0, "Switching stages") 
        state = state + 1

    end     

    return state 
end

-- Released: 
    --Quad stabilizes and switches to guided mode to begin the cube mission 
function released() --figure this out, should have altitude readings? This state is also kind of sloppy 
    gcs:send_text(0, "Released Stage")

    if not arming:is_armed() then --ensures drone is still armed 
        arming:arm()
    end

    if arming:is_armed() then -- This will need to be changed once cube mission incorporated 
        gcs:send_text(0, "YEET HIM")
         --once cube mission integrated, this will switch the into another state that begins the cube mission, auto
    end

    if vehicle:get_mode() == GUIDED_MODE then 
        state = state + 1
    end 

    return state 
end

function update()

    --RC Switch Settings--
    if rc:get_pwm(rc_channel_S1) <= PWM_LOW and rc:get_pwm(rc_channel_S2) <= PWM_LOW then --reset switch 
        state = 1; --resets state machine
    end

    --Script for State Machine Begins--
    if vehicle:get_mode() ~= THROW_MODE then --check that vehicle is in throw mode 
        vehicle:set_mode(THROW_MODE) 
    
    elseif rc:get_pwm(rc_channel_S1) >= PWM_HIGH then --check syntax

        --State Machine--
        if state == 1 then 
            rocket_flight()
        elseif state == 2 then --2 is nose_release
            nose_release()
        elseif state == 3 then --3 is arm_release
            arm_release()
        elseif state == 4 then --4 is checking
            check_ready()
        elseif state == 5 then --5 is detach 
            detach()
        elseif state == 6 then --6 is released                
            released()
        elseif state == 7 then
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
                    if (dist_NED:x() >= 200) then
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
                    if (dist_NED:y() >= 173.2 and dist_NED:x() <= 100 ) then
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
        
        end

    elseif (rc:get_pwm(rc_channel_S1) > 1300 and rc:get_pwm(rc_channel_S1) < 1600) then
        if rc_channel_F >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, NOSECONE_PWM, 1000) 
        end
    end

    return update, 1000
end 

rocket_flight() 
nose_release()
arm_release()
check_ready()
detach()
released()


return update()