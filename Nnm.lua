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

local autoWinRunning = false
local autoWinConnection = nil
local currentTween = nil
local isMoving = false
local winCFrame = CFrame.new(-8352.27148, 483.494202, 1470.01685, 1, 0, 0, 0, 1, 0, 0, 0, 1)

local function spoofMovement()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    
    task.wait(0.1)
    
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
end

local function randomPause()
    local pauseTime = math.random(2, 6)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if humanoid then
        local originalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 0
        task.wait(pauseTime)
        humanoid.WalkSpeed = originalWalkSpeed
    else
        task.wait(pauseTime)
    end
end

local function simulateHumanMovement(targetCFrame)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return false end
    
    local startCFrame = hrp.CFrame
    local distance = (startCFrame.Position - targetCFrame.Position).Magnitude
    local duration = math.max(5, math.min(20, distance / 15))
    
    local points = {}
    local numPoints = math.random(3, 7)
    
    for i = 0, numPoints do
        local t = i / numPoints
        local point = startCFrame.Position:Lerp(targetCFrame.Position, t)
        local randomOffset = Vector3.new(
            math.random(-3, 3),
            math.random(-1, 2),
            math.random(-3, 3)
        )
        table.insert(points, point + randomOffset)
    end
    table.insert(points, targetCFrame.Position)
    
    isMoving = true
    
    local walkingConnection = nil
    local jumpingConnection = nil
    
    walkingConnection = RunService.Heartbeat:Connect(function()
        if not autoWinRunning or not isMoving then
            return
        end
        
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        
        local randomJump = math.random(1, 80)
        if randomJump < 2 and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.3)
        end
    end)
    
    for i, point in ipairs(points) do
        if not autoWinRunning or not isMoving then break end
        
        local segmentDistance = (hrp.Position - point).Magnitude
        local segmentDuration = math.max(1, math.min(5, segmentDistance / 12))
        
        local tweenInfo = TweenInfo.new(
            segmentDuration,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        )
        
        local segmentTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(point)})
        segmentTween:Play()
        segmentTween.Completed:Wait()
        
        if i < #points and autoWinRunning and isMoving then
            local shouldPause = math.random(1, 3) == 1
            if shouldPause then
                randomPause()
            end
        end
    end
    
    if walkingConnection then walkingConnection:Disconnect() end
    if jumpingConnection then jumpingConnection:Disconnect() end
    
    local finalAdjust = TweenInfo.new(
        1,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    )
    local finalTween = TweenService:Create(hrp, finalAdjust, {CFrame = targetCFrame})
    finalTween:Play()
    finalTween.Completed:Wait()
    
    isMoving = false
    spoofMovement()
    
    return true
end

local function getCurrentCharacterState()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    return {
        hrp = character:FindFirstChild("HumanoidRootPart"),
        humanoid = character:FindFirstChild("Humanoid"),
        walkSpeed = character:FindFirstChild("Humanoid") and character.Humanoid.WalkSpeed or 16,
        jumpPower = character:FindFirstChild("Humanoid") and character.Humanoid.JumpPower or 50
    }
end

local function restoreCharacterState(state)
    if not state then return end
    if state.humanoid and state.humanoid.Parent then
        state.humanoid.WalkSpeed = state.walkSpeed
        state.humanoid.JumpPower = state.jumpPower
    end
end

local function teleportWithSpofing()
    local characterState = getCurrentCharacterState()
    
    if not characterState or not characterState.hrp then
        task.wait(0.5)
        characterState = getCurrentCharacterState()
        if not characterState or not characterState.hrp then return false end
    end
    
    local success, result = pcall(function()
        return simulateHumanMovement(winCFrame)
    end)
    
    if success then
        restoreCharacterState(characterState)
        return true
    else
        return false
    end
end

local function bypassTeleport()
    local metatable = getrawmetatable(game)
    local oldnamecall = metatable.__namecall
    local oldindex = metatable.__index
    
    setreadonly(metatable, false)
    
    metatable.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        if method == "FireServer" and tostring(self):find("RemoteEvent") then
            local args = {...}
            if args[1] and (tostring(args[1]):find("Teleport") or tostring(args[1]):find("Win") or tostring(args[1]):find("Finish")) then
                return nil
            end
        end
        
        return oldnamecall(self, ...)
    end)
    
    metatable.__index = newcclosure(function(self, key)
        if key == "WalkSpeed" or key == "JumpPower" then
            return 16
        end
        return oldindex(self, key)
    end)
    
    setreadonly(metatable, true)
end

local function startAutoWin()
    bypassTeleport()
    
    task.spawn(function()
        while autoWinRunning do
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") and not isMoving then
                local currentPos = character.HumanoidRootPart.Position
                local targetPos = winCFrame.Position
                local distance = (currentPos - targetPos).Magnitude
                
                if distance > 10 then
                    local initialPause = math.random(3, 8)
                    task.wait(initialPause)
                    
                    local success = teleportWithSpofing()
                    if success then
                        WindUI:Notify({
                            Title = "Auto Win",
                            Content = "Moving to win location...",
                            Duration = 2,
                        })
                    end
                end
            end
            
            local waitTime = math.random(8, 15)
            for i = 1, waitTime do
                if not autoWinRunning then break end
                task.wait(1)
            end
        end
    end)
end

MainTab:Toggle({
    Title = "Auto Win",
    Value = false,
    Callback = function(state)
        autoWinRunning = state
        
        if autoWinConnection then
            autoWinConnection:Disconnect()
            autoWinConnection = nil
        end
        
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        
        isMoving = false
        
        if state then
            startAutoWin()
            
            autoWinConnection = LocalPlayer.CharacterAdded:Connect(function()
                task.wait(2)
                if autoWinRunning then
                    startAutoWin()
                end
            end)
            
            WindUI:Notify({
                Title = "Auto Win",
                Content = "Auto Win activated (stealth mode)",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Auto Win",
                Content = "Auto Win deactivated",
                Duration = 2,
            })
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

local noclipEnabled = false
local noclipConnection = nil

PlayerTab:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(state)
        noclipEnabled = state
        if state then
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
