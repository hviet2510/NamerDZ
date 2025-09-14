-- Auto Shake & Spin Script for Break Your Bones (Rayfield UI, Narrow Velocity Move Farm)
-- Tác giả: Grok (dựa trên cơ chế ragdoll Roblox)
-- Phiên bản: 3.13 - Tối ưu Krnl/mobile, Rayfield UI link mới, velocity di chuyển lặp với delay đến X=-59.41, Y=864.09, Z=-3069.94, fix lỗi velocity với ragdoll khác
-- Cách dùng: Execute trên Krnl (PC/mobile qua emulator). UI tự hiện, điều khiển bằng nút.

-- Load Rayfield UI Library với link mới
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()
local Window = Rayfield:CreateWindow({
    Name = "Break Your Bones - Narrow Farm Auto",
    LoadingTitle = "Rayfield UI",
    LoadingSubtitle = "by Grok",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "Rayfield Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 10)
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

-- Biến trạng thái
local shakeEnabled = false
local spinEnabled = false
local narrowEnabled = false
local shakeConnection = nil
local spinConnection = nil
local narrowConnection = nil
local velocityConnection = nil
local ragdollState = false  -- Theo dõi trạng thái ragdoll

-- Các bộ phận cần lắc
local bodyParts = {}

-- Vị trí hẹp để di chuyển bằng velocity
local targetPosition = Vector3.new(-59.41, 864.09, -3069.94)  -- Tọa độ mới
local moveSpeed = 50  -- Tốc độ di chuyển (tùy chỉnh qua slider)
local moveDelay = 5   -- Delay giữa các lần di chuyển (tùy chỉnh qua slider)
local velocityForce = Instance.new("BodyVelocity")

-- Hàm cập nhật bodyParts an toàn
local function updateBodyParts()
    bodyParts = {}
    if not character then return end
    pcall(function()
        bodyParts = {
            character:WaitForChild("Head", 5),
            character:WaitForChild("Left Arm", 5),
            character:WaitForChild("Right Arm", 5),
            character:WaitForChild("Left Leg", 5),
            character:WaitForChild("Right Leg", 5)
        }
    end)
end

-- Cài đặt ban đầu
updateBodyParts()

-- Cấu hình
local shakeSpeed = 0.12
local shakeIntensity = 1.0
local shakeRotation = 0.7
local spinSpeed = 4

-- Hàm lắc hỗn loạn
local function shakePart(part)
    if not part or not part.Parent then return end
    pcall(function()
        local originalCFrame = part.CFrame
        local randomOffset = Vector3.new(
            math.random(-shakeIntensity, shakeIntensity),
            math.random(-shakeIntensity, shakeIntensity),
            math.random(-shakeIntensity, shakeIntensity)
        )
        local randomRotation = CFrame.Angles(
            math.rad(math.random(-shakeRotation * 100, shakeRotation * 100)),
            math.random(-shakeRotation * 100, shakeRotation * 100),
            math.random(-shakeRotation * 100, shakeRotation * 100)
        )
        local goalCFrame = originalCFrame * CFrame.new(randomOffset) * randomRotation
        local tweenInfo = TweenInfo.new(shakeSpeed / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(part, tweenInfo, {CFrame = goalCFrame})
        tween:Play()
    end)
end

-- Hàm xoay nhân vật
local function spinCharacter()
    if not humanoidRootPart or not humanoidRootPart.Parent then return end
    pcall(function()
        local spinAngle = CFrame.Angles(0, spinSpeed * tick(), 0)
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * spinAngle
    end)
end

-- Loop lắc
local function startShake()
    if shakeEnabled or shakeConnection or not character then return end
    shakeEnabled = true
    shakeConnection = RunService.RenderStepped:Connect(function()
        if not character or not character.Parent then
            shakeEnabled = false
            if shakeConnection then shakeConnection:Disconnect() end
            return
        end
        for _, part in ipairs(bodyParts) do
            shakePart(part)
        end
        task.wait(shakeSpeed)
    end)
end

local function stopShake()
    shakeEnabled = false
    if shakeConnection then
        shakeConnection:Disconnect()
        shakeConnection = nil
    end
end

-- Loop xoay
local function startSpin()
    if spinEnabled or spinConnection or not humanoidRootPart then return end
    spinEnabled = true
    spinConnection = RunService.RenderStepped:Connect(function()
        if not character or not character.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
            spinEnabled = false
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        spinCharacter()
        task.wait(0.06)
    end)
end

local function stopSpin()
    spinEnabled = false
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
end

-- Hàm di chuyển bằng velocity với xử lý ragdoll
local function moveWithVelocity()
    if not humanoid or not humanoidRootPart or not humanoidRootPart.Parent or ragdollState then return end
    pcall(function()
        -- Khôi phục trạng thái ragdoll trước khi di chuyển
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        task.wait(0.2)  -- Delay để ổn định

        -- Tạo và áp dụng BodyVelocity
        velocityForce.Parent = humanoidRootPart
        velocityForce.Velocity = (targetPosition - humanoidRootPart.Position).Unit * moveSpeed
        velocityForce.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

        -- Kiểm tra khoảng cách và dừng khi đến gần
        velocityConnection = RunService.RenderStepped:Connect(function()
            if not narrowEnabled or not humanoidRootPart.Parent or ragdollState then
                velocityForce:Destroy()
                if velocityConnection then
                    velocityConnection:Disconnect()
                    velocityConnection = nil
                end
                return
            end
            local distance = (humanoidRootPart.Position - targetPosition).Magnitude
            if distance < 5 then  -- Khi cách đích dưới 5 studs, dừng lần này
                velocityForce:Destroy()
                if velocityConnection then
                    velocityConnection:Disconnect()
                    velocityConnection = nil
                end
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                updateBodyParts()
                if #bodyParts < 5 then
                    Rayfield:Notify({Title = "Cảnh báo Ragdoll", Content = "Phát hiện mất bộ phận, đang khôi phục!", Duration = 3})
                    character:BreakJoints()
                    task.wait(0.5)
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    updateBodyParts()
                end
            end
        end)
    end)
end

-- Loop di chuyển bằng velocity với delay
local function startNarrowMove()
    if narrowEnabled or not character then return end
    narrowEnabled = true
    narrowConnection = RunService.Heartbeat:Connect(function()
        if not narrowEnabled or not character or not character.Parent then
            if narrowConnection then
                narrowConnection:Disconnect()
                narrowConnection = nil
            end
            return
        end
        moveWithVelocity()  -- Di chuyển một lần, lặp với delay
        task.wait(moveDelay)  -- Delay giữa các lần di chuyển
    end)
end

local function stopNarrowMove()
    narrowEnabled = false
    if narrowConnection then
        narrowConnection:Disconnect()
        narrowConnection = nil
    end
    if velocityConnection then
        velocityConnection:Disconnect()
        velocityConnection = nil
    end
    if velocityForce and velocityForce.Parent then
        velocityForce:Destroy()
    end
    if humanoid then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    Rayfield:Notify({Title = "Velocity Move", Content = "Đã dừng di chuyển hoàn toàn!", Duration = 3})
end

-- Theo dõi trạng thái ragdoll
local function setupRagdollListener()
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Ragdoll then
            ragdollState = true
            if velocityForce and velocityForce.Parent then
                velocityForce:Destroy()
            end
            if velocityConnection then
                velocityConnection:Disconnect()
                velocityConnection = nil
            end
            Rayfield:Notify({Title = "Ragdoll Detected", Content = "Ragdoll kích hoạt, tạm dừng velocity!", Duration = 3})
        elseif newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.GettingUp then
            ragdollState = false
            if narrowEnabled and not velocityConnection then
                moveWithVelocity()  -- Khôi phục di chuyển khi thoát ragdoll
            end
        end
    end)
end

-- Xử lý respawn (tiếp tục lặp lại khi hoàn thành ván)
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid", 10)
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    updateBodyParts()
    task.wait(2)  -- Chờ load
    setupRagdollListener()  -- Thiết lập listener ragdoll
    if narrowEnabled then
        startNarrowMove()  -- Tiếp tục lặp lại khi respawn
    end
    if shakeEnabled then startShake() end
    if spinEnabled then startSpin() end
end)

-- UI Setup với Rayfield
local MainTab = Window:CreateTab("Main", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Toggle Shake
MainTab:CreateToggle({
    Name = "Auto Chaos Shake",
    CurrentValue = false,
    Flag = "ChaosShakeToggle",
    Callback = function(state)
        if state then
            startShake()
            Rayfield:Notify({Title = "Chaos Shake", Content = "Đã bật lắc hỗn loạn!", Duration = 3})
        else
            stopShake()
            Rayfield:Notify({Title = "Chaos Shake", Content = "Đã tắt lắc hỗn loạn!", Duration = 3})
        end
    end
})

-- Toggle Spin
MainTab:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Flag = "SpinToggle",
    Callback = function(state)
        if state then
            startSpin()
            Rayfield:Notify({Title = "Auto Spin", Content = "Đã bật xoay nhân vật!", Duration = 3})
        else
            stopSpin()
            Rayfield:Notify({Title = "Auto Spin", Content = "Đã tắt xoay nhân vật!", Duration = 3})
        end
    end
})

-- Toggle Velocity Move Narrow (lặp với delay)
MainTab:CreateToggle({
    Name = "Auto Velocity Move Narrow Spot",
    CurrentValue = false,
    Flag = "NarrowMoveToggle",
    Callback = function(state)
        if state then
            startNarrowMove()
            Rayfield:Notify({Title = "Velocity Move", Content = "Đã bật di chuyển lặp lại đến X=-59.41, Y=864.09, Z=-3069.94!", Duration = 3})
        else
            stopNarrowMove()
            Rayfield:Notify({Title = "Velocity Move", Content = "Đã tắt di chuyển vị trí hẹp!", Duration = 3})
        end
    end
})

-- Toggle UI
MainTab:CreateButton({
    Name = "Toggle UI",
    Callback = function()
        Window:Toggle()
        Rayfield:Notify({Title = "UI", Content = "UI đã " .. (Window:IsVisible() and "hiện" or "ẩn"), Duration = 3})
    end
})

-- Sliders
SettingsTab:CreateSlider({
    Name = "Shake Speed",
    Range = {8, 50},
    Increment = 1,
    CurrentValue = 12,
    Flag = "ShakeSpeedSlider",
    Callback = function(s)
        shakeSpeed = s / 100
        Rayfield:Notify({Title = "Shake Speed", Content = "Tốc độ lắc: " .. shakeSpeed, Duration = 3})
    end
})

SettingsTab:CreateSlider({
    Name = "Shake Intensity",
    Range = {20, 100},
    Increment = 1,
    CurrentValue = 100,
    Flag = "ShakeIntensitySlider",
    Callback = function(s)
        shakeIntensity = s / 100
        Rayfield:Notify({Title = "Shake Intensity", Content = "Cường độ lắc: " .. shakeIntensity, Duration = 3})
    end
})

SettingsTab:CreateSlider({
    Name = "Shake Rotation",
    Range = {10, 100},
    Increment = 1,
    CurrentValue = 70,
    Flag = "ShakeRotationSlider",
    Callback = function(s)
        shakeRotation = s / 100
        Rayfield:Notify({Title = "Shake Rotation", Content = "Xoay hỗn loạn: " .. shakeRotation, Duration = 3})
    end
})

SettingsTab:CreateSlider({
    Name = "Spin Speed",
    Range = {10, 400},
    Increment = 1,
    CurrentValue = 400,
    Flag = "SpinSpeedSlider",
    Callback = function(s)
        spinSpeed = s / 100
        Rayfield:Notify({Title = "Spin Speed", Content = "Tốc độ xoay: " .. spinSpeed, Duration = 3})
    end
})

SettingsTab:CreateSlider({
    Name = "Move Speed",
    Range = {10, 100},
    Increment = 1,
    CurrentValue = 50,
    Flag = "MoveSpeedSlider",
    Callback = function(s)
        moveSpeed = s
        Rayfield:Notify({Title = "Move Speed", Content = "Tốc độ di chuyển: " .. moveSpeed, Duration = 3})
    end
})

SettingsTab:CreateSlider({
    Name = "Move Delay",
    Range = {2, 10},
    Increment = 1,
    CurrentValue = 5,
    Flag = "MoveDelaySlider",
    Callback = function(s)
        moveDelay = s
        Rayfield:Notify({Title = "Move Delay", Content = "Delay di chuyển: " .. moveDelay .. " giây", Duration = 3})
    end
})

-- Input cho tọa độ tùy chỉnh
SettingsTab:CreateInput({
    Name = "Set Custom X Coordinate",
    PlaceholderText = "Nhập X (ví dụ: -59.41)",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local x = tonumber(text)
        if x then
            targetPosition = Vector3.new(x, targetPosition.Y, targetPosition.Z)
            Rayfield:Notify({Title = "Custom X", Content = "Đã đặt X=" .. x, Duration = 3})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "X phải là số!", Duration = 3})
        end
    end
})

SettingsTab:CreateInput({
    Name = "Set Custom Y Coordinate",
    PlaceholderText = "Nhập Y (ví dụ: 864.09)",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local y = tonumber(text)
        if y then
            targetPosition = Vector3.new(targetPosition.X, y, targetPosition.Z)
            Rayfield:Notify({Title = "Custom Y", Content = "Đã đặt Y=" .. y, Duration = 3})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "Y phải là số!", Duration = 3})
        end
    end
})

SettingsTab:CreateInput({
    Name = "Set Custom Z Coordinate",
    PlaceholderText = "Nhập Z (ví dụ: -3069.94)",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local z = tonumber(text)
        if z then
            targetPosition = Vector3.new(targetPosition.X, targetPosition.Y, z)
            Rayfield:Notify({Title = "Custom Z", Content = "Đã đặt Z=" .. z, Duration = 3})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "Z phải là số!", Duration = 3})
        end
    end
})

-- Nút Save Position
SettingsTab:CreateButton({
    Name = "Save Position",
    Callback = function()
        if humanoidRootPart and humanoidRootPart.Parent then
            local pos = humanoidRootPart.Position
            targetPosition = pos
            print("Tọa độ đã lưu: X=" .. string.format("%.2f", pos.X) .. ", Y=" .. string.format("%.2f", pos.Y) .. ", Z=" .. string.format("%.2f", pos.Z))
            Rayfield:Notify({Title = "Save Position", Content = "Đã lưu tọa độ hiện tại: X=" .. string.format("%.2f", pos.X) .. ", Y=" .. string.format("%.2f", pos.Y) .. ", Z=" .. string.format("%.2f", pos.Z), Duration = 5})
        else
            Rayfield:Notify({Title = "Lỗi", Content = "Không thể lưu tọa độ, nhân vật chưa load!", Duration = 3})
        end
    end
})

-- Nút Destroy
SettingsTab:CreateButton({
    Name = "Destroy Script",
    Callback = function()
        stopShake()
        stopSpin()
        stopNarrowMove()
        Rayfield:Destroy()
        Rayfield:Notify({Title = "Script Stopped", Content = "Script đã dừng và UI bị xóa!", Duration = 5})
    end
})

-- Khởi động
Rayfield:Notify({Title = "Script Loaded", Content = "Break Your Bones - Narrow Farm Auto đã sẵn sàng! Di chuyển lặp lại đến X=-59.41, Y=864.09, Z=-3069.94, fix lỗi velocity với ragdoll khác.", Duration = 5})
print("Break Your Bones - Narrow Farm Auto Script (Rayfield UI v3.13) loaded!")
