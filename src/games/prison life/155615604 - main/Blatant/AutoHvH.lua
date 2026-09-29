local AutoHvH
local hvhSnapshot

local hvhTargets = {'AutoPosition', 'Invisible', 'Phase', 'Fly'}

AutoHvH = vape.Categories.Blatant:CreateModule({
	Name = 'AutoHvH',
	Function = function(callback)
		if callback then
			hvhSnapshot = {}

			for _, name in hvhTargets do
				local target = vape.Modules[name]

				if target then
					hvhSnapshot[name] = target.Enabled

					if not target.Enabled then
						target:Toggle()
					end
				end
			end

			notif('AutoHvH', 'AutoHvH enabled resetting...', 5)

			if entitylib.isAlive then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
			end
		elseif hvhSnapshot then
			for _, name in hvhTargets do
				local target = vape.Modules[name]

				if target and target.Enabled and hvhSnapshot[name] == false then
					target:Toggle()
				end
			end

			hvhSnapshot = nil
		end
	end,
	Tooltip = 'Toggles AutoPosition, Invisible, Phase and Fly, then resets you into the position.'
})
