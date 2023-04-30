--Command simple path in auto mode but with rc start--
    --fly manually to specific altitude and switch into auto mode 
    --autonomously flies 20 meters and lands
    ----Out-dated in terms of syntax, disregard as a reference

local flight_distance = 10
local state = 0
local LAND_MODE = 9
local START_MODE = 16
local GUIDED_MODE = 4

local rc_position_hold = 1500
local rc_mode = 7

-- local target_vel = Vector3f() --this may need to be put here in the cube code
-- local current_location = Location() 
local start_location 

--arming:is_armed() and
  
function update()

    if not arming:is_armed() then 
        state = 0
    
    else 
        pwm = rc:get_pwm(rc_mode)
        if pwm and pwm >= rc_position_hold then 
            if state == 0 then
                if vehicle:set_mode(GUIDED_MODE) then
                    state = state + 1
                end
            elseif (state == 1) then
                --stuff here 
            end
        
        if ahrs:healthy() then    
            if state == 0 then
                --compare distance code to square reference, may need to declare further varibles 
                current_location = ahrs:get_position()
                --gcs:send_text(0, string.format("Location-  Lat: %.1f   Lng: %.1f     Alt: %.1f", current_location:lat(), current_location:lng(), current_location():alt()))
                if current_location then
                    start_location = current_location
                    --gcs:send_text(0, string.format("Start Location- Lat: %.1f   Lng: %.1f     Alt: %.1f ", start_location:lat(), start_location:lng(), start_location:alt()))
                    state = state + 1
                end 
        
            elseif state >= 1 or state <=2  then
                current_location = ahrs:get_position()
                --local target_vel = Vector3f(); 
                if start_location and current_location then
                    local distance = start_location:get_distance(current_location)
                   -- gcs:send_text(0, string.format("Distance", distance))
                    state = state + 1
        
                    if state ==2 then
                        target_vel:x(2)
                        if distance >= flight_distance then
                            state = state + 1
                           -- gcs:send_text("State 2, should end here")
                        end
                    end
                end
                    
            elseif state == 3 then
                vehicle:set_mode(LAND_MODE)
                gcs:send_text("Landing Now")
            end
        end
    end
    end
    return update, 1000 
end
    
return update()