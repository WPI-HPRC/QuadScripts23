local roll
local pitch
local yaw
local rates

local roll_rate
local pitch_rate
local yaw_rate

function update()

    roll = math.deg(ahrs:get_roll())
    pitch = math.deg(ahrs:get_pitch())
    yaw = math.deg(ahrs:get_yaw())
    rates = ahrs:get_gyro()

    if rates then
      roll_rate = math.deg(rates:x())
      pitch_rate = math.deg(rates:y())
      yaw_rate = math.deg(rates:z())

    else
      roll_rate = 0
      pitch_rate = 0
      yaw_rate = 0
    end

    gcs:send_text(0, string.format("Ang R:%.1f P:%.1f Y:%.1f Rate R:%.1f P:%.1f Y:%.1f", roll, pitch, yaw, roll_rate, pitch_rate, yaw_rate))

    if (roll > math.abs(90)) then
        gcs:send_text(0, "I am upside down")
    end

    return update, 1000 
end
return update()