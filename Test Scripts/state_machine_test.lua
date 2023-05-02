--Tests state machine with functions that pass in parameters--
    --consider consolidating this test script with the rc signal one


--RC Channel Values--
local rc_channel_S1 = 0 --Starts the script: flipped upon launch
local rc_channel_S2 = 0 --Switches out of rocket_flight(): flipped at apogee 
local rc_channel_A = 0  --Switches to cameras to observe arm deploy: flipped at arm_release()
local rc_channel_C = 0  --Confirms go for drop if arm limit switch fails: flipped once visual confirmation received
local rc_channel_D = 0  --Switches to cameras to observe arm deploy: flipped at arm_release()
local rc_channel_F = 0  --Switches out of nose_release() to arm_release(): flipped upon confirmation of payload parachute inflation

local PWM_HIGH = 1800 --these may need to be reset based on more accurate threshold values
local PWM_LOW = 1200

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
local altitude
local acceleration

--State Functions--

--Start Stage: 
    --Switches to read_alt() when S2 switch triggered
function start_stage()
    gcs:send_text(0, "Start Stage")
    saved_state = state
        if rc:get_pwm(rc_channel_S2) >= PWM_HIGH then --change to when payload chutes are deployed 
            state = state + 1 
        end
    gcs:send_text(0, state)   
    return state 
end

--Read-altitude: 
    --Reads the relative altitude
function read_alt(relative_alt)
    gcs:send_text(0, "Read Altitude Stage")
    saved_state = state
    gcs:send_text(relative_alt)
    if(rc_channel_F >= PWM_HIGH) then
        state = state + 1 
    end

    return state 
end


-- Check-ready: 
    --Checks whether the drone is able to arm and is at the proper height to be dropped
function check_arming_test(relative_alt)

    gcs:send_text(0, "check arming ready test") 
    saved_state = state 
    gcs:send_text(0, relative_alt)  

    local armSuccess = false
    while armSuccess == false do
        gcs:send_text(0, "attempting arm")
        arming:arm()
      end 

    if vehicle:is_armed() then --will this make throwmode initiate? 
        armSuccess = true
        arming:disarm()
    end

    if armSuccess == true then 
        gcs:send_text(0, "arming success")
        state = state + 1
    end
    gcs:send_text(0, state)  
    return state   
end 

--read_accel()
function read_accel(acceleration)
    gcs:send_text(0, "Read accleration Stage")
    saved_state = state
    gcs:send_text(0, acceleration) 

    if rc_channel_D >= PWM_HIGH then
        gcs:send_text(0, "Switching stages") 
        state = state + 1

    end    
    gcs:send_text(0, state)  

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
    
    if rc:get_pwm(rc_channel_S1) >= PWM_HIGH and rc:get_pwm(rc_channel_S1) <= PWM_LOW then --check syntax

        --State Machine--
        if state == 1 then 
            start_stage()
        elseif state == 2 then --2 is nose_release
            read_alt(altitude)
        elseif state == 3 then --2 is arm_release
            check_arming_test()
        elseif state == 5 then --4 is ready
            read_accel(acceleration)
        elseif state == 7 then --6 is released                
           gcs:send_text(0, "routine finished")
        elseif state == 0 then --initial abort
            initial_abort() --state == 0        
        end

    elseif rc:get_pwm(rc_channel_S1) == PWM_NEUTRAL and rc:get_pwm(rc_channel_S1) == PWM_NEUTRAL then
        if rc_channel_A >= PWM_HIGH then
            SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, 1100, 1000) 
        end
    end

    return update, 1000
end 

start_stage() 
read_alt(altitude)
check_arming_test()
read_accel(acceleration)
initial_abort()


return update()
