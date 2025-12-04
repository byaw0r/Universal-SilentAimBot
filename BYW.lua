local hitboxEnabled = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeadHitbox"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local hitboxBtn = Instance.new("TextButton")
hitboxBtn.Name = "HeadHitboxBtn"
hitboxBtn.Size = UDim2.new(0, 40, 0, 40)
hitboxBtn.Position = UDim2.new(0, 10, 0, 10)
hitboxBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
hitboxBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
hitboxBtn.Text = "SA"
hitboxBtn.TextSize = 28
hitboxBtn.Font = Enum.Font.GothamBold
hitboxBtn.BorderSizePixel = 0
hitboxBtn.Active = true
hitboxBtn.Draggable = true
hitboxBtn.ZIndex = 999999
hitboxBtn.Parent = screenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = hitboxBtn

local espConnection
local originalSizes = {}
local originalTransparencies = {}
local hitboxSize = 25

local function getHead(character)
    return character:FindFirstChild("Head")
end

local function isAlive(player)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function isPlayerVisible(player)
    if player == game.Players.LocalPlayer then return false end
    
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    local targetCharacter = player.Character
    
    if not localCharacter or not targetCharacter then return false end
    
    local localHead = localCharacter:FindFirstChild("Head")
    local targetHead = targetCharacter:FindFirstChild("Head")
    
    if not localHead or not targetHead then return false end
    
    local distance = (localHead.Position - targetHead.Position).Magnitude
    if distance > 500 then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localCharacter, targetCharacter}
    
    local raycastResult = workspace:Raycast(
        localHead.Position,
        (targetHead.Position - localHead.Position).Unit * distance,
        raycastParams
    )
    
    if raycastResult then
        local hitParent = raycastResult.Instance.Parent
        local isPlayerPart = false
        
        while hitParent do
            if hitParent == targetCharacter then
                isPlayerPart = true
                break
            end
            hitParent = hitParent.Parent
        end
        
        return isPlayerPart
    end
    
    return true
end

local function applyHitbox(player)
    if player == game.Players.LocalPlayer then return end
    
    if not isPlayerVisible(player) then
        if originalSizes[player] then
            pcall(function()
                restoreHitbox(player)
            end)
        end
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local head = getHead(character)
    if not head then return end
    
    if not originalSizes[player] then
        originalSizes[player] = head.Size
        originalTransparencies[player] = head.Transparency
    end
    
    head.Transparency = 1
    head.CanTouch = true
    head.CanQuery = true
    head.CanCollide = false
    
    head.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
    head.Massless = true
    
    for _, child in pairs(head:GetChildren()) do
        if child:IsA("Decal") or child:IsA("Texture") then
            child:Destroy()
        end
    end
    
    local wireframe = head:FindFirstChild("HitboxWireframe")
    if wireframe then 
        wireframe:Destroy() 
    end
    
    local outline = head:FindFirstChild("HitboxOutline")
    if outline then 
        outline:Destroy() 
    end
    
    local hitHelper = head:FindFirstChild("HitHelper")
    if not hitHelper then
        hitHelper = Instance.new("Part")
        hitHelper.Name = "HitHelper"
        hitHelper.Size = Vector3.new(hitboxSize * 0.9, hitboxSize * 0.9, hitboxSize * 0.9)
        hitHelper.Transparency = 1
        hitHelper.CanCollide = false
        hitHelper.CanTouch = true
        hitHelper.CanQuery = true
        hitHelper.Anchored = false
        hitHelper.Massless = true
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head
        weld.Part1 = hitHelper
        weld.Parent = hitHelper
        
        hitHelper.Parent = head
    end
end

local function restoreHitbox(player)
    if not originalSizes[player] then return end
    
    local character = player.Character
    if character then
        local head = getHead(character)
        if head then
            head.Size = originalSizes[player]
            head.Transparency = originalTransparencies[player] or 0
            
            head.CanCollide = true
            head.CanTouch = true
            head.CanQuery = true
            head.Massless = false
            
            local hitHelper = head:FindFirstChild("HitHelper")
            if hitHelper then hitHelper:Destroy() end
        end
    end
    
    originalSizes[player] = nil
    originalTransparencies[player] = nil
end

local function updateHitboxes()
    if not hitboxEnabled then return end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player == game.Players.LocalPlayer then continue end
        
        if isAlive(player) then
            pcall(function()
                if isPlayerVisible(player) then
                    applyHitbox(player)
                else
                    restoreHitbox(player)
                end
            end)
        else
            pcall(restoreHitbox, player)
        end
    end
end

local function toggleHitbox()
    hitboxEnabled = not hitboxEnabled
    
    if hitboxEnabled then
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        
        if not espConnection then
            espConnection = game:GetService("RunService").Heartbeat:Connect(updateHitboxes)
        end
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and isAlive(player) then
                pcall(function()
                    if isPlayerVisible(player) then
                        applyHitbox(player)
                    end
                end)
            end
        end
        
    else
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                pcall(restoreHitbox, player)
            end
        end
    end
end

hitboxBtn.MouseButton1Click:Connect(toggleHitbox)

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.H then
        toggleHitbox()
    end
end)

game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then return end
    
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid").Died:Connect(function()
            if hitboxEnabled then
                wait(0.1)
                pcall(restoreHitbox, player)
            end
        end)
    end)
end)

game.Players.PlayerRemoving:Connect(function(player)
    pcall(restoreHitbox, player)
end)

for _, player in pairs(game.Players:GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            wait(0.5)
            if hitboxEnabled and isAlive(player) then
                pcall(function()
                    if isPlayerVisible(player) then
                        applyHitbox(player)
                    end
                end)
            end
        end)
    end
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    if hitboxEnabled then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and isAlive(player) then
                pcall(function()
                    if isPlayerVisible(player) then
                        applyHitbox(player)
                    end
                end)
            end
        end
    end
end)

local function startVisibilityCheck()
    while true do
        wait(0.2)
        if hitboxEnabled then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and isAlive(player) then
                    pcall(function()
                        if originalSizes[player] then
                            if not isPlayerVisible(player) then
                                restoreHitbox(player)
                            end
                        end
                    end)
                end
            end
        end
    end
end

spawn(startVisibilityCheck)

print("BYW SCRIPT loaded!")
