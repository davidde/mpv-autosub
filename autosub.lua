-- Requires Subliminal version 1.0 or newer
-- Make sure to specify your system's Subliminal location below:
local subliminal = '/opt/anaconda3/bin/subliminal'
-- Specify languages in this order:
-- { 'language name', 'ISO-639-1', 'ISO-639-2' } !
-- (See: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
local languages = {
    -- If subtitles are found for the first language,
    -- other languages will NOT be downloaded,
    -- so put your preferred language first:
    { 'English', 'en', 'eng' },
    { 'Dutch', 'nl', 'dut' },
    -- { 'Spanish', 'es', 'spa' },
    -- { 'French', 'fr', 'fre' },
    -- { 'German', 'de', 'ger' },
    -- { 'Italian', 'it', 'ita' },
    -- { 'Portuguese', 'pt', 'por' },
    -- { 'Polish', 'pl', 'pol' },
    -- { 'Russian', 'ru', 'rus' },
    -- { 'Chinese', 'zh', 'chi' },
    -- { 'Arabic', 'ar', 'ara' },
}
-- Optional provider login: e.g. { '--opensubtitles', 'USERNAME', 'PASSWORD' }
local login = {}
local utils = require 'mp.utils'

-- Log function: log to both terminal and mpv OSD (On-Screen Display)
function log(string, secs)
    secs = secs or 2.5  -- secs defaults to 2.5 when secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to mpv screen
end

-- Sleep function: give the mpv OSD messages time to be read
-- before being overwritten by the next message
function sleep(s)
    local ntime = os.time() + s
    repeat until os.time() > ntime
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
                subliminal, login[1], login[2], login[3], '--debug',
                'download', '-f', '-l', language[2], '-d', directory, filename
            }
        }
    else
        mp.msg.warn('Not using any provider login')
        table = {
            args = { -- To see --debug output start mpv from terminal!
                subliminal, '--debug', 'download', '-f',
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

    -- Make MPV accept external subtitle files with language specifier:
    mp.set_property('sub-auto', 'fuzzy')
    -- Set subtitle language preference:
    mp.set_property('slang', languages[1][2])
    mp.msg.warn('Reactivate external subtitle files:')
    mp.commandv('rescan_external_files')

    track_list = mp.get_property_native('track-list')
    -- mp.msg.warn('track_list = ', mp.get_property('track-list'), '\n')
    for i, language in ipairs(languages) do
        if should_download_subs_in(language, track_list, i) then
            if download_subs(language) == true then
                return
            end
        else
            return
        end
    end
    log('No subtitles were found')
end

-- Check for subs already present:
-- (either embedded in video or external subtitle files)
function should_download_subs_in(language, track_list, i)
    for _, track in ipairs(track_list) do
        if track['type'] == 'sub' then
            if track['external'] == false then
                if embedded_subs_in(language, track, i) then
                    return false
                end
            elseif external_subs_in(language, track) then
                return false
            end
        end
    end
    mp.msg.warn('No ' .. language[1] .. ' subtitles were detected\n' ..
                '=> Proceeding to download:')
    return true
end

-- Check if embedded subs are present in the right language:
function embedded_subs_in(language, track, i)
    if track['lang'] == language[3] or track['lang'] == language[2]
        or (track['title'] and track['title']:lower():find(language[3])) then
            mp.msg.warn('Embedded ' .. language[1] .. ' subtitles are present')
            mp.msg.warn('=> NOT downloading new subtitles')
            sleep(1.5) -- Do not overwrite potential previous OSD message
            if not track['selected'] then
                mp.set_property('sid', track['id'])
                log('Enabled embedded ' .. language[1] .. ' subtitles!')
            -- We don't need OSD notifs if the right subtitles
            -- are present from the start:
            elseif i ~= 1 then
                log(language[1] .. ' subtitles already active')
            end
            return true -- The right embedded subtitles are already present
    end
end

-- Check if external subtitle file is present in the right language:
function external_subs_in(language, track)
    video_name = mp.get_property('filename/no-ext')
    sub_name = track['title']:sub(1, -5)
    lang = sub_name:sub(video_name:len() + 2)
    if video_name == sub_name then
        mp.msg.warn('An exactly matching external ' ..
            'subtitle file of unknown language is present')
        mp.msg.warn('=> NOT downloading other subtitles')
        return true -- The right external subtitle file is already present
    elseif lang == language[2] then
        mp.msg.warn('A matching ' .. language[1] ..
            ' subtitle file is present')
        mp.msg.warn('=> NOT downloading other subtitles')
        if not track['selected'] then
            mp.set_property('sid', track['id'])
            log('Enabled external ' .. language[1] .. ' subtitle file!')
        end
        return true -- The right external subtitle file is already present
    end
end

mp.register_event('file-loaded', control_downloads)
mp.add_key_binding('b', 'download_subs', download_subs)
mp.add_key_binding('n', 'download_subs2', download_subs2)
