local HitSound
local Value
local Folder
local Volume
local PitchShift
local soundFolder = 'hacksensev2/sounds'
local audioTypes = {flac = true, m4a = true, mp3 = true, ogg = true, wav = true}
local sounds, folderSounds = {}, {}

if not isfolder(soundFolder) then
	makefolder(soundFolder)
end

local function listFolder()
	local files = {}
	if not isfolder(soundFolder) then
		return files
	end
	for _, path in listfiles(soundFolder) do
		local name = string.match(path, '[^/\\]+$')
		if name and audioTypes[string.match(string.lower(name), '%.([a-z0-9]+)$') or ''] then
			files[#files + 1] = name
		end
	end
	table.sort(files)
	return files
end

local function refreshFolder()
	local changed = false
	for _, name in listFolder() do
		if not table.find(Folder.List, name) then
			table.insert(Folder.List, name)
			table.insert(Folder.ListEnabled, name)
			changed = true
		end
	end
	if changed then
		Folder:ChangeValue()
	end
end

HitSound = vape.Legit:CreateModule({
	Name = 'HitSound',
	Function = function(callback)
		if callback then
			refreshFolder()
			local played
			TracerHook:Add('HitSound', function(...)
				local part = debug.getstack(4, 17)
				if typeof(part) == 'Instance' then
					for _, v in entitylib.List do
						if part:IsDescendantOf(v.Character) and entitylib.isVulnerable(v, true) then
							local pool = table.clone(sounds)
							table.move(folderSounds, 1, #folderSounds, #pool + 1, pool)
							if #pool > 0 and not played then
								local sound = Instance.new('Sound')
								sound.SoundId = pool[math.random(1, #pool)]
								sound.PlayOnRemove = true
								sound.PlaybackSpeed = PitchShift.Enabled and 1 + ((0.5 - math.random()) / 10) or 1
								sound.Volume = Volume.Value
								sound.Parent = workspace
								sound:Destroy()

								played = task.defer(function()
									played = nil
								end)
							end

							break
						end
					end
				end
			end)
		else
			TracerHook:Remove('HitSound')
		end
	end,
	Tooltip = 'Custom hit sound'
})
Value = HitSound:CreateTextList({
	Name = 'Sounds',
	Placeholder = 'sound id (roblox or file path)',
	Function = function(list)
		table.clear(sounds)
		for index, sound in list or {} do
			sounds[index] = sound:find('rbxasset') and sound or isfile(sound) and getcustomasset(sound) or nil
		end
	end
})
Folder = HitSound:CreateTextList({
	Name = 'Folder',
	Placeholder = 'file name in hacksensev2/sounds',
	Function = function()
		table.clear(folderSounds)
		for _, name in Folder.ListEnabled do
			local path = soundFolder..'/'..name
			if isfile(path) then
				folderSounds[#folderSounds + 1] = getcustomasset(path)
			end
		end
	end
})
refreshFolder()
Volume = HitSound:CreateSlider({
	Name = 'Volume',
	Min = 0,
	Max = 2,
	Default = 1,
	Decimal = 10
})
PitchShift = HitSound:CreateToggle({
	Name = 'Pitch Shift'
})
