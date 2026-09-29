local SongBeats
local List
local Folder
local FOV
local FOVValue = {}
local Volume
local soundFolder = 'hacksensev2/sounds'
local audioTypes = {flac = true, m4a = true, mp3 = true, ogg = true, wav = true}
local alreadypicked = {}
local beattick = os.clock()
local oldfov, songobj, songbpm, songtween

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

local function choosesong()
	local combined = {}
	for _, v in List.ListEnabled do
		combined[#combined + 1] = v
	end
	for _, v in Folder.ListEnabled do
		local path = soundFolder..'/'..v
		if isfile(path) and not table.find(combined, path) then
			combined[#combined + 1] = path
		end
	end
	if #alreadypicked >= #combined then
		table.clear(alreadypicked)
	end

	if #combined <= 0 then
		notif('SongBeats', 'no songs', 10)
		SongBeats:Toggle()
		return
	end

	local chosensong = combined[math.random(1, #combined)]
	if #combined > 1 and table.find(alreadypicked, chosensong) then
		repeat
			task.wait()
			chosensong = combined[math.random(1, #combined)]
		until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
	end
	if not SongBeats.Enabled then return end

	local songpath, bpmvalue, startvalue = chosensong, nil, nil
	if not isfile(chosensong) then
		local split = chosensong:split('/')
		songpath = split[1]
		bpmvalue = tonumber(split[2])
		startvalue = tonumber(split[3])
	end

	if not isfile(songpath) then
		notif('SongBeats', 'Missing song ('..songpath..')', 10)
		SongBeats:Toggle()
		return
	end

	songobj.SoundId = getcustomasset(songpath)
	repeat
		task.wait()
	until songobj.IsLoaded or not SongBeats.Enabled

	if SongBeats.Enabled then
		beattick = os.clock() + (startvalue or 0)
		songbpm = 60 / (bpmvalue or 50)
		songobj:Play()
	end
end

SongBeats = vape.Legit:CreateModule({
	Name = 'Song Beats',
	Function = function(callback)
		if callback then
			refreshFolder()
			songobj = Instance.new('Sound')
			songobj.Volume = Volume.Value / 100
			songobj.Parent = workspace
			SongBeats:Clean(songobj)
			oldfov = gameCamera.FieldOfView

			repeat
				if not songobj.Playing then
					choosesong()
				end

				if beattick < os.clock() and SongBeats.Enabled and FOV.Enabled then
					beattick = os.clock() + songbpm
					if songtween then
						songtween:Cancel()
					end

					gameCamera.FieldOfView = oldfov - FOVValue.Value
					songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {
						FieldOfView = oldfov
					})

					songtween:Play()
				end

				task.wait()
			until not SongBeats.Enabled
		else
			if songtween then
				songtween:Cancel()
			end

			if oldfov then
				gameCamera.FieldOfView = oldfov
			end

			table.clear(alreadypicked)
		end
	end,
	Tooltip = 'Built in mp3 player'
})
List = SongBeats:CreateTextList({
	Name = 'Songs',
	Placeholder = 'filepath/bpm/start'
})
Folder = SongBeats:CreateTextList({
	Name = 'Folder',
	Placeholder = 'file name in hacksensev2/sounds'
})
refreshFolder()
FOV = SongBeats:CreateToggle({
	Name = 'Beat FOV',
	Function = function(callback)
		if FOVValue.Object then
			FOVValue.Object.Visible = callback
		end

		if SongBeats.Enabled then
			SongBeats:Toggle()
			SongBeats:Toggle()
		end
	end,
	Default = true
})
FOVValue = SongBeats:CreateSlider({
	Name = 'Adjustment',
	Min = 1,
	Max = 30,
	Default = 5,
	Darker = true
})
Volume = SongBeats:CreateSlider({
	Name = 'Volume',
	Function = function(val)
		if songobj then
			songobj.Volume = val / 100
		end
	end,
	Min = 1,
	Max = 100,
	Default = 100,
	Suffix = '%'
})
