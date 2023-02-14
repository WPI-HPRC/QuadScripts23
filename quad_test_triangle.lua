--fly triangle autonoumously-- adjust altitude values depending on how payload wants to test

local AUTO_MODE = 0 --need to set values
local COPTER_LAND_MODE_NUM = 0

local OFFSET_NORTH_1 = 17.3 --these values are offsets for an equiliateral triangle with 20m sides 
local OFFSET_EAST_1 = 10
local OFFSET_NORTH_2 = 0
local OFFSET_EAST_2 = -20
local OFFSET_NORTH_3 = -5.77
local OFFSET_EAST_3= 10

local x_velocities = {
    [0] = 2,
    [1] = 0,
    [2] = -2,
}

local y_velocities = {
    [0] = 2,
    [1] = -2,
    [2] = 2,
}

local MIN_DISTANCE = 1; 

local offset_north
local offset_east
local altitude
local target_vel = Vector3f(); 

local offsetNorth = {
    [0]= OFFSET_NORTH_1,  
    [1]= OFFSET_NORTH_2, 
    [2]= OFFSET_NORTH_3, 
}

local offsetEast = {
    [0]= OFFSET_EAST_1,
    [1]= OFFSET_EAST_2,
    [2]= OFFSET_EAST_3,
}

function update() 
    if not arming:is_armed() or not vehicle:get_mode() ~= AUTO_MODE then --check logic 
        vehicle:set_mode(AUTO_MODE)
    end

    if arming:is_armed() and vehicle:get_mode() ~= AUTO_MODE then
        altitude = alt();  --this is different than defining alt in release script, should probably add additional if statements to set mode if not in auto mode
        if altitude > 15000 then --make sure altitude units are correct (cm???)
            target_vel:z(-2)
        end

        if altitude <= 15000 then 
            for i = 0,2 do 

                offset_north = offsetNorth[i] --sets offset value according to array index
                offset_east = offsetEast[i]
                target:offset(offset_north, offset_east) --offsets in distance (m)

                local current_location = ahrs.get_location(); --set home location to current point and calculate distance that way
                
                if current_location then
                
                    local distance = target:get_distance(current_location)
                    --distance should be updating continuously according to ahrs values
                    if distance > MIN_DISTANCE then 
                        target_vel:x(x_velocities[i]) 
                        target_vel:y(y_velocities[i]) 
                    end 
                end
            end

            vehicle:set_mode(COPTER_LAND_MODE_NUM) 

        end
    end
    return update, 1000
end

return update()