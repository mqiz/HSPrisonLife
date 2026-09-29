local DeathTP
local deathCf

local function watchCharacter(char)
	local hum = char:WaitForChild('Humanoid', 5)

	if hum then
		DeathTP:Clean(hum.Died:Connect(function()
			local root = char:FindFirstChild('HumanoidRootPart')

			if root then
				deathCf = root.CFrame
			end
		end))
	end
end

DeathTP = vape.Categories.Blatant:CreateModule({
	Name = 'DeathTP',
	Function = function(callback)
		if callback then
			deathCf = nil

			if lplr.Character then
				watchCharacter(lplr.Character)
			end

			DeathTP:Clean(lplr.CharacterAdded:Connect(watchCharacter))

			DeathTP:Clean(lplr.CharacterAdded:Connect(function(char)
				local root = char:WaitForChild('HumanoidRootPart', 5)

				if root and deathCf and DeathTP.Enabled then
					task.wait(0.25)

					if DeathTP.Enabled and deathCf and root.Parent then
						root.CFrame = deathCf
					end
				end
			end))
		else
			deathCf = nil
		end
	end,
	Tooltip = 'Tps you back to where you died'
})
