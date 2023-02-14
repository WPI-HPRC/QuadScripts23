--Calibration on the ground (in manual mode) 
--Once calibrated, switch into auto for whole flight 
    --Command motors to be off 
    --Log data as soon as auto mode is activated (individual test: Check data log on SD)  

--Detect liftoff, motor burnout, apogee, landing + print to sd card 
--When in descent, when at specified alt 
    --Detect switch from cameron -decide for alternative event assuming grond fails
    --Run release checks (check for mode but not imperative)
    --Detect second switch, MAKE SURE THERE IS A WAY FOR CAM TO KNOW WHEN TO FLIP THE SWITCH- use print statement
    --Log these changes 

local altitude 
local velocity 

function update()
    if not arming:is_armed() or not vehicle:get_mode() ~= AUTO_MODE then --check logic 
        vehicle:set_mode(AUTO_MODE)

    elseif arming:is_armed() and vehicle:get_mode() ~= AUTO_MODE then
        --if necessary log data here- test if we need a command to 
        --set motors off 
        altitude = alt()
        velocity = gps:velocity()


        --if statements that print stages based on data 
        --descent 
            --run release script 
    end
end 