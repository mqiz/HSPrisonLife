local isfile = isfile or function(file)
        local suc, res = pcall(function()
                return readfile(file)
        end)
        return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
        writefile(file, '')
end

local function downloadFile(path, func)
        if not isfile(path) then
                local suc, res = pcall(function()
                        return game:HttpGet('https://raw.githubusercontent.com/mqiz/HSPrisonLife/'..readfile('hacksensev2/profiles/commit.txt')..'/'..select(1, path:gsub('hacksensev2/', '')), true)
                end)
                if not suc or res == '404: Not Found' then
                        error(res)
                end
                writefile(path, res)
        end
        return (func or readfile)(path)
end

local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
                if file:find('loader') then continue end
                if isfile(file) then
                        delfile(file)
                end
        end
end

for _, folder in {'hacksensev2', 'hacksensev2/games', 'hacksensev2/profiles', 'hacksensev2/sounds', 'hacksensev2/assets', 'hacksensev2/libraries', 'hacksensev2/guis'} do
        if not isfolder(folder) then
                makefolder(folder)
        end
end

if not shared.VapeDeveloper then
        local _, subbed = pcall(function()
                return game:HttpGet('https://github.com/mqiz/HSPrisonLife')
        end)

        local assetVer = '3'
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'

        if commit == 'main' or (isfile('hacksensev2/profiles/commit.txt') and readfile('hacksensev2/profiles/commit.txt') or '') ~= commit then
                wipeFolder('hacksensev2')
                wipeFolder('hacksensev2/games')
                wipeFolder('hacksensev2/guis')
                wipeFolder('hacksensev2/libraries')
        end

        if (isfile('hacksensev2/profiles/asset.txt') and readfile('hacksensev2/profiles/asset.txt') or '') ~= assetVer then
                wipeFolder('hacksensev2/assets')
        end

        writefile('hacksensev2/profiles/asset.txt', assetVer)
        writefile('hacksensev2/profiles/commit.txt', commit)
end

return loadstring(downloadFile('hacksensev2/main.lua'), 'main')()