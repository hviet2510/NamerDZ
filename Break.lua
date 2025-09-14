-- Auto Shake & Spin Script for Break Your Bones (Rayfield UI, Narrow Teleport Farm)
-- Tác giả: Grok (dựa trên cơ chế ragdoll Roblox)
-- Phiên bản: 2.8 - Tối ưu Krnl/mobile, Rayfield UI, lắc hỗn loạn, teleport vị trí hẹp để farm
-- Cách dùng: Execute trên Krnl (PC/mobile qua emulator). UI tự hiện, điều khiển bằng nút.

-- Load Rayfield UI Library
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
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

-- Biến trạng thái
local shakeEnabled = false
local spinEnabled = false
local narrowEnabled = false
local shakeConnection = nil
local spinConnection = nil
local narrowConnection = nil

-- Các bộ phận cần lắc
local bodyParts = {}

-- Vị trí hẹp để teleport (thay đổi nếu cần, ví dụ: giữa hai tường ở hub)
local narrowPosition = CFrame.new(0, 10, 0)  -- Ước lượng vị trí hẹp; chỉnh theo game

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
local teleportDelay = 5  -- Giây giữa các lần teleport

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
            math.rad(math.random(-shakeRotation * 100, shakeRotation * 100)),
            math.rad(math.random(-shakeRotation * 100, shakeRotation * 100))
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

-- Hàm teleport đến vị trí hẹp
local function teleportToNarrow()
    if not humanoidRootPart or not humanoidRootPart.Parent then return end
    pcall(function()
        humanoidRootPart.CFrame = narrowPosition
    end)
end

-- Loop teleport hẹp
local function startNarrowTeleport()
    if narrowEnabled or narrowConnection or not character then return end
    narrowEnabled = true
    narrowConnection = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then
            narrowEnabled = false
            if narrowConnection then narrowConnection:Disconnect() end
            return
        end
        teleportToNarrow()
        task.wait(teleportDelay)  -- Teleport định kỳ
    end)
end

local function stopNarrowTeleport()
    narrowEnabled = false
    if narrowConnection then
        narrowConnection:Disconnect()
        narrowConnection = nil
    end
end

-- Xử lý respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    updateBodyParts()
    task.wait(2)  -- Chờ load
    if shakeEnabled then startShake() end
    if spinEnabled then startSpin() end
    if narrowEnabled then 
        startNarrowTeleport() 
    end
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

-- Toggle Teleport Narrow
MainTab:CreateToggle({
    Name = "Auto Teleport Narrow Spot",
    CurrentValue = false,
    Flag = "NarrowTeleportToggle",
    Callback = function(state)
        if state then
            startNarrowTeleport()
            Rayfield:Notify({Title = "Narrow Teleport", Content = "Đã bật teleport vị trí hẹp để farm!", Duration = 3})
        else
            stopNarrowTeleport()
            Rayfield:Notify({Title = "Narrow Teleport", Content = "Đã tắt teleport vị trí hẹp!", Duration = 3})
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
    Name = "Teleport Delay",
    Range = {2, 10},
    Increment = 1,
    CurrentValue = 5,
    Flag = "TeleportDelaySlider",
    Callback = function(s)
        teleportDelay = s
        Rayfield:Notify({Title = "Teleport Delay", Content = "Delay teleport: " .. teleportDelay .. " giây", Duration = 3})
    end
})

-- Nút chỉnh vị trí hẹp (thủ công)
SettingsTab:CreateButton({
    Name = "Set Custom Narrow Position",
    Callback = function()
        -- Mở console để lấy tọa độ hiện tại
        Rayfield:Notify({Title = "Custom Position", Content = "Sử dụng F9 để xem tọa độ hiện tại và chỉnh narrowPosition trong script!", Duration = 5})
    end
})

-- Nút Destroy
SettingsTab:CreateButton({
    Name = "Destroy Script",
    Callback = function()
        stopShake()
        stopSpin()
        stopNarrowTeleport()
        Rayfield:Destroy()
        Rayfield:Notify({Title = "Script Stopped", Content = "Script đã dừng và UI bị xóa!", Duration = 5})
    end
})

-- Khởi động
Rayfield:Notify({Title = "Script Loaded", Content = "Break Your Bones - Narrow Farm Auto đã sẵn sàng! Bật Teleport Narrow để farm ở vị trí hẹp.", Duration = 5})
print("Break Your Bones - Narrow Farm Auto Script (Rayfield UI) loaded!")
