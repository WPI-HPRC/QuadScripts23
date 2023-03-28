--fly triangle autonoumously-- adjust altitude values depending on how payload wants to test
--after this mode passes, test throw mode 
--does not test with altitide change 

local AUTO_MODE = 3 --need to set values
local LAND_MODE = 0
local POS_HOLD = 16
local GUIDED_MODE = 4

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

local MIN_DISTANCE = 1

local offset_north
local offset_east
local position 
local altitude 
local home_alt
local home 
local state = 0
local tri_state = 0
local target_alt = 7
local start_location



local target_vel = Vector3f()

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
    

    if not arming:is_armed() then
        state = 0
    else
        if vehicle:get_mode(POS_HOLD) then
                    -- change to guided mode
            if (vehicle:set_mode(GUIDED_MODE)) then     -- change to Guided mode
                state = state + 1
            end
        elseif (state == 1) then
            local home = ahrs:get_home()
            local curr_loc = ahrs:get_location()
            local target_vel = Vector3f()  
            if home and curr_loc then
              local vec_from_home = home:get_distance_NED(curr_loc)
              gcs:send_text(0, "alt above home: " .. tostring(math.floor(-vec_from_home:z())))
            
                if (target_alt + vec_from_home:z()) > 1 then
                    target_vel:z(2)
                elseif (target_alt + vec_from_home:z()) < -1 then
                    target_vel:z(-2)
                elseif (math.abs(target_alt + vec_from_home:z()) < 1) then
                    state = state + 1
                    --start_location = curr_loc          -- record location when starting square
                end
            end
        elseif (state == 2) then    

            for i = 0,2 do 

                local current_location = ahrs.get_location()
                local target_vel = Vector3f()
                local target = Location()
                if(tri_state == 0) then
                    offset_north = offsetNorth[i] --sets offset value according to array index
                    offset_east = offsetEast[i]
                    target = current_location
                    target:offset(offset_north, offset_east) --offsets in distance (m)
                    tri_state = tri_state + 1

                elseif tri_state == 1 then
                    if current_location then
                        local distance = current_location:get_distance_NE(target)
                        --distance should be updating continuously according to ahrs values
                        if distance:x() > MIN_DISTANCE and distance:y() > MIN_DISTANCE then 
                            target_vel:x(x_velocities[i]) 
                            target_vel:y(y_velocities[i]) 

                        else
                            tri_state = 0
                        end 

                    end
                end

                if (vehicle:set_target_velocity_NED(target_vel)) then   -- send target velocity to vehicle
                    gcs:send_text(0, "pos:" .. tostring(math.floor(dist_NE:x())) .. "," .. tostring(math.floor(dist_NE:y())) .. " sent vel x:" .. tostring(target_vel:x()) .. " y:" .. tostring(target_vel:y()))
                else
                    gcs:send_text(0, "failed to execute velocity command")
                end

            end
        
            if i == 2 then
                state = state + 1
            end
        
        
        elseif (state == 3) then
            vehicle:set_mode(LAND_MODE) 
            state = state + 1
        end

    end
    return update, 1000
end

return update()