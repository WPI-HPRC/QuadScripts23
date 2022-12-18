local altitude
local CUBE_SERVO_CHANNEL = 0 --need to set values
local CUBE_SERVO_ON_PWM = 0
local CUBE_SERVO_ON_TIMEOUT = 0
local OFFSET_NORTH_1 = 0 
local OFFSET_EAST_1 = 0
local OFFSET_NORTH_2 = 0
local OFFSET_EAST_2 = 0
local OFFSET_NORTH_3 = 0 
local OFFSET_EAST_3= 0 
local OFFSET_NORTH_4= 0
local OFFSET_EAST_4= 0
local SIDE_LENGTH = 3; 
MIN_DISTANCE = 1; 

local AUTO_MODE = 0 --need to set values
local COPTER_LAND_MODE_NUM = 0
local offset_north
local offset_east

local offset = {
    [0]= OFFSET_NORTH_1,  
    [1]= OFFSET_EAST_1,
    [2]= OFFSET_NORTH_2, 
    [3]= OFFSET_EAST_2,
    [4]= OFFSET_NORTH_3, 
    [5]= OFFSET_EAST_3,
    [6]= OFFSET_NORTH_4,
    [7]= OFFSET_EAST_4
}

function update() --may be better to create several different functions/state machine rather than have everything under the update function; more research required
    if not arming:is_armed() or not vehicle:get_mode() ~= AUTO_MODE then --check logic 
        vehicle:set_mode(AUTO_MODE)
    end
    if arming:is_armed() and vehicle:get_mode() ~= AUTO_MODE then
        altitude = alt();  --should probably add if statements to set mode if not in auto mode, again may be better to reformat into state machine 
        if altitude > 150 then 
            target_vel:z(2)
        end

        if altitude <= 150 then --make sure altitude units are correct (cm???)
            for i = 0,3 do 
                set_output_pwm_chan_timeout(CUBE_SERVO_CHANNEL, CUBE_SERVO_ON_PWM, CUBE_SERVO_ON_TIMEOUT) --set servo to drop cube 1, after time does servo set to original value? 
                local current_location = ahrs.get_location(); 
                local k = 2*i
                for k, value in pairs(offset) do --logic needs to be adjusted to iterate through first two items only
                    offset_north = value
                    offset_east = value + 1 --check logic
                end
                target:offset(offset_north, offset_east) --remember to define target and distance
                --move to target
                local distance = target:get_distance(target)
                --distance should be updating continuously according to ahrs values
                if distance > MIN_DISTANCE then 
                    target_vel:x(2) -- need to make velocity vector?
                    target_vel:y(2) --these velocities may need to change depending on the quad's orientation
                    --add lines to continuously update distance traveled? 
                end 
            end

            vehicle:set_mode(COPTER_LAND_MODE_NUM) --might need to add something before this, probably need to define target 

        end
    end
end

return update, 1000