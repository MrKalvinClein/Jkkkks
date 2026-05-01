local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Nuvik | Auto Win",
    Icon = "trophy",
    Author = "by nipcd",
    Folder = "NuvikAutoWin",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home",
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings",
})

local AutoBox = MainTab:Section({
    Title = "Auto Walk",
    Box = true,
    Opened = true,
})

local InfoBox = MainTab:Section({
    Title = "Status",
    Box = true,
    Opened = true,
})

local MiscBox = MainTab:Section({
    Title = "Utility",
    Box = true,
    Opened = true,
})

local TeleportBox = TeleportTab:Section({
    Title = "Teleports",
    Box = true,
    Opened = true,
})

local TeleportInfoBox = TeleportTab:Section({
    Title = "Options",
    Box = true,
    Opened = true,
})

local State = {
    Enabled = false,
    Interval = 0.35,
    Burst = 1,
    Threads = 1,
    Calls = 0,
    Errors = 0,
    ActiveThreads = 0,
}

local IsTeleporting = false
local DefaultGravity = workspace.Gravity

local TpSettings = {
    MaxDelta = 300,
    CheckInterval = 6.5,
    HoldTime = 10,
}

local UpdateSpeed = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UpdateSpeed")

local function Notify(msg, duration)
    WindUI:Notify({
        Title = "Nuvik",
        Content = msg,
        Duration = duration or 3,
    })
end

local function FireWalking()
    if not UpdateSpeed then
        State.Errors += 1
        return false
    end

    local ok, err = pcall(function()
        UpdateSpeed:FireServer("Walking")
    end)

    if ok then
        State.Calls += 1
        return true
    else
        State.Errors += 1
        return false
    end
end

local function SpawnThread(id)
    local offset = (id - 1) * (State.Interval / State.Threads)

    task.spawn(function()
        State.ActiveThreads += 1
        task.wait(offset)

        while State.Enabled do
            for i = 1, State.Burst do
                if not State.Enabled then break end
                FireWalking()
                task.wait(0.02)
            end
            task.wait(State.Interval)
        end

        State.ActiveThreads -= 1
    end)
end

local function StopAllThreads()
    State.Enabled = false
end

local function StartThreads()
    if State.ActiveThreads > 0 then return end
    State.Enabled = true
    State.Errors = 0

    for i = 1, State.Threads do
        SpawnThread(i)
    end
end

local noclipConn = nil
local noclipEnabled = false

MiscBox:Toggle({
    Title = "NoClip",
    Desc = "Disables collision so you can walk through walls.",
    Callback = function(value)
        noclipEnabled = value
        if value then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    if IsTeleporting then return end
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                end)
            end
        else
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
            end
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end)
        end
    end
})

MiscBox:Toggle({
    Title = "No Gravity",
    Desc = "Sets workspace gravity to 0.",
    Callback = function(value)
        if value then
            workspace.Gravity = 0
        else
            workspace.Gravity = DefaultGravity
        end
    end
})

AutoBox:Toggle({
    Title = "Auto Walk",
    Desc = "Fires Walking remote automatically across all threads.",
    Callback = function(value)
        if value then
            StartThreads()
            Notify("Auto Walk enabled | Threads: " .. State.Threads, 2)
        else
            StopAllThreads()
            Notify("Auto Walk disabled", 2)
        end
    end
})

AutoBox:Slider({
    Title = "Interval (s)",
    Value = { Min = 10, Max = 200, Default = 35 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        State.Interval = value / 100
    end
})

AutoBox:Slider({
    Title = "Burst per cycle",
    Value = { Min = 1, Max = 5, Default = 1 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        State.Burst = value
    end
})

AutoBox:Slider({
    Title = "Threads",
    Value = { Min = 1, Max = 100, Default = 1 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        State.Threads = value
        if State.Enabled then
            StopAllThreads()
            task.wait(0.1)
            State.Enabled = true
            StartThreads()
            Notify("Threads restarted: " .. value, 2)
        end
    end
})

AutoBox:Button({
    Title = "Fire Once",
    Callback = function()
        local ok = FireWalking()
        if ok then
            Notify("Walking fired once", 2)
        else
            Notify("Error firing", 4)
        end
    end
})

AutoBox:Button({
    Title = "Reset Stats",
    Callback = function()
        State.Calls = 0
        State.Errors = 0
        Notify("Stats reset", 2)
    end
})

AutoBox:Button({
    Title = "Copy Coords",
    Callback = function()
        local hrp = nil
        pcall(function() hrp = LocalPlayer.Character.HumanoidRootPart end)
        if not hrp then
            Notify("HumanoidRootPart not found", 3)
            return
        end
        local pos = hrp.Position
        local coords = string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
        if setclipboard then
            setclipboard(coords)
            Notify("Coords copied: " .. coords, 4)
        else
            print(coords)
            Notify("setclipboard not supported", 3)
        end
    end
})

local labelCalls = InfoBox:Label({ Title = "Calls: 0" })
local labelErrors = InfoBox:Label({ Title = "Errors: 0" })
local labelThreads = InfoBox:Label({ Title = "Threads: 0" })
local labelState = InfoBox:Label({ Title = "State: Off" })

task.spawn(function()
    while task.wait(0.5) do
        labelCalls:SetTitle("Calls: " .. State.Calls)
        labelErrors:SetTitle("Errors: " .. State.Errors)
        labelThreads:SetTitle("Active Threads: " .. State.ActiveThreads)
        labelState:SetTitle("State: " .. (State.Enabled and "Running" or "Off"))
    end
end)

local function GradualTeleport(targetX, targetY, targetZ)
    if IsTeleporting then return end
    IsTeleporting = true

    task.spawn(function()
        local hrp = nil
        repeat
            task.wait(0.1)
            pcall(function() hrp = LocalPlayer.Character.HumanoidRootPart end)
        until hrp

        local startPos = hrp.Position
        local startY = startPos.Y
        local totalDist = Vector2.new(startPos.X - targetX, startPos.Z - targetZ).Magnitude
        local stepSize = TpSettings.MaxDelta / (TpSettings.CheckInterval / 0.03)
        stepSize = math.max(stepSize, 0.8)

        local tpNoclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end)

        local lockPos = nil
        local lockConn = RunService.RenderStepped:Connect(function()
            if lockPos then
                pcall(function()
                    local h = LocalPlayer.Character.HumanoidRootPart
                    h.CFrame = lockPos
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end)

        while IsTeleporting do
            pcall(function() hrp = LocalPlayer.Character.HumanoidRootPart end)
            if not hrp then
                IsTeleporting = false
                break
            end

            local current = hrp.Position
            local currentFlat = Vector2.new(current.X, current.Z)
            local targetFlat = Vector2.new(targetX, targetZ)
            local distFlat = (targetFlat - currentFlat).Magnitude

            if distFlat <= stepSize * 2 then
                lockPos = CFrame.new(targetX, targetY, targetZ)
                task.wait(0.5)

                local finalY = targetY
                
                pcall(function()
                    local char = LocalPlayer.Character
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {char}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local roofCheck = workspace:Raycast(
                        Vector3.new(targetX, targetY + 10, targetZ),
                        Vector3.new(0, -20, 0),
                        params
                    )
                    
                    if roofCheck and math.abs(targetY - roofCheck.Position.Y) < 5 then
                        local insidePos = Vector3.new(targetX, targetY - 5, targetZ)
                        lockPos = CFrame.new(insidePos)
                        task.wait(0.5)
                        
                        local floorResult = workspace:Raycast(
                            insidePos + Vector3.new(0, 2, 0),
                            Vector3.new(0, -200, 0),
                            params
                        )
                        
                        if floorResult and floorResult.Normal.Y > 0.5 then
                            finalY = floorResult.Position.Y + 3
                        end
                    end
                end)

                lockPos = CFrame.new(targetX, finalY, targetZ)
                Notify("Arrived — holding...", 3)
                task.wait(TpSettings.HoldTime)

                lockPos = nil
                lockConn:Disconnect()
                if tpNoclipConn then tpNoclipConn:Disconnect() end
                
                if not noclipEnabled then
                    pcall(function()
                        local char = LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = true
                                end
                            end
                        end
                    end)
                end

                IsTeleporting = false
                Notify("Teleport complete", 2)
                break
            end

            local progress = 1 - (distFlat / totalDist)
            local interpY = startY + (targetY - startY) * math.clamp(progress, 0, 1)
            local dirFlat = (targetFlat - currentFlat).Unit
            local nextX = current.X + dirFlat.X * stepSize
            local nextZ = current.Z + dirFlat.Y * stepSize

            lockPos = CFrame.new(nextX, interpY, nextZ)
            task.wait(0.03)
        end

        if lockConn then lockConn:Disconnect() end
        if tpNoclipConn then tpNoclipConn:Disconnect() end
        
        if not noclipEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end)
        end
        
        IsTeleporting = false
    end)
end

TeleportBox:Button({
    Title = "+50000 Wins",
    Desc = "Teleport to 50k wins location",
    Callback = function()
        GradualTeleport(-8353.97, 491.42, 1466.87)
    end
})

TeleportBox:Button({
    Title = "Cancel Teleport",
    Desc = "Stops current teleport",
    Callback = function()
        IsTeleporting = false
        Notify("Teleport cancelled", 2)
    end
})

TeleportInfoBox:Slider({
    Title = "Max Delta/Check",
    Value = { Min = 50, Max = 2000, Default = 300 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        TpSettings.MaxDelta = value
    end
})

TeleportInfoBox:Slider({
    Title = "Check Interval (ms)",
    Value = { Min = 1, Max = 6000, Default = 650 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        TpSettings.CheckInterval = value / 100
    end
})

TeleportInfoBox:Slider({
    Title = "Hold Time (s)",
    Value = { Min = 1, Max = 9000, Default = 1000 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        TpSettings.HoldTime = value / 100
    end
})

if not isMobile then
    Window:EditOpenButton({
        Title = "Keybind: K",
        Icon = "grip",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        OnlyMobile = false,
        Enabled = true,
        Draggable = false,
    })
    Window:SetToggleKey(Enum.KeyCode.K)
else
    Window:EditOpenButton({
        Title = "Open Hub",
        Icon = "grip",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        OnlyMobile = true,
        Enabled = true,
        Draggable = true,
    })
end

WindUI:Notify({
    Title = "Nuvik",
    Content = "Auto Win loaded!",
    Icon = "check-circle",
    Duration = 3,
})
