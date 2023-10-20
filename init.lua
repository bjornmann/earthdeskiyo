local http = require("hs.http")
local json = require("hs.json")
local osascript = require("hs.osascript")
local projectPath = os.getenv("HOME") .. '/github/earthdeskiyo'
-- Function to fetch and store JSON data from the URL
function FetchAndStoreData()
    local jsonURL = "https://earthview.withgoogle.com/_api/photos.json"
    local response, status = http.get(jsonURL)
    if status == 200 then
        local data = json.decode(response)
        local file = io.open(projectPath .. "/photoData.json", "w")
        if (file ~= nil) then
            file:write(json.encode(data, true))
            file:close()
            return data
        end
        return nil
    else
        print("Failed to retrieve JSON data. Status code: " .. status)
        return nil
    end
end

-- Function to download and save an image from a URL while overwriting an existing image file
function DownloadAndSaveImage(url)
    local status, response = http.get(url)
    if status == 200 then
        local file = io.open(projectPath .. "/input.jpg", "wb")
        if (file ~= nil) then
            file:write(response)
            file:close()
            AddOverlaysToImage()
            SetDesktopWallpaper()
        end
        return nil
    else
        print("Failed to download the image.")
    end
end

function EmptyDirectory(path)
    for file in hs.fs.dir(path) do
        if (file ~= '.') and (file ~= '..') and (file ~= '.DS_Store') then
            print(path .. '/' .. file)
            os.remove(path .. '/' .. file)
        else
            print('skipped')
        end
    end
end

-- Function to select a random entry from the stored data
function SelectRandomEntry(data)
    if data then
        return data[math.random(#data)]
    else
        return nil
    end
end

-- Function to extract numbers from a slug
function ExtractNumbersFromSlug(slug)
    local numbers = slug:match("(%d+)$")
    if numbers then
        print("Extracted numbers: " .. numbers)
        return numbers
    else
        print("No numbers found at the end of the string.")
    end
end

function AddOverlaysToImage()
    local compositePath = '/opt/homebrew/bin/composite'
    local output = projectPath .. '/background.jpg'
    local addFlag = string.format(
        "%s -geometry +100+100 %s %s %s",
        compositePath,
        projectPath .. '/logo.png',
        projectPath .. '/input.jpg',
        output)
    os.execute(addFlag)
end

-- Function to set the desktop wallpaper using AppleScript
function SetDesktopWallpaper()
    local applescript =
        'tell application "System Events" to set picture of every desktop to "' .. projectPath .. '/background.jpg"'
    osascript.applescript(applescript)
end

-- Main function
function Main()
    local data = {}
    local file, errorMessage

    -- Attempt to read data from the local "photoData.json" file
    file, errorMessage = io.open(projectPath .. "/photoData.json", "r")

    if file then
        data = json.decode(file:read("*a"))
        file:close()
    else
        -- If the file doesn't exist, fetch and store data from the URL
        print('fetching remote file')
        data = FetchAndStoreData()
    end

    -- Select a random entry
    local randomEntry = SelectRandomEntry(data)
    if randomEntry then
        local slug = randomEntry.slug
        local earthviewURL = "https://earthview.withgoogle.com/" .. slug
        local imageId = ExtractNumbersFromSlug(slug)
        local imageURL = "https://www.gstatic.com/prettyearth/assets/full/" .. imageId .. ".jpg"
        print("Random EarthView URL: " .. imageURL)

        -- Download and save the image, overwriting the existing image file
        DownloadAndSaveImage(imageURL)
    else
        print("No data available.")
    end
end

Main()
timer = hs.timer.new(30 * 60, Main)
timer:start()
