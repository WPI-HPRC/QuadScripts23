-- this script tries to act as a state machine but instead just 
-- calls the other methods whenever it has met some parameters

target_drop_height = 500 -- random number that will get changed
copter_brake_mode_num = 2 -- need to get actual number for brake mode  
battery_threshold = 12 -- need to get the actual battery threshold 
detach_servo_position = 10 -- need to get read number for this 
servo_release_output = 1000 -- need to get real number for this
servo_detatch_output = 1000 -- need to get real number for this 
quad_accel_threshold = 9.8 -- do we want to use gravity or a lower number 
rc_start_switch = 1 -- get real value 
rc_start_channel = 1 -- get real value 
rc_prerelease_switch = 2 -- get real value
rc_prerelease_channel = 2 -- get real vaue  
NO_GPS = GPS_FIX_TYPE_NO_GPS -- need to figure out more about what this does 


function update()

    if not arming:is_armed() then -- don't we want this to be armed?
        state = rocket_flight() -- call?
    end

    function rocket_flight()
        if rc:get_pwm(rc_start_channel) == rc_start_switch then
        servo.set_output(servo_release_output, PWM)
        prerelease()
        end
    end

    function prerelease()
        if not arming:is_armed() then
        abort()
        elseif rc:get_pwm(rc_prerelease_channel) == rc_prerelease_switch then
        checking()
        end
    end

    function checking()
        if battery:voltage(instance) < battery_threshold or
            rc:has_valid_input() == false or -- do we need this cuz it would throw an error anyway (Ask Cam)
            gps:status(instance) == NO_GPS -- just to make sure that you have a GPS lock  
            then
            abort()
            else
                ready()
        end
    end

    function ready() -- is  this function relevant?
        if location:alt() < target_drop_height then
            detatch()
        end
    end 

    function detatch()
        servo.set_output(servo_release_output, PWM) 
        if ahrs:get_accel() < quad_accel_threshold then
            released()
        end

    end

    function released()
        -- throw mode part 
        -- descends to 500 feet 
    end

    function abort()
        vehicle:set_mode(copter_brake_mode_num) -- just don't do anything 
    end
end

return(update)