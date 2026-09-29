local Resolver
local oldBullet
local targetEntity
local targetSince
local pending
local lastNoTarget = 0
local confirmWindow = 1

local function getCrosshairTarget()
	if not entitylib.isAlive then
		return
	end

	return entitylib.EntityMouse({
		Range = 60,
		Part = 'RootPart',
		Players = true,
		NPCs = false
	})
end

local function onBullet(...)
	local tool = lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool')

	if tool and tool:GetAttribute('FireRate') and tool.Name ~= 'Taser' then
		if targetEntity and targetEntity.Humanoid and targetEntity.Humanoid.Health > 0 then
			if pending == nil or pending.Entity ~= targetEntity then
				pending = {
					Entity = targetEntity,
					Name = targetEntity.Player and targetEntity.Player.Name or 'NPC',
					Duration = targetSince and (os.clock() - targetSince) or 0,
					Health = targetEntity.Humanoid.Health,
					Deadline = os.clock() + confirmWindow
				}
			else
				pending.Deadline = os.clock() + confirmWindow
			end
		elseif os.clock() - lastNoTarget > 0.5 then
			notif('Resolver', 'Failed to resolve : no target found!', 3)
			lastNoTarget = os.clock()
		end
	end

	return oldBullet(...)
end

Resolver = vape.Categories.Combat:CreateModule({
	Name = 'Resolver',
	Function = function(callback)
		if callback then
			targetEntity = nil
			targetSince = nil
			pending = nil

			Resolver:Clean(runService.RenderStepped:Connect(function()
				local ent = getCrosshairTarget()

				if ent ~= targetEntity then
					targetEntity = ent
					targetSince = ent and os.clock() or nil
				end
			end))

			Resolver:Clean(runService.Heartbeat:Connect(function()
				if pending then
					local hum = pending.Entity and pending.Entity.Humanoid
					local health = hum and hum.Health

					if health and health < pending.Health then
						notif('Resolver', 'successfully resolved '..pending.Name..' in '..string.format('%.1f', pending.Duration)..'s!', 5)
						pending = nil
					elseif not health or os.clock() > pending.Deadline then
						notif('Resolver', 'Failed to resolve '..pending.Name..'!', 3)
						pending = nil
					end
				end
			end))

			task.spawn(function()
				local start = os.clock()

				while Resolver.Enabled and not (pl and pl.Bullet) and (os.clock() - start) < 5 do
					task.wait(0.1)
				end

				if Resolver.Enabled and pl and pl.Bullet and not oldBullet then
					oldBullet = hookfunction(pl.Bullet, onBullet)
				end
			end)
		else
			if oldBullet then
				if restorefunction then
					restorefunction(pl.Bullet)
				else
					hookfunction(pl.Bullet, oldBullet)
				end

				oldBullet = nil
			end

			targetEntity = nil
			targetSince = nil
			pending = nil
		end
	end,
	Tooltip = 'attempts to resolve your bullets for better hitreg'
})
