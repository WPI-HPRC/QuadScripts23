--Command simple path in auto mode--
    --fly manually to specific altitude and switch into auto mode 
    --autonomously flies 20 meters and lands

local flight_distance = 10
local current_location
local state = 0
local copter_land_mode_num = 9
local START_MODE = 16

function update()

    if arming:is_armed() and vehicle:get_mode() == START_MODE then
        
        if state == 0 then
            --compare distance code to square reference, may need to declare further varibles 
            current_location = ahrs.get_location()
            if current_location then
                local start_location = current_location
                state = state + 1
            end 

        elseif state >= 1 or state <=2  then
            current_location = ahrs:get_location()
            local target_vel = Vector3f(); --this may need to be put here in the cube code
            if start_location and current_location then
                local distance = start_location:get_distance()
                state = state + 1

                if state ==2 then
                    target_vel:x(2)
                    if distance >= flight_distance then
                        state = state + 1
                    end
                end
            end
            
        elseif state == 3 then
            vehicle:set_mode(copter_land_mode_num)
        end
    end
    return update, 1000 
end

return update()