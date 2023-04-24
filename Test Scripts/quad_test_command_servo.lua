--commands servo (will eventually be done in auto), also checks limit switch 
--(Yes I was too lazy to make extra test files for each test...)

local rc_cube_servo = 0 
local rc_cube__switch = 0
local CUBE_SERVO_CHANNEL =0
local CUBE_SERVO_ON_PWM = 0
local CUBE_SERVO_ON_TIMEOUT=0

local servo_arm_output = 0
local SERVO1 = 94
local SERVO2 = 95
local servo_channel_upper = SRV_Channels:find_channel(SERVO1) --upper is servo 1
local servo_channel_lower = SRV_Channels:find_channel(SERVO2)   -- lower is servo 2
local PWM = 1900 
local rc_arm_release_switch = 1500 
local rc_arm_release_channel = 7
local rc_upper_chanel = 8

local ARM_BUTTON = 1


function update()

    --Servo Test-- 
    -- if rc:get_pwm(rc_cube_servo) > rc_cube__switch then --Does SRV_Channels need to be declared or something? 
    --     SRV_Channels:set_output_pwm_chan_timeout(CUBE_SERVO_CHANNEL, CUBE_SERVO_ON_PWM, CUBE_SERVO_ON_TIMEOUT)
    --     --servo.set_output(servo_release_output, PWM)
    --     gcs:send_text(0, "Servo Activate")
    -- end

    --Arm Deploy Test--
    if rc:get_pwm(rc_arm_release_channel) > 1800 then
        gcs:send_text(0, "High1")
        SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000)
         --Drops arms, again check if servo needs to be defined 
    elseif rc:get_pwm(rc_arm_release_channel) < 1000 then
        gcs:send_text(0, "Low1")
        --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1300, 1000) --Drops arms, again check if servo needs to be defined 
        SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1100, 1000)
    elseif(rc:get_pwm(rc_arm_release_channel) == 1500) then
        gcs:send_text(0, "Neutral")
    else 
        gcs:send_text(0, "Neutral")
    end

    if rc:get_pwm(rc_upper_chanel) > 1800 then
        SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000)

    elseif rc:get_pwm(rc_upper_chanel) < 1000 then
        SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 1000)
    end



    --Upper servo, cube held when PWM is low, drops when high 
    
    -- if button:get_button_state(ARM_BUTTON) then --we need to check how the button class decides that button is active 
    --     gcs:send_text(0, "Arm Drop Detected")  
    -- else
    --     gcs:send_text(0, "Not Detected") 
    -- end 
    
    -- --Release From Retention System Test--
    -- gcs:send_text(0, "Start release")
    -- servo:set_output(servo_release_output, PWM) --may need to change to timed
    -- --make sure none of these are blocking 

    --timer 
        -- time == something 
            --drone arms ; again will intiate throw mode too early 



    return update, 1000
end
return update()