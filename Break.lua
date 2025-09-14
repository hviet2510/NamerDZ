-- Auto Shake & Spin Script for Break Your Bones (Mobile Optimized)
-- Tác giả: Grok (dựa trên cơ chế ragdoll Roblox)
-- Phiên bản: 2.1 - Tối ưu cho mobile, Kavo UI cảm ứng, hiệu suất cao
-- Cách dùng: Execute trên executor mobile (Fluxus, Delta, v.v.). UI tự hiện, điều khiển bằng nút cảm ứng.

-- Load Kavo UI Library (tối ưu cho mobile)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Break Your Bones - Mobile Auto", "DarkTheme")

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
local uiVisible = true
local shakeConnection = nil
local spinConnection = nil

-- Các bộ phận cần lắc
local bodyParts = {}

-- Hàm cập nhật bodyParts an toàn
local function updateBodyParts()
    bodyParts = {}
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

-- Cấu hình (tối ưu cho mobile)
local shakeSpeed = 0.15  -- Tăng nhẹ để giảm lag trên mobile
local shakeIntensity = 0.4  -- Giảm cường độ để mượt hơn
local spinSpeed = 4  -- Tốc độ xoay nhẹ hơn cho mobile

-- Hàm lắc một bộ phận (an toàn với pcall)
local function shakePart(part)
    if not part or not part.Parent then return end
    pcall(function()
        local originalCFrame = part.CFrame
        local randomOffset = Vector3.new(
            math.random(-shakeIntensity, shakeIntensity),
            math.random(-shakeIntensity, shakeIntensity),
            math.random(-shakeIntensity, shakeIntensity)
        )
        part.CFrame = originalCFrame * CFrame.new(randomOffset)
    end)
end

-- Hàm xoay nhân vật (an toàn)
local function spinCharacter()
    if not humanoidRootPart or not humanoidRootPart.Parent then return end
    pcall(function()
        local spinAngle = CFrame.Angles(0, spinSpeed * tick(), 0)  -- Xoay quanh trục Y
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * spinAngle
    end)
end

-- Loop lắc (riêng biệt)
local function startShake()
    if shakeEnabled or shakeConnection then return end
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

-- Loop xoay (riêng biệt)
local function startSpin()
    if spinEnabled or spinConnection then return end
    spinEnabled = true
    spinConnection = RunService.RenderStepped:Connect(function()
        if not character or not character.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
            spinEnabled = false
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        spinCharacter()
        task.wait(0.06)  -- Delay nhẹ cho mobile
    end)
end

local function stopSpin()
    spinEnabled = false
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
end

-- Xử lý respawn an toàn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
    updateBodyParts()
    if shakeEnabled then startShake() end
    if spinEnabled then startSpin() end
end)

-- UI Setup với Kavo Library (tối ưu cảm ứng)
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Auto Controls")

-- Toggle Shake
MainSection:NewToggle("Auto Shake", "Bật/tắt lắc tay chân đầu", function(state)
    if state then
        startShake()
        Library:Notify("Auto Shake: BẬT", 3)
    else
        stopShake()
        Library:Notify("Auto Shake: TẮT", 3)
    end
end)

-- Toggle Spin
MainSection:NewToggle("Auto Spin", "Bật/tắt xoay nhân vật", function(state)
    if state then
        startSpin()
        Library:Notify("Auto Spin: BẬT", 3)
    else
        stopSpin()
        Library:Notify("Auto Spin: TẮT", 3)
    end
end)

-- Toggle UI Visibility
MainSection:NewButton("Toggle UI", "Ẩn/hiện giao diện", function()
    uiVisible = not uiVisible
    Library:ToggleUI()
    Library:Notify("UI: " .. (uiVisible and "Hiện" or "Ẩn"), 3)
end)

-- Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Adjustments")

-- Sliders (giá trị tối ưu cho mobile)
SettingsSection:NewSlider("Shake Speed", "Tốc độ lắc (cao hơn = chậm hơn)", 50, 10, function(s)
    shakeSpeed = s / 100  -- 0.1-0.5
    Library:Notify("Shake Speed: " .. shakeSpeed, 3)
end)

SettingsSection:NewSlider("Shake Intensity", "Cường độ lắc", 50, 10, function(s)
    shakeIntensity = s / 100  -- 0.1-0.5
    Library:Notify("Shake Intensity: " .. shakeIntensity, 3)
end)

SettingsSection:NewSlider("Spin Speed", "Tốc độ xoay", 400, 10, function(s)
    spinSpeed = s / 100  -- 0.1-4
    Library:Notify("Spin Speed: " .. spinSpeed, 3)
end)

-- Nút Destroy
SettingsSection:NewButton("Destroy Script", "Dừng và xóa UI", function()
    stopShake()
    stopSpin()
    Library:Destroy()
    Library:Notify("Script đã dừng!", 3)
end)

-- Khởi động
Library:Notify("Script loaded! Sử dụng nút trong UI để điều khiển.", 5)
print("Break Your Bones - Mobile Auto Script loaded!")
