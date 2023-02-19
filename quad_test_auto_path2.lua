--Command simple path in auto mode but with rc start--
    --fly manually to specific altitude and switch into auto mode 
    --autonomously flies 20 meters and lands

local flight_distance = 10
local state = 0
local copter_land_mode_num = 9
local START_MODE = 16

local rc_position_hold = 1500
local rc_mode = 7

--arming:is_armed() and
  
function update()

    if rc:get_pwm(rc_mode) >= rc_position_hold then
            
        if state == 0 then
            --compare distance code to square reference, may need to declare further varibles 
            local current_location = ahrs:get_position()
            gcs:send_text(0, string.format("Location:", current_location))
            if current_location then
                local start_location = current_location
                gcs:send_text(0, string.format("Start Location:", start_location))
                state = state + 1
            end 
    
        elseif state >= 1 or state <=2  then
            local current_location = ahrs:get_position()
            --local target_vel = Vector3f(); --this may need to be put here in the cube code
            if start_location and current_location then
                local distance = start_location:get_distance()
                gcs:send_text(0, string.format("Distance", distance))
                state = state + 1
    
                if state ==2 then
                    -- target_vel:x(2)
                    if distance >= flight_distance then
                        state = state + 1
                        gcs:send_text("State 2, should end here")
                    end
                end
            end
                
        elseif state == 3 then
            --vehicle:set_mode(copter_land_mode_num)
            gcs:send_text("Landing Now")
        end
    end
    return update, 1000 
end
    
return update()