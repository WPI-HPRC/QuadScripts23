--Command simple path in auto mode--
    --fly manually to specific altitude and switch into auto mode 
    --autonomously flies 20 meters and lands

local flight_distance = 10 --distance in m 
--local current_location
local state = 0
local LAND_MODE = 9
local START_MODE = 16
local target_vel = Vector3f()
local start_location = Location() 
local current_location = Location()

function update()

    if arming:is_armed() and vehicle:get_mode() == START_MODE then
        
        if ahrs:healthy() then
            if state == 0 then
                --compare distance code to square reference, may need to declare further varibles 
                current_location = ahrs:get_position() 
                if current_location then
                    start_location = current_location
                    state = state + 1
                end 

            elseif state >= 1 or state <=2  then
                current_location = ahrs:get_position()
                --velocity dec here? 
                if start_location and current_location then
                    local distance = start_location:get_distance(current_location) --not sure if current distance is needed 
                    state = state + 1

                    if state == 2 then
                        target_vel:x(2)
                        if distance >= flight_distance then
                            state = state + 1
                        end
                    end
                end
                
            elseif state == 3 then
                vehicle:set_mode(LAND_MODE)
            end
        end
    end
    return update, 1000 
end

return update()