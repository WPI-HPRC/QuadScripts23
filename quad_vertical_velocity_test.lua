local velocity = Vector3f()
local altitude = Location()

function update()
    velocity = ahrs:get_velocity_NED()

    if velocity then 
        gcs:send_text(0, string.format("Velocity- N:%.1f E:%.1f D:%.1f", velocity:x(), velocity:y(), velocity:z()))
    end
    if altitude then
        gcs:sent_text(0, string.format("Altitude: %.1f", altitude:alt()))
    end
    return update, 1000
end

return update()