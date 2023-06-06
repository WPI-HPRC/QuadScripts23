--Tests the retention system sequence--

--Please disable GPS requirements for arming 

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
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, NOSECONE_PWM, 1000) --need to make sure this is set to the right value
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
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_arm, 1100, 1000) --make sure pwm value is correct
    
    if (button:get_button_state(ARM_BUTTON)) or rc_channel_F > PWM_HIGH then --we need to check how the button class decides that button is active 
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

      if armSuccess == true then 
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
      
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_screw, 1100, 5000) --delays for 5 seconds
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
        state = state + 1 --once cube mission integrated, this will switch the into another state that begins the cube mission, auto
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
            gcs:send_text(0, "Test Complete")
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