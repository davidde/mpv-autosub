-- Requires Subliminal version 1.0 or newer
-- Make sure to specify your system's Subliminal location below:
subliminal = '/opt/anaconda3/bin/subliminal'
language = 'en'
local utils = require 'mp.utils'

-- Log function: log to both terminal and mpv OSD (On-Screen Display)
function log(string, secs)
    secs = secs or 2     -- secs defaults to 2 when the secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to mpv screen
end

function download_subs()
    log('Searching subtitles ...', 10)

    path = mp.get_property('path')
    filename = mp.get_property('filename')
    save_dir = string.sub(path, 0, string.len(path) - string.len(filename))

    table = { args = {subliminal, 'download', '-s', '-l', language, '-d', save_dir, filename} }
    result = utils.subprocess(table)

    if string.find(result.stdout, 'Downloaded 1 subtitle') then
        -- Subtitles are downloaded successfully, so rescan to activate them:
        mp.commandv('rescan_external_files') 
        log('Subtitles ready!')
    else
        log('Subtitles failed downloading')
    end
end

-- Control function: only download if necessary
function control_download()
    duration = tonumber(mp.get_property('duration'))
    if duration < 900 then
        mp.msg.warn('Video is less than 15 minutes\n', '=> NOT downloading any subtitles')
        return
    end
    -- There does not seem to be any documentation for the 'sub' property,
    -- but it works on both internally encoded as well as external subtitle files!
    -- -> sub = '1' when subtitles are present
    -- -> sub = 'no' when subtitles are not present
    -- -> sub = 'auto' when called before the 'file-loaded' event is triggered
    sub = mp.get_property('sub')
    if sub == '1' then
        mp.msg.warn('Sub track is already present\n', '=> NOT downloading other subtitles')
        return
    end
    mp.msg.warn('No sub track was detected\n', '=> Proceeding to download subtitles:')
    download_subs()
end

mp.register_event('file-loaded', control_download)
mp.add_key_binding("b", "download_subs", download_subs)

