-- Requires Subliminal version 1.0 or newer
-- Make sure to specify your system's Subliminal location below:
subliminal = '/opt/anaconda3/bin/subliminal'
-- Specify languages in this order: { 'language name', 'ISO-639-1', 'ISO-639-2' } !
-- (See: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
languages = {
    -- If subtitles are found for the first language,
    -- other languages will NOT be downloaded,
    -- so put your preferred language first:
    { 'English', 'en', 'eng' },
    { 'Dutch', 'nl', 'dut' },
    { 'Polish', 'pl', 'pol' },
}
-- Optional provider login: e.g. { '--opensubtitles', 'USERNAME', 'PASSWORD' }
login = {}
local utils = require 'mp.utils'

-- Log function: log to both terminal and mpv OSD (On-Screen Display)
function log(string, secs)
    secs = secs or 2.5     -- secs defaults to 2.5 when the secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to mpv screen
end

-- Download function: download the best subtitles in most preferred language
function download_subs(language)
    language = language or languages[1]
    log('Searching ' .. language[1] .. ' subtitles ...', 30)

    directory, filename = utils.split_path(mp.get_property('path'))
    if login[1] then
        mp.msg.warn('Using ' .. login[1] .. ' login')
        table = {
            args = { -- To see --debug output start mpv from terminal!
                subliminal, login[1], login[2], login[3], '--debug', 'download',
                '-s', '-f', '-l', language[2], '-d', directory, filename
            }
        }
    else
        mp.msg.warn('Not using any provider login')
        table = {
            args = { -- To see --debug output start mpv from terminal!
                subliminal, '--debug', 'download', '-s', '-f',
                '-l', language[2], '-d', directory, filename
            }
        }
    end
    result = utils.subprocess(table)

    if string.find(result.stdout, 'Downloaded 1 subtitle') then
        -- Subtitles are downloaded successfully, so rescan to activate them:
        mp.commandv('rescan_external_files')
        log(language[1] .. ' subtitles ready!')
        return true
    else
        log('No ' .. language[1] .. ' subtitles found\n')
        return false
    end
end

-- Manually download second language subs by pressing 'n':
function download_subs2()
    download_subs(languages[2])
end

-- Control function: only download if necessary
function control_downloads()
    duration = tonumber(mp.get_property('duration'))
    if duration < 900 then
        mp.msg.warn('Video is less than 15 minutes\n' ..
                    '=> NOT downloading any subtitles')
        return
    end
    track_list = mp.get_property_native('track-list')
    -- mp.msg.warn('track_list = ', mp.get_property('track-list'), '\n')
    for _, language in pairs(languages) do
        if should_download_subs_in(language, track_list) then
            if download_subs(language) == true then
                return
            end
        else
            return
        end
    end
    log('No subtitles were found')
end

-- Check for subs already present (either embedded in video or external subtitle files):
function should_download_subs_in(language, track_list)
    for _, track in pairs(track_list) do
        if track['type'] == 'sub' then
            if track['lang'] == language[3] or track['lang'] == language[2]
                or (track['title'] and track['title']:lower():find(language[3])) then
                log('Embedded ' .. language[1] .. ' subtitles are present')
                mp.msg.warn('=> NOT downloading new subtitles')
                if not track['selected'] then
                    mp.msg.warn('=> Enabling embedded ' .. language[1] .. ' subtitles:')
                    mp.set_property('sid', track['id'])
                end
                return false
            elseif track['external'] == true then
                mp.msg.warn('A matching external subtitle file is present\n' ..
                            '=> NOT downloading other subtitles')
                return false
            end
        end
    end
    mp.msg.warn('No ' .. language[1] .. ' subtitles were detected\n' ..
                '=> Proceeding to download:')
    return true
end

mp.register_event('file-loaded', control_downloads)
mp.add_key_binding('b', 'download_subs', download_subs)
mp.add_key_binding('n', 'download_subs2', download_subs2)
