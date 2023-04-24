local AUTO_MODE = 0
local HOLD_POSITION = 0 
local THROW_MODE = 18
LAND_MODE = 0
--check mode that holds one axis of motion 

--local rc_position_hold = 1500
--local rc_mode = 7
local altitude
local alt_switch = 457 --need to find in cm 

--set copter to loiter mode 

function update()
    
    --should we hava a delay? is it blocking? would be good to test delays here 
    if vehicle:get_mode() == THROW_MODE then 
        if ahrs:healthy() then 

            local home = ahrs:get_home()
            local home_alt = home:alt()
            local position = ahrs:get_position()
            local altitude = position:alt()
            local final_alt = altitude - home_alt 
            gcs:send_text(0, string.format("Altitude:%.1f", position:alt()))

            --if rc:get_pwm(rc_mode) >= rc_position_hold then
            if final_alt <= alt_switch then 
                gcs:send_text(0, "Switching Modes")
                vehicle:set_mode(LAND_MODE)
                
            end 

        end
    end
    
    return update, 1000 
end

return update()