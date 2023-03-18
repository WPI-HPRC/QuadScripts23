local velocity = Vector3f()
--local location

function update()
    velocity = ahrs:get_velocity_NED()
    --local alt1 = baro:get_altitude()

    if ahrs:healthy() then --make sure a home is set 
        local position = ahrs:get_position()
        local altitude = position:alt()
        --local position = ahrs:get_relative_position_NED_home()
        --local altitude = -1*position:z()
        gcs:send_text(5, string.format("Altitude: %.1f", altitude))
    end
    

    if velocity then 
        gcs:send_text(0, string.format("Velocity- N:%.1f E:%.1f D:%.1f", velocity:x(), velocity:y(), velocity:z()))
    end
   
    --if location then
        --gcs:sent_text(0, string.format("Lat: %.1f Lng:%.1f ", location:lat(), location:lng()))
    --end
    return update, 1000
end

return update()