local Invisible
local Mode
local AvoidSpeed
local Visualize
local oldcf
local animtrack
local paused = false
local avoidAccum = 0
local avoidUp = true
local ghostModel
local ghostParts
local ghostOffsets
local ghostConn
local physCf
local proper = true

local function kickBusy()
        local kick = vape.Modules.KickExploit
        local position = vape.Modules.AutoPosition
        return (kick and kick.Enabled) or (position and position.Enabled) or false
end

local function animationTrickery()
        if entitylib.isAlive then
                local isR15 = entitylib.character.Humanoid.RigType == Enum.HumanoidRigType.R15
                local anim = Instance.new('Animation')
                anim.AnimationId = 'rbxassetid://'..(isR15 and '18665825805' or '215384594')
                animtrack = entitylib.character.Humanoid.Animator:LoadAnimation(anim)
                animtrack.Priority = Enum.AnimationPriority.Action4
                animtrack:Play(0, 0.001, 0)
                anim:Destroy()

                task.delay(0, function()
                        if animtrack then
                                animtrack.TimePosition = isR15 and 1.95 or 0.4
                        end
                end)
        end
end

local function destroyGhost()
        if ghostConn then
                ghostConn:Disconnect()
                ghostConn = nil
        end

        if ghostModel then
                ghostModel:Destroy()
                ghostModel = nil
                ghostParts = nil
                ghostOffsets = nil
        end
end

local function buildGhost()
        destroyGhost()

        if not (Visualize.Enabled and Invisible.Enabled and entitylib.isAlive) then
                return
        end

        local char = entitylib.character.Character
        if not char then
                return
        end

        ghostModel = Instance.new('Model')
        ghostModel.Name = 'VapeAvoidVisual'
        ghostParts = {}
        ghostOffsets = {}

        local root = entitylib.character.RootPart

        for _, part in char:GetDescendants() do
                if part:IsA('BasePart') and part.Transparency < 1 then
                        local ghost = part:Clone()

                        if ghost then
                                for _, child in ghost:GetChildren() do
                                        if not child:IsA('DataModelMesh') then
                                                child:Destroy()
                                        end
                                end

                                ghost.Name = 'VapeGhost'
                                ghost.Anchored = true
                                ghost.CanCollide = false
                                ghost.CanQuery = false
                                ghost.CanTouch = false
                                ghost.CastShadow = false
                                ghost.Transparency = 0
                                ghost.Material = Enum.Material.ForceField
                                ghost.Color = Color3.fromRGB(255, 0, 0)

                                if ghost:IsA('MeshPart') then
                                        ghost.TextureID = ''
                                end

                                ghost.CFrame = part.CFrame
                                ghost.Parent = ghostModel
                                ghostParts[part] = ghost
                                ghostOffsets[ghost] = root.CFrame:ToObjectSpace(part.CFrame)
                        end
                end
        end

        if not next(ghostParts) then
                destroyGhost()
                return
        end

        local highlight = Instance.new('Highlight')
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.55
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineTransparency = 0.1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = ghostModel

        ghostConn = runService.RenderStepped:Connect(function()
                if ghostModel and ghostOffsets and entitylib.isAlive then
                        local show = Mode.Value == 'Avoid' and not paused and not avoidUp and physCf ~= nil
                        local parent = show and workspace or nil

                        if ghostModel.Parent ~= parent then
                                ghostModel.Parent = parent
                        end

                        if show then
                                for ghost, offset in ghostOffsets do
                                        ghost.CFrame = physCf * offset
                                end
                        end
                end
        end)
end

Invisible = vape.Categories.Blatant:CreateModule({
        Name = 'Invisible',
        Function = function(callback)
                if callback then
                        avoidAccum = 0
                        avoidUp = true
                        paused = kickBusy()
                        oldcf = nil
                        physCf = nil

                        if not paused and Mode.Value == 'Normal' then
                                animationTrickery()
                        end

                        local bindKey = httpService:GenerateGUID(true)
                        runService:BindToRenderStep(bindKey, 0, function()
                                if entitylib.isAlive and oldcf and not paused then
                                        entitylib.character.RootPart.CFrame = oldcf

                                        if animtrack then
                                                animtrack:AdjustWeight(0.001)
                                        end
                                end
                        end)

                        Invisible:Clean(function()
                                runService:UnbindFromRenderStep(bindKey)
                        end)

                        Invisible:Clean(runService.Heartbeat:Connect(function(dt)
                                local kickNow = kickBusy()

                                if kickNow ~= paused then
                                        paused = kickNow
                                        avoidAccum = 0
                                        avoidUp = true

                                        if paused then
                                                if entitylib.isAlive and oldcf then
                                                        entitylib.character.RootPart.CFrame = oldcf
                                                end

                                                if animtrack then
                                                        animtrack:AdjustWeight(0.001)
                                                end
                                        elseif entitylib.isAlive and animtrack == nil and Mode.Value == 'Normal' then
                                                animationTrickery()
                                        end
                                end

                                if paused or not entitylib.isAlive then
                                        return
                                end

                                local root = entitylib.character.RootPart
                                local isR15 = entitylib.character.Humanoid.RigType == Enum.HumanoidRigType.R15
                                local sink = entitylib.character.Humanoid.HipHeight + (root.Size.Y / 2) - 1
                                local bury = entitylib.character.HipHeight + 2

                                if Mode.Value == 'Avoid' then
                                        avoidAccum += dt * AvoidSpeed.Value

                                        if avoidAccum >= 1 then
                                                avoidAccum -= math.floor(avoidAccum)
                                                avoidUp = not avoidUp
                                        end

                                        if avoidUp then
                                                oldcf = root.CFrame
                                                physCf = root.CFrame
                                        elseif oldcf then
                                                physCf = (oldcf - Vector3.new(0, bury, 0)) * CFrame.Angles(math.rad(isR15 and 180 or 90), 0, 0)
                                                root.CFrame = physCf
                                        end

                                        return
                                end

                                local cf = root.CFrame - Vector3.new(0, sink, 0)
                                oldcf = root.CFrame

                                root.CFrame = cf * CFrame.Angles(math.rad(isR15 and 180 or 90), 0, 0)

                                if animtrack then
                                        animtrack:AdjustWeight(100)
                                end
                        end))

                        Invisible:Clean(entitylib.Events.LocalAdded:Connect(function(char)
                                local animator = char.Humanoid:WaitForChild('Animator', 1)

                                if animator and Invisible.Enabled then
                                        oldcf = nil
                                        Invisible:Toggle()
                                        Invisible:Toggle()

                                        task.delay(0.5, buildGhost)
                                end
                        end))

                        buildGhost()
                else
                        destroyGhost()

                        if animtrack then
                                animtrack:Stop()
                                animtrack:Destroy()
                                animtrack = nil
                        end

                        if entitylib.isAlive and oldcf and not kickBusy() and (entitylib.character.RootPart.Position - oldcf.Position).Magnitude < 10 then
                                entitylib.character.RootPart.CFrame = oldcf
                        end

                        paused = false
                end
        end,
        Tooltip = 'Turns you invisible.'
})
Mode = Invisible:CreateDropdown({
        Name = 'Mode',
        List = {'Normal', 'Avoid'},
        Function = function(value)
                if AvoidSpeed then
                        AvoidSpeed.Object.Visible = value == 'Avoid'
                end

                if Visualize then
                        Visualize.Object.Visible = value == 'Avoid'
                end

                if Invisible.Enabled then
                        Invisible:Toggle()
                        Invisible:Toggle()
                end
        end
})
AvoidSpeed = Invisible:CreateSlider({
        Name = 'Avoid Speed',
        Min = 1,
        Max = 20,
        Default = 10,
        Visible = false,
        Darker = true,
        Suffix = function(value)
                return value == 1 and 'flip' or 'flips'
        end
})
Visualize = Invisible:CreateToggle({
        Name = 'Visualize',
        Visible = false,
        Darker = true,
        Function = function(callback)
                if Invisible.Enabled then
                        if callback then
                                buildGhost()
                        else
                                destroyGhost()
                        end
                end
        end,
        Tooltip = 'Shows a red forcefield ghost where your character really is while Avoid buries you.'
})
