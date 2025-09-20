-- Load Rayfield UI library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fast Attack",
   LoadingTitle = "Blox Fruits",
   LoadingSubtitle = "by VietHoangIOS",
   Theme = "Default",
   ToggleUIKeybind = Enum.KeyCode.K,
   DisableRayfieldPrompts = true,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Big Hub"
   },
   KeySystem = false,
})

local Tab = Window:CreateTab("Fast Attack")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local connection = nil
local hitboxConnection = nil

local Settings = {
    AutoClick = false,
    ClickDelay = 0.05,
    SpeedOn = false,
    HitboxOn = false,
    AttackMobs = true,
    AttackPlayers = false,
}

local SPEED_VALUE = 1500
local HITBOX_SIZE = Vector3.new(30, 30, 30)
local DEFAULT_SIZE = Vector3.new(2, 2, 1)
local NPC_HITBOX_SIZE = Vector3.new(30, 30, 30)
local ATTACK_DISTANCE = 100

-- Tạo nút bật/tắt cho mobile
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Player:WaitForChild("PlayerGui")
screenGui.Name = "MobileToggleUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

local toggleButton = Instance.new("TextButton")
toggleButton.Parent = screenGui
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0.02, 0, 0.02, 0) -- Góc trên trái
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.BackgroundTransparency = 0.3
toggleButton.Text = "UI"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleButton

-- Hiệu ứng hover cho nút mobile
toggleButton.MouseEnter:Connect(function()
    toggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
end)
toggleButton.MouseLeave:Connect(function()
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)

-- Xử lý chạm để bật/tắt UI
toggleButton.Activated:Connect(function()
    Window:Toggle() -- Toggle Rayfield UI
    toggleButton.Text = Window:IsVisible() and "UI ON" or "UI OFF"
end)

-- Đảm bảo nút tương thích với mobile
UserInputService.TouchTapInWorld:Connect(function(position)
    if toggleButton.Visible then
        local buttonPos = toggleButton.AbsolutePosition
        local buttonSize = toggleButton.AbsoluteSize
        if position.X >= buttonPos.X and position.X <= buttonPos.X + buttonSize.X and
           position.Y >= buttonPos.Y and position.Y <= buttonPos.Y + buttonSize.Y then
            Window:Toggle()
            toggleButton.Text = Window:IsVisible() and "UI ON" or "UI OFF"
        end
    end
end)

local function SafeWaitForChild(parent, childName)
    local success, result = pcall(function()
        return parent:WaitForChild(childName, 5)
    end)
    if not success or not result then
        warn("Không tìm thấy: " .. childName)
    end
    return result
end

-- Tìm RemoteEvent động
local function findRemoteEvent()
    local net = SafeWaitForChild(SafeWaitForChild(ReplicatedStorage, "Modules"), "Net")
    local registerAttack = SafeWaitForChild(net, "RE/RegisterAttack")
    local registerHit = SafeWaitForChild(net, "RE/RegisterHit")
    return registerAttack, registerHit
end

local RegisterAttack, RegisterHit = findRemoteEvent()

local function IsAlive(character)
    return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end

-- Hàm tìm mục tiêu
local function ProcessEnemies(OthersEnemies, Folder)
    local BasePart = nil
    for _, Enemy in pairs(Folder:GetChildren()) do
        local Head = Enemy:FindFirstChild("Head")
        if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < ATTACK_DISTANCE then
            if Enemy ~= Player.Character then
                table.insert(OthersEnemies, {Enemy, Head})
                BasePart = Head
            end
        end
    end
    return BasePart
end

-- Hàm tấn công với tham số FireServer tối ưu
local function Attack(BasePart, OthersEnemies)
    if not BasePart or #OthersEnemies == 0 then return end
    local character = Player.Character
    if not character or not IsAlive(character) then return end
    local tool = character:FindFirstChildOfClass("Tool")
    
    pcall(function()
        RegisterAttack:FireServer(0)
    end)

    for _, enemyData in ipairs(OthersEnemies) do
        local enemy = enemyData[1]
        local head = enemyData[2]
        local direction = (head.Position - character:GetPivot().Position).Unit
        local hitPosition = head.Position
        local toolName = tool and tool.Name or "Melee"
        local hitCFrame = CFrame.new(character:GetPivot().Position, head.Position)
        
        pcall(function()
            RegisterHit:FireServer(head, {enemy}, direction, toolName, hitPosition, hitCFrame)
        end)
    end
end

-- Hàm tấn công gần nhất
local function AttackNearest()
    local OthersEnemies = {}
    local Part1, Part2 = nil, nil

    if Settings.AttackMobs then
        Part1 = ProcessEnemies(OthersEnemies, Workspace:WaitForChild("Enemies"))
    end

    if Settings.AttackPlayers then
        Part2 = ProcessEnemies(OthersEnemies, Workspace:WaitForChild("Characters"))
    end

    local character = Player.Character
    if not character then return end
    local equippedWeapon = character:FindFirstChildOfClass("Tool")

    if equippedWeapon and equippedWeapon:FindFirstChild("LeftClickRemote") then
        for _, enemyData in ipairs(OthersEnemies) do
            local enemy = enemyData[1]
            local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
            local hitCFrame = CFrame.new(character:GetPivot().Position, enemy.HumanoidRootPart.Position)
            pcall(function()
                equippedWeapon.LeftClickRemote:FireServer(direction, 1, hitCFrame)
            end)
        end
    elseif #OthersEnemies > 0 then
        Attack(Part1 or Part2, OthersEnemies)
    else
        task.wait(0)
    end
end

-- Hàm xử lý đòn đánh
local function BladeHits()
    local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped and Equipped.ToolTip ~= "Gun" then
        AttackNearest()
    else
        task.wait(0)
    end
end

-- Hàm cập nhật hitbox của nhân vật và công cụ
local function updateHitbox(character, enable)
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.Size = enable and HITBOX_SIZE or DEFAULT_SIZE
        rootPart.Transparency = enable and 0.7 or 1
        rootPart.CanCollide = true
    end

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Size = enable and HITBOX_SIZE or DEFAULT_SIZE
                    part.Transparency = enable and 0.7 or 1
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Hàm cập nhật hitbox của NPC
local function updateNPCHitbox(enable)
    if enable then
        if hitboxConnection then return end
        hitboxConnection = task.spawn(function()
            while Settings.HitboxOn do
                pcall(function()
                    for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                        if enemy:IsA("Model") and IsAlive(enemy) then
                            local hpr = enemy:FindFirstChild("HumanoidRootPart")
                            if hpr then
                                hpr.Size = NPC_HITBOX_SIZE
                                hpr.Transparency = 0.7
                                hpr.CanCollide = true
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if hitboxConnection then
            task.cancel(hitboxConnection)
            hitboxConnection = nil
        end
        pcall(function()
            for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                if enemy:IsA("Model") then
                    local hpr = enemy:FindFirstChild("HumanoidRootPart")
                    if hpr then
                        hpr.Size = DEFAULT_SIZE
                        hpr.Transparency = 1
                        hpr.CanCollide = true
                    end
                end
            end
        end)
    end
end

-- Slider điều chỉnh ClickDelay
Tab:CreateSlider({
    Name = "Click Delay (s)",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = Settings.ClickDelay,
    Callback = function(value)
        Settings.ClickDelay = value
    end
})

-- Toggle Fast Attack
Tab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = false,
    Callback = function(isEnabled)
        Settings.AutoClick = isEnabled
        if isEnabled then
            if connection then return end
            connection = task.spawn(function()
                while Settings.AutoClick do
                    pcall(function()
                        BladeHits()
                    end)
                    task.wait(Settings.ClickDelay)
                end
                connection = nil
            end)
        else
            Settings.AutoClick = false
            if connection then
                task.cancel(connection)
                connection = nil
            end
        end
    end
})

-- Toggle Attack Mobs
Tab:CreateToggle({
    Name = "Attack Mobs",
    CurrentValue = true,
    Callback = function(value)
        Settings.AttackMobs = value
    end
})

-- Toggle Attack Players
Tab:CreateToggle({
    Name = "Attack Players",
    CurrentValue = false,
    Callback = function(value)
        Settings.AttackPlayers = value
    end
})

-- Toggle Chạy nhanh
Tab:CreateToggle({
    Name = "Chạy nhanh",
    CurrentValue = false,
    Callback = function(value)
        Settings.SpeedOn = value
        local character = Player.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Settings.SpeedOn and SPEED_VALUE or 16
        end
    end
})

-- Toggle Đánh xa
Tab:CreateToggle({
    Name = "Đánh xa",
    CurrentValue = false,
    Callback = function(value)
        Settings.HitboxOn = value
        local character = Player.Character
        updateHitbox(character, Settings.HitboxOn)
        updateNPCHitbox(Settings.HitboxOn)
    end
})

-- Xử lý khi nhân vật respawn
Player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if Settings.SpeedOn and humanoid then
        humanoid.WalkSpeed = SPEED_VALUE
    end
    if Settings.HitboxOn then
        updateHitbox(character, true)
    end
end)

-- Đảm bảo game đã tải xong
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
