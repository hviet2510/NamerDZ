local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Fast Attack",
   LoadingTitle = "Blox Fruit",
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
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local connection = nil

local Settings = {
    AutoClick = false,
    ClickDelay = 0,
}

local function SafeWaitForChild(parent, childName)
    local success, result = pcall(function()
        return parent:WaitForChild(childName)
    end)
    if not success or not result then
        warn("Không tìm thấy: " .. childName)
    end
    return result
end

-- Định nghĩa FastAttack table và các method
local FastAttack = {
    Distance = 100,
    attackMobs = true,
    attackPlayers = false,
    Equipped = nil
}

local Net = SafeWaitForChild(SafeWaitForChild(ReplicatedStorage, "Modules"), "Net")
local RegisterAttack = SafeWaitForChild(Net, "RE/RegisterAttack")
local RegisterHit = SafeWaitForChild(Net, "RE/RegisterHit")

local function IsAlive(character)
    return character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0
end

local function ProcessEnemies(OthersEnemies, Folder)
    local BasePart = nil
    for _, Enemy in pairs(Folder:GetChildren()) do
        local Head = Enemy:FindFirstChild("Head")
        if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < FastAttack.Distance then
            if Enemy ~= Player.Character then
                table.insert(OthersEnemies, {Enemy, Head})
                BasePart = Head
            end
        end
    end
    return BasePart
end

function FastAttack:Attack(BasePart, OthersEnemies)
    if not BasePart or #OthersEnemies == 0 then return end
    RegisterAttack:FireServer(0)
    RegisterHit:FireServer(BasePart, OthersEnemies)
end

function FastAttack:AttackNearest()
    local OthersEnemies = {}
    local workspace = game:GetService("Workspace")
    local Part1, Part2 = nil, nil

    if self.attackMobs then
        Part1 = ProcessEnemies(OthersEnemies, workspace:WaitForChild("Enemies"))
    end

    if self.attackPlayers then
        Part2 = ProcessEnemies(OthersEnemies, workspace:WaitForChild("Characters"))
    end

    local character = Player.Character
    if not character then return end
    local equippedWeapon = character:FindFirstChildOfClass("Tool")

    if equippedWeapon and equippedWeapon:FindFirstChild("LeftClickRemote") then
        for _, enemyData in ipairs(OthersEnemies) do
            local enemy = enemyData[1]
            local direction = (enemy.HumanoidRootPart.Position - character:GetPivot().Position).Unit
            pcall(function()
                equippedWeapon.LeftClickRemote:FireServer(direction, 1)
            end)
        end
    elseif #OthersEnemies > 0 then
        self:Attack(Part1 or Part2, OthersEnemies)
    else
        task.wait(0)
    end
end

function FastAttack:BladeHits()
    local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
    if Equipped and Equipped.ToolTip ~= "Gun" then
        self:AttackNearest()
    else
        task.wait(0)
    end
end

-- Slider điều chỉnh ClickDelay
local ClickDelaySlider = Tab:CreateSlider({
    Name = "Click Delay (s)",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = Settings.ClickDelay,
    Callback = function(value)
        Settings.ClickDelay = value
    end
})

-- Toggle bật/tắt FastAttack
local FastAttackToggle = Tab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = false,
    Callback = function(isEnabled)
        Settings.AutoClick = isEnabled

        if isEnabled then
            if connection then return end
            connection = task.spawn(function()
                while Settings.AutoClick do
                    pcall(function()
                        FastAttack:BladeHits()
                    end)
                    task.wait(Settings.ClickDelay)
                end
                connection = nil
            end)
        else
            Settings.AutoClick = false
            connection = nil
        end
    end
})

-- Toggle Attack Mobs
Tab:CreateToggle({
    Name = "Attack Mobs",
    CurrentValue = FastAttack.attackMobs,
    Callback = function(value)
        FastAttack.attackMobs = value
    end
})

-- Toggle Attack Players
Tab:CreateToggle({
    Name = "Attack Players",
    CurrentValue = FastAttack.attackPlayers,
    Callback = function(value)
        FastAttack.attackPlayers = value
    end
})
