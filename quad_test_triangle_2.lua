-- Link to repo: https://github.com/ArduPilot/ardupilot/blob/master/libraries/AP_Scripting/examples/set-target-velocity.lua
--flies an obtuse triangle with 10m sides, descends and activates servo at each point before ascending to original alt

--Added basic servo functionality, not enough to actually drop cubes, but enough to test
--drops two cubes (maybe) 

local takeoff_alt_above_home = 6
local copter_guided_mode_num = 4
local copter_rtl_mode_num = 6
local POS_HOLD = 16
local LAND_MODE = 9
local stage = 0
local start_loc  -- vehicle location when starting square
local square_side_length = 20   -- length of each side of square

local SERVO1 = 94
local SERVO2 = 95
local servo_channel_upper = SRV_Channels:find_channel(SERVO1)
local servo_channel_lower = SRV_Channels:find_channel(SERVO2)

-- the main update function that uses the takeoff and velocity controllers to fly a rough square pattern
function update()
  if not arming:is_armed() then -- reset state when disarmed
    stage = 0
  else
    
      if (vehicle:get_mode() == POS_HOLD and stage == 0) then          -- change to guided mode
        if (vehicle:set_mode(copter_guided_mode_num)) then     -- change to Guided mode
          local curr_loc = ahrs:get_location()
          if curr_loc then
                start_loc = curr_loc          -- record location when starting square
              end
          stage = stage + 3
        end
      -- elseif (stage == 1) then      -- Stage1: takeoff
      --   if (vehicle:start_takeoff(takeoff_alt_above_home)) then
      --     stage = stage + 1
      --   end
      -- elseif (stage == 2) then      -- Stage2: check if vehicle has reached target altitude
      --   local home = ahrs:get_home()
      --   local curr_loc = ahrs:get_location()
      --   if home and curr_loc then
      --     local vec_from_home = home:get_distance_NED(curr_loc)
      --     gcs:send_text(0, "alt above home: " .. tostring(math.floor(-vec_from_home:z())))
      --     if (math.abs(takeoff_alt_above_home + vec_from_home:z()) < 1) then
      --       stage = stage + 1
      --       start_loc = curr_loc          -- record location when starting square
      --     end
      --   end
      elseif (stage >= 3 and stage <= 11) then   -- fly a triangle using velocity controller
        gcs:send_text(0, "Got here") 
        local curr_loc = ahrs:get_location()
        local target_vel = Vector3f()           -- create velocity vector
        if (start_loc and curr_loc) then
          local dist_NED = start_loc:get_distance_NED(curr_loc)--changed this to NED

          -- Stage3 : fly to first point (N) at 2m/s
          if (stage == 3) then
            gcs:send_text(0, "stage 3")
            target_vel:x(3)
            if (dist_NED:x() >= 8) then
              stage = stage + 1
            end
          end

          if (stage == 4)then
            gcs:send_text(0, "stage 4, descending")
            target_vel:z(3)
            if (dist_NED:z() >= 2) then --if this doesn't work then we may be in cm (kill me), also check orientation as well, may need to be negative
              SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drops when PWM is high
              gcs:send_text(0, "Servo stuff here")
              stage = stage + 1
            end
          end

          if (stage == 5)then
            gcs:send_text(0, "stage 5, ascending")
            target_vel:z(-3)
            if (dist_NED:z() <= 1) then
              SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 500) --reset lower servo quickly
               SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000) --drop upper cube
              stage = stage + 1
            end
          end

          -- Stage4 : fly SE at 2m/s
          if (stage == 6) then
            gcs:send_text(0, "stage 6")
            target_vel:x(-3)
            target_vel:y(3) 
            if (dist_NED:y() >= 6 and dist_NED:x() <= 1 ) then
              stage = stage + 1
            end
          end

          if (stage == 7)then
            gcs:send_text(0, "stage 7, descending")
            target_vel:z(3)
            if (dist_NED:z() >= 2) then
              SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drop second cube 
              gcs:send_text(0, "Servo stuff here")
              stage = stage + 1
            end
          end

          if (stage == 8)then
            gcs:send_text(0, "stage 8, ascending")
            target_vel:z(-3)
            if (dist_NED:z() <= 1) then
              -- SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1500, 1000) --need to figure out servo timing and stuff for third cube
              stage = stage + 1
            end
          end

          -- Stage5 : fly SW at 2m/s
          if (stage == 9) then
            gcs:send_text(0, "stage 9")
            --target_vel:x(-1) --changed this 
            target_vel:y(-3)
            if (dist_NED:y() <= 1) then
              stage = stage + 1
            end
          end

          if (stage == 10)then
            gcs:send_text(0, "stage 10, descending")
            target_vel:z(3)
            if (dist_NED:z() >= 2) then
              --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 1000)
              gcs:send_text(0, "Servo stuff here")
              stage = stage + 1
            end
          end

          if (stage == 11)then
            gcs:send_text(0, "stage 11, ascending")
            target_vel:z(-3)
            if (dist_NED:z() <= 1) then
              -- SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1500, 1000)
              stage = stage + 1
            end
          end

          -- send velocity request
          if (vehicle:set_target_velocity_NED(target_vel)) then   -- send target velocity to vehicle
            gcs:send_text(0, "pos:" .. tostring(math.floor(dist_NED:x())) .. "," .. tostring(math.floor(dist_NED:y())) .. " sent vel x:" .. tostring(target_vel:x()) .. " y:" .. tostring(target_vel:y()))
          else
            gcs:send_text(0, "failed to execute velocity command")
          end
        else
          gcs:send_text(0, "position failed")
        end

      elseif (stage == 12) then  -- Stage7: change to RTL mode
        vehicle:set_mode(LAND_MODE)
        stage = stage + 1
        gcs:send_text(0, "finished square, switching to RTL")
      end
    
  end

  return update, 1000
end

return update()