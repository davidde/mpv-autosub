-- Requires Subliminal version 1.0 or newer
-- Make sure to specify your system's Subliminal location below:
subliminal = '/opt/anaconda3/bin/subliminal'
-- Specify language in this order: full name, ISO-639-1, ISO-639-2!
-- (See: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
language = { 'English', 'en', 'eng' }
local utils = require 'mp.utils'

-- Log function: log to both terminal and mpv OSD (On-Screen Display)
function log(string, secs)
    secs = secs or 2     -- secs defaults to 2 when the secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to mpv screen
end

function download_subs()
    log('Searching subtitles ...', 10)

    directory, filename = utils.split_path(mp.get_property('path'))
    table = {
        args = { -- To see --debug output start mpv from terminal!
            subliminal, '--debug', 'download', '-s', '-f',
            '-l', language[2], '-d', directory, filename
        }
    }
    result = utils.subprocess(table)

    if string.find(result.stdout, 'Downloaded 1 subtitle') then
        -- Subtitles are downloaded successfully, so rescan to activate them:
        mp.commandv('rescan_external_files')
        log('Subtitles ready!')
    else
        log('No subtitles were found')
    end
end

-- Control function: only download if necessary
function control_download()
    duration = tonumber(mp.get_property('duration'))
    if duration < 900 then
        mp.msg.warn('Video is less than 15 minutes\n' ..
                    '=> NOT downloading any subtitles')
        return
    end
    track_list = mp.get_property_native('track-list')
    -- mp.msg.warn('track_list = ', mp.get_property('track-list'), '\n')
    for i, track in pairs(track_list) do
        if track['type'] == 'sub' then
            if track['lang'] == language[3] or track['lang'] == language[2] then
                mp.msg.warn('Embedded ' .. language[1] ..
                            ' subtitles are already present:\n' ..
                            '=> NOT downloading new subtitles')
                if not track['selected'] then
                    mp.msg.warn('=> Enabling embedded ' .. language[1] .. ' subtitles')
                    mp.set_property('sid', track['id'])
                end
                return
            elseif track['external'] == true then
                mp.msg.warn('A matching external subtitle file is present\n' ..
                            '=> NOT downloading other subtitles')
                return
            end
        end
    end
    mp.msg.warn('No ' .. language[1] .. ' subtitles were detected\n' ..
                '=> Proceeding to download:')
    download_subs()
end

mp.register_event('file-loaded', control_download)
mp.add_key_binding('b', 'download_subs', download_subs)

