local AUTO_MODE = 0
local HOLD_POSITION = 0 
--check mode that holds one axis of motion 

--local rc_position_hold = 1500
--local rc_mode = 7
local altitude
local alt_switch = 20

--set copter to loiter mode 

function update()
     --if not arming:is_armed() or not vehicle:get_mode() ~= loiter then 
       -- vehicle:set_mode(copter_loiter_num)
    --end

    altitude = alt() 
    gcs:send_text(0, string.format("Altitude", altitude))

    --if rc:get_pwm(rc_mode) >= rc_position_hold then
    if altitude <= alt_switch then 
        gcs:send_text(0, "Switching Modes")
        vehicle:set_mode(copter_land_mode_num)
        
    end 
    
    return update, 1000 
end

return update()