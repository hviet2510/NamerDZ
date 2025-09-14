-- Auto Shake & Spin Script for Break Your Bones (Krnl Optimized, Chaotic Shake)
-- Tác giả: Grok (dựa trên cơ chế ragdoll Roblox)
-- Phiên bản: 2.5 - Tối ưu Krnl, xử lý lỗi nil, lắc tay chân đầu hỗn loạn
-- Cách dùng: Execute trên Krnl (PC/mobile qua emulator). UI tự hiện, điều khiển bằng nút.

-- Load Orion Library với xử lý lỗi
local success, OrionLib = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source', true))()
end)
if not success then
    success, OrionLib = pcall(function()
        return loadstring(game:HttpGet('https://pastebin.com/raw/8r0h0T4Z', true))()
    end)
end
if not success or not OrionLib then
    warn("Không thể load Orion UI. Script sẽ dừng.")
    return
end

-- Tạo UI Window
local Window = OrionLib:MakeWindow({
    Name = "Break Your Bones - Chaos Auto",
    HidePremium = true,
    SaveConfig = false,
    IntroText = "Krnl Optimized - Chaotic Shake & Spin"
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
local shakeConnection = nil
local spinConnection = nil

-- Các bộ phận cần lắc
local bodyParts = {}

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

-- Xử lý respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    updateBodyParts()
    if shakeEnabled then startShake() end
    if spinEnabled then startSpin() end
end)

-- UI Setup
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local SettingsTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- Toggle Shake
MainTab:AddToggle({
    Name = "Auto Chaos Shake",
    Default = false,
    Callback = function(state)
        if state then
            startShake()
            OrionLib:MakeNotification({Name = "Chaos Shake", Content = "Đã bật lắc hỗn loạn!", Time = 3})
        else
            stopShake()
            OrionLib:MakeNotification({Name = "Chaos Shake", Content = "Đã tắt lắc hỗn loạn!", Time = 3})
        end
    end
})

-- Toggle Spin
MainTab:AddToggle({
    Name = "Auto Spin",
    Default = false,
    Callback = function(state)
        if state then
            startSpin()
            OrionLib:MakeNotification({Name = "Auto Spin", Content = "Đã bật xoay nhân vật!", Time = 3})
        else
            stopSpin()
            OrionLib:MakeNotification({Name = "Auto Spin", Content = "Đã tắt xoay nhân vật!", Time = 3})
        end
    end
})

-- Toggle UI
MainTab:AddButton({
    Name = "Toggle UI",
    Callback = function()
        OrionLib:Toggle()
        OrionLib:MakeNotification({Name = "UI", Content = "UI đã " .. (OrionLib:IsVisible() and "hiện" or "ẩn"), Time = 3})
    end
})

-- Sliders
SettingsTab:AddSlider({
    Name = "Shake Speed", Min = 8, Max = 50, Default = 12, Increment = 1, ValueName = " (cao hơn = chậm hơn)",
    Callback = function(s) shakeSpeed = s / 100; OrionLib:MakeNotification({Name = "Shake Speed", Content = "Tốc độ lắc: " .. shakeSpeed, Time = 3}) end
})
SettingsTab:AddSlider({
    Name = "Shake Intensity", Min = 20, Max = 100, Default = 100, Increment = 1, ValueName = " (cường độ lắc)",
    Callback = function(s) shakeIntensity = s / 100; OrionLib:MakeNotification({Name = "Shake Intensity", Content = "Cường độ lắc: " .. shakeIntensity, Time = 3}) end
})
SettingsTab:AddSlider({
    Name = "Shake Rotation", Min = 10, Max = 100, Default = 70, Increment = 1, ValueName = " (xoay hỗn loạn)",
    Callback = function(s) shakeRotation = s / 100; OrionLib:MakeNotification({Name = "Shake Rotation", Content = "Xoay hỗn loạn: " .. shakeRotation, Time = 3}) end
})
SettingsTab:AddSlider({
    Name = "Spin Speed", Min = 10, Max = 400, Default = 400, Increment = 1, ValueName = " (tốc độ xoay)",
    Callback = function(s) spinSpeed = s / 100; OrionLib:MakeNotification({Name = "Spin Speed", Content = "Tốc độ xoay: " .. spinSpeed, Time = 3}) end
})

-- Nút Destroy
SettingsTab:AddButton({
    Name = "Destroy Script",
    Callback = function()
        stopShake()
        stopSpin()
        OrionLib:Destroy()
        OrionLib:MakeNotification({Name = "Script Stopped", Content = "Script đã dừng và UI bị xóa!", Time = 5})
    end
})

-- Khởi động
OrionLib:MakeNotification({Name = "Script Loaded", Content = "Break Your Bones - Chaos Auto (Krnl) đã sẵn sàng!", Time = 5})
OrionLib:Init()
print("Break Your Bones - Chaos Auto Script (Krnl, Orion UI) loaded!")
