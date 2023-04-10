--commands servo (will eventually be done in auto), also checks limit switch 
--(Yes I was too lazy to make extra test files for each test...)


local SERVO1 = 94
local SERVO2 = 95
local servo_channel1 = SRV_Channels:find_channel(SERVO1)
local servo_channel2 = SRV_Channels:find_channel(SERVO2)
local PWM = 1900 
local rc_arm_release_switch = 1500; 
local rc_arm_release_channel = 7; 
local state = 0

function high()
    gcs:send_text(0, "High")
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel1, 1500, 1000)
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel2, 1500, 1000)
    state = 1
    return state
end

function low()
    gcs:send_text(0, "Low")
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel1, 1400, 1000)
    SRV_Channels:set_output_pwm_chan_timeout(servo_channel2, 1400, 1000)
    state = 0
    return state 
end 

function update()

    if rc:get_pwm(rc_arm_release_channel) >= rc_arm_release_switch then
        if state == 0 then
            high()
        elseif state == 1 then
            low()
        end
    end



    return update, 1000
end
high()
low()
return update()