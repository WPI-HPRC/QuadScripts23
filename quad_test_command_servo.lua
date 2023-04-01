--commands servo (will eventually be done in auto), also checks limit switch 
--(Yes I was too lazy to make extra test files for each test...)

local rc_cube_servo = 0 
local rc_cube__switch = 0
local CUBE_SERVO_CHANNEL =0
local CUBE_SERVO_ON_PWM = 0
local CUBE_SERVO_ON_TIMEOUT=0

local servo_arm_output = 0
local servo_release_output = 0
local PWM = 0 

local ARM_BUTTON = 1


function update()

    --Servo Test-- 
    -- if rc:get_pwm(rc_cube_servo) > rc_cube__switch then --Does SRV_Channels need to be declared or something? 
    --     SRV_Channels:set_output_pwm_chan_timeout(CUBE_SERVO_CHANNEL, CUBE_SERVO_ON_PWM, CUBE_SERVO_ON_TIMEOUT)
    --     --servo.set_output(servo_release_output, PWM)
    --     gcs:send_text(0, "Servo Activate")
    -- end

    --Arm Deploy Test--
    -- gcs:send_text(0, "Commence Arm Drop")
    -- servo:set_output(servo_arm_output, PWM) --Drops arms, again check if servo needs to be defined 

    -- if button:get_button_state(ARM_BUTTON) then --we need to check how the button class decides that button is active 
    --     gcs:send_text(0, "Arm Drop Detected")  
    -- else
    --     gcs:send_text(0, "Not Detected") 
    -- end 
    
    --Release From Retention System Test--
    gcs:send_text(0, "Start release")
    servo:set_output(servo_release_output, PWM) --may need to change to timed
    --make sure none of these are blocking 

    --timer 
        -- time == something 
            --drone arms ; again will intiate throw mode too early 



    return update, 1000
end
return update()