
local AUTO_MODE = 3

function update()
    if not arming:is_armed() then 
        arming:arm()
        vehicle:set_mode(AUTO_MODE)
    end
    return update, 1000
end
return update()