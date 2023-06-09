--Tests the retention system sequence--

--Please disable GPS requirements for arming 

--Flight Mode Numbers--
local GUIDED_MODE = 4
local THROW_MODE = 18
local LAND_MODE = 9 
local BRAKE_MODE = 17 

--Threshold Constants--
local target_drop_height = 200 --Units in ft? 
local main_deploy_alt = 1400 --Was originally 400 in Cam's code but may have been a typo
--Also, since the nosecone pins retract before the black power ejects the payload, should this value be slighty greater than 1400ft? 

--RC Channel Values-- CHANGE
local rc_channel_S1 = 10 --Starts the state machine: flipped upon launch
local rc_channel_S2 = 11 --Switches out of rocket_flight(): flipped at apogee 
local rc_channel_B = 6  --Manual mode for nosecone switches 
local rc_channel_F = 8  --Secondary switch for arm release if limit switch fails: flipped upon confirmation of payload parachute inflation, also used for manual mode as well
local rc_channel_C = 0 --NEEDS TO BE SET, releases the arms upon visual confirmation of parachute deployment

local PWM_HIGH = 1800 --these may need to be reset based on more accurate threshold values
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
local ARM_PWM = 1100 --set upon tests
local LEADSCREW_PWM = 1100 --set upon tests

local ARM_BUTTON = 1

--General Declarations--
local state = 1
local stage = 0
local start_loc
local firstRun = true

local startTime = 0
local endTime = 0
local gpsTime = 0
local timeDiff = 0

--State Functions--

--Rocket Flight: 
    --In-flight state from launch to apogee
    --Switches to arm_release when S2 switch triggered
function rocket_flight()
    gcs:send_text(0, "Rocket Flight Stage")
        if rc:get_pwm(rc_channel_S2) >= 1300 then 
            state = state + 1 
        end
    return state 
end

--Nose-release: 
    --Releases the retention system from the nosecone
function nose_release()
    gcs:send_text(0, "Nose Release Stage")
    -- if ahrs:healthy() then
    --   local position = ahrs:get_position()
    --   local home = ahrs:get_home()
    --   if position and home then
    --       local relative_alt = position:alt() - home:alt() 
          if(rc:get_pwm(rc_channel_C) < PWM_LOW) then 
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, NOSECONE_PWM, 1000) 
                  state = state + 1 
          end
    --   end
    -- end
    return state 
end

-- Arm-release: 
    --Releases the arms from the retention system 
    --Confirms release and switches states through button or RC switch
function arm_release()
    gcs:send_text(0, "Arm Release Stage")

    if rc:get_pwm(rc_channel_C) > PWM_HIGH then --Allows for visual confirmation of parachute deployment 
      SRV_Channels:set_output_pwm_chan_timeout(servo_channel_arm, ARM_PWM, 1000) 
    end

    if (rc:get_pwm(rc_channel_F) > PWM_HIGH or not button:get_button_state(ARM_BUTTON)) then --we need to check how the button class decides that button is active 
        state = state + 1 
    end

    return state
end


-- Check-ready: 
    --Checks whether the drone is able to arm and is at the proper height to be dropped
function check_ready()
  gcs:send_text(0, "Ready Stage") 

--   if ahrs:healthy() then
--     local position = ahrs:get_position()
--     local home = ahrs:get_home()

--     if position and home then

--       local relative_alt = position:alt() - home:alt() 
      local armSuccess = false

      gcs:send_text(0, "Attempting arm")
      arming:arm()
    

      if arming:is_armed() then --will this make throwmode initiate? 
          armSuccess = true
          arming:disarm()
          gcs:send_text(0, "Arm success, disarming")
      end

      if armSuccess == true then 
          state = state + 1 
          return state   
      end
    -- end

    -- end
    
end 

--Detach: 
    --Detaches the quad from the retention system through a timed lead screw
    --Arms the quad 
    --Fly child 
function detach()
    gcs:send_text(0, "Detach Stage")
      
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_screw, LEADSCREW_PWM, 5000) 

    if firstRun then 
      startTime = gps:time_week_ms(0) 
      gcs:send_text(0, "First Run")
      firstRun = false
      return state 

    else 
      endTime = gps:time_week_ms(0)
      timeDiff = endTime - startTime
      if timeDiff < 5000 then --Where 5000 ms is the time delay
        return state --make sure the structure of this function in terms of returning states works and doesn't arm early for some reason 
      end
    end

    arming:arm()

    if arming:is_armed() then
        --gcs:send_text(0, "Switching stages") 
        state = state + 1
    end     

    return state 
end

-- Released: 
    --Quad stabilizes and switches to guided mode to begin the cube mission 
function released() --figure this out, should have altitude readings? This state is also kind of sloppy 
    gcs:send_text(0, "Released Stage")

    if not arming:is_armed() then --ensures drone is still armed, don't think this check is necessary but could be good to have
        arming:arm()
    end

    if arming:is_armed() then --ensures quad is in guided mode 
      state = state + 1
    end 
    
    return state 
end

function update()

    --RC Switch Settings--
    if rc:get_pwm(rc_channel_S1) <= PWM_LOW and rc:get_pwm(rc_channel_S2) <= PWM_LOW then --reset switch 
        state = 1; --resets state machine
        firstRun = true
    end

    --Script for State Machine Begins--
    if vehicle:get_mode() ~= THROW_MODE and state < 6 then --check that vehicle is in throw mode if not in release() or cube missison 
        vehicle:set_mode(THROW_MODE) 
    end
    
    if rc:get_pwm(rc_channel_S1) >= PWM_HIGH then --check syntax, changed from elseif after throwmode check to if 

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
            gcs:send_text(0, "End of Test")
        
        end

    elseif (rc:get_pwm(rc_channel_S1) > 1300 and rc:get_pwm(rc_channel_S1) < 1600) then
        if rc_channel_B >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, NOSECONE_PWM, 1000) 
        end
    end

    return update, 1000
end 

-- rocket_flight()
-- nose_release()
-- arm_release()
-- check_ready()
-- detach()
-- released()


return update()