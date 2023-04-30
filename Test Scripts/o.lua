--This test runs the cube mission through target offsets rather than velocity control--

local takeoff_alt_above_home = 6
local copter_guided_mode_num = 4
local copter_rtl_mode_num = 6
local POS_HOLD = 16
local LAND_MODE = 9
local stage = 0
local start_loc  -- vehicle location when starting square

local SERVO1 = 94
local SERVO2 = 95
local servo_channel_upper = SRV_Channels:find_channel(SERVO1)
local servo_channel_lower = SRV_Channels:find_channel(SERVO2)

function update()
    if not arming:is_armed() then
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
          
          elseif (stage >= 3 and stage <= 11) then  
            --gcs:send_text(0, "Got here") 
            local curr_loc = ahrs:get_location()
        
            if (start_loc and curr_loc) then

              local tri_target1 = start_loc
              tri_target1:offset(10, 0)

              local tri_target2 = start_loc
              tri_target2:offset(5, 8.6)

              local tri_target3 = start_loc

              --local dist_NED = start_loc:get_distance_NED(curr_loc)--changed this to NED
    
              -- Stage3 : fly to first point (N) at 2m/s
              if (stage == 3) then
                if(vehicle:set_target_location(tri_target1)) then
                    stage = stage + 1 
                  end
              end

              if (stage == 4) then
                  --gcs:send_text(0, "stage 3")
                  local dist_NED = curr_loc:get_distance_NED(tri_target1)
                  if (dist_NED:x() < 1) then
                    stage = stage + 1
                    gcs:send_text(0, "switching to descending")
                  end
              end
    
              if (stage == 5)then
                tri_target1:alt(tri_target1:alt() - 200) --check units 
                gcs:send_text(0, "stage 4, descending")
                if(vehicle:set_target_location(tri_target1)) then
                  stage = stage + 1 
                end
              end

              if (stage == 6) then
                local dist_NED = curr_loc:get_distance_NED(tri_target1)
                if (dist_NED:z() < 1) then --if this doesn't work then we may be in cm (kill me), also check orientation as well, may need to be negative
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drops when PWM is high
                  gcs:send_text(0, "Cube 1 Dropped")
                  stage = stage + 1
                end
              end
    
              if (stage == 7)then
                --gcs:send_text(0, "stage 5, ascending")
                tri_target1:alt(tri_target1:alt() + 200)
                if(vehicle:set_target_location(tri_target1)) then
                  stage = stage + 1 
                end
              end

              if (stage == 8) then
                local dist_NED = curr_loc:get_distance_NED(tri_target1)
                if (dist_NED:z() < 1) then
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 500) --reset lower servo quickly
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000) --drop upper cube
                  stage = stage + 1
                 end
              end
    
              -- Stage4 : fly SE at 2m/s
              if (stage == 9) then
                if(vehicle:set_target_location(tri_target2)) then
                    stage = stage + 1
                end
              end

              if (stage == 10) then
                  local dist_NED = curr_loc:get_distance_NED(tri_target2)
                  if (dist_NED:x() < 1 and dist_NED:y() < 1) then
                    SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1100, 1000)
                    stage = stage + 3
                  end
              end
    
              if (stage == 11) then
                --gcs:send_text(0, "stage 7, descending")
                tri_target2:alt(tri_target2:alt() - 200)
                if(vehicle:set_target_location(tri_target2)) then
                  stage = stage + 1 
                end
              end

              if (stage == 12) then
                local dist_NED = curr_loc:get_distance_NED(tri_target2)
                if (dist_NED:z() < 1) then
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1100, 1000) --drop second cube 
                  gcs:send_text(0, "Cube 2 Dropped")
                  stage = stage + 1
                end
              end
    
              if (stage == 13)then
                --gcs:send_text(0, "stage 8, ascending")
                tri_target2:alt(tri_target2:alt() + 200)
                if(vehicle:set_target_location(tri_target2)) then
                  stage = stage + 1 
                end
              end

              if (stage == 14) then
                local dist_NED = curr_loc:get_distance_NED(tri_target2)
                if (dist_NED:z() < 1) then
                  -- SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1500, 1000) --need to figure out servo timing and stuff for third cube
                  stage = stage + 1
                end
              end
    
              -- Stage5 : fly W at 2m/s
              if (stage == 15) then
                if(vehicle:set_target_location(tri_target3)) then
                    stage = stage + 1
                end
              end

              if (stage == 16) then
                local dist_NED = curr_loc:get_distance_NED(tri_target3)
                  if (dist_NED:x() < 1 and dist_NED:y() < 1) then
                    stage = stage + 3
                  end
              end
    
              if (stage == 17)then
                --gcs:send_text(0, "stage 10, descending")
                tri_target3:alt(tri_target3:alt() - 200)
                if(vehicle:set_target_location(tri_target3)) then
                  stage = stage + 1 
                end
              end

              if (stage == 18) then 
                local dist_NED = curr_loc:get_distance_NED(tri_target3)
                if (dist_NED:z() < 1) then
                  --SRV_Channels:set_output_pwm_chan_timeout(servo_channel_lower, 1900, 1000)
                  gcs:send_text(0, "Cube 3 Dropped")
                  SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1900, 1000)
                  stage = stage + 1
                end
              end
    
              if (stage == 19)then
                --gcs:send_text(0, "stage 11, ascending")
                tri_target3:alt(tri_target3:alt() + 200)
                if(vehicle:set_target_location(tri_target3)) then
                  stage = stage + 1 
                end
              end

              if (stage == 20) then
                local dist_NED = curr_loc:get_distance_NED(tri_target3)
                if (dist_NED:z() < 1) then
                  -- SRV_Channels:set_output_pwm_chan_timeout(servo_channel_upper, 1500, 1000)
                  stage = stage + 1
                end
              end
    
          elseif (stage == 21) then  -- Stage7: change to RTL mode
            vehicle:set_mode(LAND_MODE)
            stage = stage + 1
            gcs:send_text(0, "finished square, switching to RTL")
          end
    end
  end


    return update, 1000
end

return update()