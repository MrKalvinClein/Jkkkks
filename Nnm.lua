local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Dexter Scripts",
    Icon = "square-user",
    Author = "by nipcd",
    Folder = "DexterScripts",
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
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            WindUI:Notify({
                Title = "Hey!",
                Content = "It's you, lol",
                Duration = 3,
            })
        end,
    },
})

local Cfg = {
    AutoWin = false,
    WinPos = Vector3.new(-8352.62305, 482.494202, 1467.85583),
    WinHeight = 15,
    WinSpeed = 50,
    Noclip = false,
    Fly = false,
    oldNoclipState = false
}

local noclipConnection = nil
local flyConnection = nil
local bodyVelocity = nil

local function setNoclip(state)
    Cfg.Noclip = state
    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function startFly()
    Cfg.Fly = true
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid.PlatformStand = true
    
    if flyConnection then flyConnection:Disconnect() end
    
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not Cfg.Fly or not LocalPlayer.Character then
            return
        end
        
        local currentRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if currentRoot and bodyVelocity then
            bodyVelocity.Parent = currentRoot
        end
    end)
end

local function stopFly()
    Cfg.Fly = false
    
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            humanoid.PlatformStand = false
        end
    end
end

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "box",
})

MainTab:Section({
    Title = "Movement",
    Box = false,
    Opened = true,
})

local autoWalkRunning = false

MainTab:Toggle({
    Title = "Auto Walk",
    Value = false,
    Callback = function(state)
        autoWalkRunning = state
        if state then
            task.spawn(function()
                local a = {"Walking"}
                while autoWalkRunning do
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UpdateSpeed"):FireServer(unpack(a))
                    task.wait(0.03)
                end
            end)
        end
    end
})

MainTab:Section({
    Title = "Auto Win",
    Box = false,
    Opened = true,
})

MainTab:Toggle({
    Title = "Auto Win (Smooth Travel)",
    Value = false,
    Callback = function(state)
        Cfg.AutoWin = state
        if state then
            task.spawn(function()
                while Cfg.AutoWin do
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if root and Cfg.WinPos then
                        local dist = (root.Position - Cfg.WinPos).Magnitude
                        
                        if dist > 5 then
                            local oldNoclipState = Cfg.Noclip
                            
                            if not Cfg.Fly then
                                startFly()
                            end
                            setNoclip(true)
                            
                            local riseHeight = Cfg.WinHeight
                            local riseStart = root.CFrame
                            local riseEnd = riseStart * CFrame.new(0, riseHeight, 0)
                            
                            WindUI:Notify({
                                Title = "Auto Win",
                                Content = "Rising up...",
                                Duration = 1,
                            })
                            
                            for i = 0, 1, 0.1 do
                                if not Cfg.AutoWin or not root.Parent then 
                                    setNoclip(oldNoclipState)
                                    return 
                                end
                                root.CFrame = riseStart:Lerp(riseEnd, i)
                                task.wait(0.01)
                            end
                            
                            if not Cfg.AutoWin or not root.Parent then 
                                setNoclip(oldNoclipState)
                                return 
                            end
                            task.wait(0.05)
                            
                            WindUI:Notify({
                                Title = "Auto Win",
                                Content = "Traveling...",
                                Duration = 1,
                            })
                            
                            local startCF = root.CFrame
                            local targetPos = Vector3.new(Cfg.WinPos.X, root.Position.Y, Cfg.WinPos.Z)
                            local targetCF = CFrame.new(targetPos, Vector3.new(targetPos.X, targetPos.Y, targetPos.Z + 1))
                            
                            local distance = (root.Position - targetPos).Magnitude
                            local steps = math.max(20, math.min(40, math.floor(distance / 5)))
                            
                            for i = 1, steps do
                                if not Cfg.AutoWin or not root.Parent then 
                                    setNoclip(oldNoclipState)
                                    return 
                                end
                                root.CFrame = startCF:Lerp(targetCF, i / steps)
                                task.wait(0.008)
                            end
                            
                            if not Cfg.AutoWin or not root.Parent then 
                                setNoclip(oldNoclipState)
                                return 
                            end
                            task.wait(0.05)
                            
                            WindUI:Notify({
                                Title = "Auto Win",
                                Content = "Descending...",
                                Duration = 1,
                            })
                            
                            local currentCF = root.CFrame
                            local finalCF = CFrame.new(Cfg.WinPos)
                            
                            for i = 0, 1, 0.05 do
                                if not Cfg.AutoWin or not root.Parent then 
                                    setNoclip(oldNoclipState)
                                    return 
                                end
                                root.CFrame = currentCF:Lerp(finalCF, i)
                                task.wait(0.008)
                            end
                            
                            if root.Parent then
                                root.CFrame = finalCF
                            end
                            
                            setNoclip(oldNoclipState)
                            stopFly()
                            
                            WindUI:Notify({
                                Title = "Auto Win",
                                Content = "Arrived! Resetting...",
                                Duration = 2,
                            })
                            
                            task.wait(1)
                            
                            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then 
                                hum.Health = 0 
                            end
                            
                            task.wait(3)
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            stopFly()
            setNoclip(false)
        end
    end
})

MainTab:Section({
    Title = "Protection",
    Box = false,
    Opened = true,
})

MainTab:Button({
    Title = "Remove Lava",
    Callback = function()
        local lavaFolder = workspace:FindFirstChild("Lava")
        if lavaFolder then
            for _, part in pairs(lavaFolder:GetChildren()) do
                if part.Name == "Lava" then
                    part:Destroy()
                end
            end
            WindUI:Notify({
                Title = "Remove Lava",
                Content = "Lava parts removed!",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Remove Lava",
                Content = "No lava folder found.",
                Duration = 3,
            })
        end
    end
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user",
})

PlayerTab:Space()

PlayerTab:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(state)
        setNoclip(state)
    end
})

PlayerTab:Space()

local WalkSpeedSection = PlayerTab:Section({
    Title = "WalkSpeed",
})

local walkspeedValue = 16
local walkspeedEnabled = false
local walkspeedConnection = nil
local bypassConnection = nil

local function applyWalkSpeed()
    if walkspeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = walkspeedValue
    end
end

WalkSpeedSection:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 7000, Default = 16 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        walkspeedValue = value
        applyWalkSpeed()
    end
})

WalkSpeedSection:Space()

WalkSpeedSection:Toggle({
    Title = "Enable WalkSpeed",
    Value = false,
    Callback = function(state)
        walkspeedEnabled = state
        
        if walkspeedConnection then
            walkspeedConnection:Disconnect()
            walkspeedConnection = nil
        end
        
        if bypassConnection then
            bypassConnection:Disconnect()
            bypassConnection = nil
        end
        
        if state then
            walkspeedConnection = RunService.Heartbeat:Connect(applyWalkSpeed)
            
            bypassConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.1)
                applyWalkSpeed()
            end)
            
            applyWalkSpeed()
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = 16
            end
        end
    end
})

local JumpPowerSection = PlayerTab:Section({
    Title = "JumpPower",
})

local jumppowerValue = 50
local jumppowerEnabled = false
local jumppowerConnection = nil
local jumpBypassConnection = nil

local function applyJumpPower()
    if jumppowerEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = jumppowerValue
    end
end

JumpPowerSection:Slider({
    Title = "JumpPower",
    Value = { Min = 50, Max = 500, Default = 50 },
    Step = 1,
    IsTooltip = true,
    Callback = function(value)
        jumppowerValue = value
        applyJumpPower()
    end
})

JumpPowerSection:Space()

JumpPowerSection:Toggle({
    Title = "Enable JumpPower",
    Value = false,
    Callback = function(state)
        jumppowerEnabled = state
        
        if jumppowerConnection then
            jumppowerConnection:Disconnect()
            jumppowerConnection = nil
        end
        
        if jumpBypassConnection then
            jumpBypassConnection:Disconnect()
            jumpBypassConnection = nil
        end
        
        if state then
            jumppowerConnection = RunService.Heartbeat:Connect(applyJumpPower)
            
            jumpBypassConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.1)
                applyJumpPower()
            end)
            
            applyJumpPower()
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.UseJumpPower = true
                LocalPlayer.Character.Humanoid.JumpPower = 50
            end
        end
    end
})

JumpPowerSection:Space()

local infiniteJumpEnabled = false

JumpPowerSection:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(state)
        infiniteJumpEnabled = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "wrench",
})

MiscTab:Section({
    Title = "Server",
    Box = false,
    Opened = true,
})

MiscTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:Button({
    Title = "Server Hop",
    Callback = function()
        local PlaceId = game.PlaceId
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data then
            for _, server in pairs(servers.data) do
                if server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
                    break
                end
            end
        end
    end
})

MiscTab:Space()

MiscTab:Toggle({
    Title = "Anti-AFK",
    Value = false,
    Callback = function(state)
        if state then
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

MiscTab:Section({
    Title = "Settings",
    Box = false,
    Opened = true,
})

MiscTab:Input({
    Title = "Change Keybind",
    Placeholder = "Enter new keybind",
    Callback = function(text)
        if text and #text > 0 then
            if isMobile then
                WindUI:Notify({
                    Title = "Mobile Device",
                    Content = "Cannot change keybind on mobile",
                    Duration = 2,
                })
                return
            end

            if #text > 1 then
                WindUI:Notify({
                    Title = "Invalid Keybind",
                    Content = "Keybind must be a single letter",
                    Duration = 2,
                })
                return
            end

            local keyName = string.upper(text)

            if keyName == "K" then
                WindUI:Notify({
                    Title = "Invalid Keybind",
                    Content = "This is already the default keybind",
                    Duration = 2,
                })
                return
            end

            if tonumber(keyName) then
                WindUI:Notify({
                    Title = "Invalid Keybind",
                    Content = "Cannot use numbers as keybind",
                    Duration = 2,
                })
                return
            end

            local restrictedKeys = {"A", "S", "D", "W", "SPACE", "UP", "DOWN", "LEFT", "RIGHT", "ESCAPE", "LEFTSHIFT", "SHIFT", "LSHIFT"}
            if table.find(restrictedKeys, keyName) then
                WindUI:Notify({
                    Title = "Invalid Key",
                    Content = "Cannot use movement keys",
                    Duration = 2,
                })
                return
            end

            local keyCode = Enum.KeyCode[keyName]
            if keyCode then
                Window:SetToggleKey(keyCode)
                Window:EditOpenButton({
                    Title = "Keybind: " .. keyName,
                    Icon = "grip",
                    CornerRadius = UDim.new(0, 16),
                    StrokeThickness = 2,
                    OnlyMobile = false,
                    Enabled = true,
                    Draggable = false,
                })
                WindUI:Notify({
                    Title = "Keybind Updated",
                    Content = "Menu keybind changed to: " .. keyName,
                    Duration = 2,
                })
            else
                WindUI:Notify({
                    Title = "Invalid Keybind",
                    Content = "Keybind '" .. text .. "' is not valid",
                    Duration = 2,
                })
            end
        end
    end
})

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

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
        Title = "Game Script",
        Icon = "grip",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        OnlyMobile = true,
        Enabled = true,
        Draggable = true,
    })
end
