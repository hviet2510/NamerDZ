-- Auto Shake & Spin Script for Break Your Bones (Fixed & Stable Version)
-- Tác giả: Grok (dựa trên cơ chế ragdoll Roblox)
-- Phiên bản: 2.0 - An toàn hơn, ổn định, thêm Kavo UI Library cho toggle chức năng & UI
-- Cách dùng: Execute sau khi vào game. UI sẽ tự hiện. Toggle UI bằng phím 'U' hoặc nút trong UI.

-- Load Kavo UI Library (phổ biến và ổn định cho Roblox scripts)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Break Your Bones - Auto Shake & Spin", "DarkTheme")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Biến trạng thái
local shakeEnabled = false
local spinEnabled = false
local uiVisible = true
local shakeConnection = nil
local spinConnection = nil

-- Các bộ phận cần lắc (tay, chân, đầu)
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

-- Cấu hình
local shakeSpeed = 0.1  -- Tốc độ lắc (giây)
local shakeIntensity = 0.5  -- Cường độ lắc (radian)
local spinSpeed = 5  -- Tốc độ xoay (radian/giây)

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

-- Loop lắc (riêng biệt cho toggle)
local function startShake()
    if shakeEnabled or shakeConnection then return end
    shakeEnabled = true
    shakeConnection = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then
            shakeEnabled = false
            if shakeConnection then shakeConnection:Disconnect() end
            return
        end
        for _, part in ipairs(bodyParts) do
            shakePart(part)
        end
        task.wait(shakeSpeed)  -- Sử dụng task.wait thay wait để ổn định hơn
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
    spinConnection = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent or not humanoidRootPart or not humanoidRootPart.Parent then
            spinEnabled = false
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        spinCharacter()
        task.wait(0.05)  -- Delay nhỏ cho spin để mượt mà
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
    -- Restart nếu đang bật
    if shakeEnabled then startShake() end
    if spinEnabled then startSpin() end
end)

-- Toggle UI bằng phím 'U'
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        uiVisible = not uiVisible
        if uiVisible then
            Library:ToggleUI()
        else
            Library:ToggleUI()  -- Kavo UI dùng ToggleUI để ẩn/hiện
        end
    end
end)

-- UI Setup với Kavo Library
local MainTab = Window:NewTab("Main Functions")
local MainSection = MainTab:NewSection("Auto Shake & Spin")

-- Toggle Shake
MainSection:NewToggle("Auto Shake Limbs & Head", "Bật/tắt lắc tay chân đầu", function(state)
    if state then
        startShake()
        print("Auto Shake: Bật")
    else
        stopShake()
        print("Auto Shake: Tắt")
    end
end)

-- Toggle Spin
MainSection:NewToggle("Auto Spin Character", "Bật/tắt xoay nhân vật", function(state)
    if state then
        startSpin()
        print("Auto Spin: Bật")
    else
        stopSpin()
        print("Auto Spin: Tắt")
    end
end)

-- Section cho UI Control
local UISection = MainTab:NewSection("UI Controls")

-- Toggle UI Visibility
UISection:NewButton("Toggle UI (or press 'U')", "Ẩn/hiện UI", function()
    uiVisible = not uiVisible
    Library:ToggleUI()
    print("UI Toggled: " .. (uiVisible and "Visible" or "Hidden"))
end)

-- Sliders cho tùy chỉnh
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Adjustments")

SettingsSection:NewSlider("Shake Speed", "Tốc độ lắc (thấp hơn = nhanh hơn)", 50, 1, function(s)
    shakeSpeed = s / 100  -- Chuyển từ 1-100 sang 0.01-1
end)

SettingsSection:NewSlider("Shake Intensity", "Cường độ lắc", 50, 1, function(s)
    shakeIntensity = s / 100  -- 0.01-1
end)

SettingsSection:NewSlider("Spin Speed", "Tốc độ xoay (cao hơn = nhanh hơn)", 500, 1, function(s)
    spinSpeed = s / 100  -- 0.01-5
end)

-- Nút Destroy UI (an toàn)
SettingsSection:NewButton("Destroy UI & Stop All", "Dừng tất cả và xóa UI", function()
    stopShake()
    stopSpin()
    Library:Destroy()
    print("Script stopped & UI destroyed.")
end)

-- Khởi động UI
print("Script loaded! UI hiện tại. Nhấn 'U' để toggle UI.")
Library:ToggleUI()  -- Đảm bảo UI hiện
