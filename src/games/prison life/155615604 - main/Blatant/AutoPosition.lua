local AutoPosition
local Position
local Movement
local Delay
local dir = 0
local moveAccum = 0
local didClick = {}

AutoPosition = vape.Categories.Blatant:CreateModule({
	Name = 'AutoPosition',
	Function = function(callback)
		if callback then
			dir = 0
			moveAccum = 0

			AutoPosition:Clean(runService.Heartbeat:Connect(function(dt)
				if Position.Value ~= 'CopCars' or not entitylib.isAlive then
					return
				end

				local root = entitylib.character.RootPart
				local didMove

				for _, button in workspace.Prison_ITEMS.buttons:GetChildren() do
					if button.Name == 'Car Spawner' then
						local mag = (button['Car Spawner'].Position - root.Position).Magnitude
						if mag < 15 and (didClick[button] or 0) < os.clock() then
							didClick[button] = os.clock() + 0.2
							task.spawn(function()
								replicatedStorage.Remotes.InteractWithItem:InvokeServer(button['Car Spawner'])
							end)
						end

						if mag < 50 and button['Car Spawner'].BrickColor == BrickColor.new('Cyan') and not didMove then
							local diff = math.clamp((button['Car Spawner'].Position - root.Position).X, -1, 1)
							dir = math.clamp(dir + (diff * dt * 24), -12, 14)
							didMove = true
						end
					end
				end

				if not didMove then
					local diff = math.clamp(0 - dir, -1, 1)
					dir = math.clamp(dir + (diff * dt * 24), -12, 14)
				end

				if Movement.Enabled then
					moveAccum += dt

					if Delay.Value <= 0 or moveAccum >= Delay.Value then
						moveAccum = 0

						if (root.Position - Vector3.new(633, 98, 2489)).Magnitude < 40 or (os.clock() - entitylib.character.SpawnTime) < 2 then
							root.CFrame = CFrame.new(Vector3.new(610 + dir, 90, 2494))
							root.AssemblyLinearVelocity = Vector3.new(24, 0, 0)
						end
					end
				end
			end))
		else
			table.clear(didClick)
		end
	end,
	Tooltip = 'Automatically positions you to prime HvH spots'
})
Position = AutoPosition:CreateDropdown({
	Name = 'Position',
	List = {'CopCars'}
})
Movement = AutoPosition:CreateToggle({
	Name = 'Movement',
	Default = true
})
Delay = AutoPosition:CreateSlider({
	Name = 'Delay',
	Min = 0,
	Max = 10,
	Default = 0,
	Decimal = 10,
	Suffix = 's',
	Tooltip = 'Time between movement repositions, 0 keeps the sweep going constantly.'
})
