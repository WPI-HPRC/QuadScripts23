--Tests state machine with functions that pass in parameters--
    --consider consolidating this test script with the rc signal one

local THROW_MODE = 18

--RC Channel Values--
local rc_channel_S1 = 10 --Starts the script: flipped upon launch
local rc_channel_S2 = 11 --Switches out of rocket_flight(): flipped at apogee 
local rc_channel_F = 8  --Switches out of nose_release() to arm_release(): flipped upon confirmation of payload parachute inflation

local PWM_HIGH = 1800 --these may need to be reset based on more accurate threshold values
local PWM_LOW = 1200

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

--State Functions--

--Start Stage: 
    --Switches to read_alt() when S2 switch triggered
function start_stage()
    gcs:send_text(0, "Start Stage")
        if rc:get_pwm(rc_channel_S2) >= 1300 then --change to when payload chutes are deployed 
            state = state + 1 
        end
    gcs:send_text(0, state)   
    return state 
end

--Read-altitude: 
    --Reads the relative altitude
function read_alt()
    if ahrs:healthy() then
        local position = ahrs:get_position()
        local home = ahrs:get_home()
        if position and home then
            local relative_alt = position:alt() - home:alt() 
            gcs:send_text(0, "Read Altitude Stage")
            gcs:send_text(0, string.format("Relative ALt: %.1f", relative_alt))  
            if(rc:get_pwm(rc_channel_F) >= 1300) then
                state = state + 1 
                return state 
            end
        end
    end
end


-- Check-ready: 
    --Checks whether the drone is able to arm and is at the proper height to be dropped
function check_arming_test()
    if ahrs:healthy() then
        local position = ahrs:get_position()
        local home = ahrs:get_home()
        if position and home then
            local relative_alt = position:alt() - home:alt() 
            gcs:send_text(0, "check arming ready test") 
                gcs:send_text(0, string.format("Relative ALt: %.1f", relative_alt))  

                local armSuccess = false
    
                    gcs:send_text(0, "attempting arm")
                    arming:arm()
                    if arming:is_armed() then --will this make throwmode initiate? 
                        armSuccess = true
                    end
                
                 arming:disarm()

                if armSuccess == true then 
                    gcs:send_text(0, "arming success")
                    state = state + 1
                    gcs:send_text(0, state) 
                    return state   
                end 
        end
    end
end 


function update()
    
    --RC Switch Settings--
    if rc:get_pwm(rc_channel_S1) <= PWM_LOW and rc:get_pwm(rc_channel_S2) <= PWM_LOW then --reset switch 
        state = 1; 
    end

    --Script for State Machine Begins--
    if vehicle:get_mode() ~= THROW_MODE then --check that vehicle is in throw mode 
        vehicle:set_mode(THROW_MODE) 
    end

    if rc:get_pwm(rc_channel_S1) >= PWM_HIGH then --check syntax

        --State Machine--
        if state == 1 then 
            start_stage()
        elseif state == 2 then 
            read_alt()
        elseif state == 3 then 
            check_arming_test()
        elseif state == 4 then                
           gcs:send_text(0, "routine finished")    
        end

    elseif (rc:get_pwm(rc_channel_S1) > 1300 and rc:get_pwm(rc_channel_S1) < 1600) then
        if rc_channel_F >= PWM_HIGH then
            --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_nosecone, 1100, 1000) 
            gcs:send_text(0, "servo working")
        end
    end

    return update, 1000
end 

start_stage() 
read_alt()
check_arming_test()


return update()
