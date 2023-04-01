--Command simple path in auto mode--
    --fly manually to specific altitude and switch into auto mode 
    --autonomously flies 6 meters and lands

local flight_distance = 6 --distance in m 
--local current_location
local state = 0
local LAND_MODE = 9
local START_MODE = 16
local target_vel = Vector3f()
local start_location = Location() 

function update()

    if not arming:is_armed() then
        state = 0
    else
        if vehicle:get_mode() == START_MODE and state == 0 then
            if (vehicle:set_mode(GUIDED_MODE)) then     -- change to Guided mode
                state = state + 1
            end
        
        elseif state == 1 then
            --compare distance code to square reference, may need to declare further varibles 
            local current_location = ahrs:get_position() 
            if current_location then
                start_location = current_location
                state = state + 1
            end 

        elseif state == 2  then
            local current_location = ahrs:get_position()
            if start_location and current_location then
                local distance = start_location:get_distance(current_location) --not sure if current distance is needed 
                
                if distance <= flight_distance then
                    target_vel:x(2)
                else
                    state = state + 1
                end
        
            end
                
        elseif state == 3 then
            vehicle:set_mode(LAND_MODE)
        end
    end
    return update, 1000 
end

return update()