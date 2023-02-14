--commands servo automonously--

local rc_cube_servo = 0 
local rc_cube__switch = 0
local CUBE_SERVO_CHANNEL =0
local CUBE_SERVO_ON_PWM=0
local CUBE_SERVO_ON_TIMEOUT=0

function update()
    if rc:get_pwm(rc_cube_servo)==rc_cube__switch then
        set_output_pwm_chan_timeout(CUBE_SERVO_CHANNEL, CUBE_SERVO_ON_PWM, CUBE_SERVO_ON_TIMEOUT)
        --servo.set_output(servo_release_output, PWM)
        gcs:send_text(0, "Servo Activate")
    end
    return update, 1000
end
return update()