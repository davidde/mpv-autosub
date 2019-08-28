--_____________________________________________________________________________
--=============================================================================
--
--                         CONFIGURATION SETTINGS
--_____________________________________________________________________________
--=============================================================================
-->>    SUBLIMINAL PATH
--=============================================================================
--          This script uses Subliminal to download subtitles,
--          so make sure to specify your system's Subliminal location below:
local subliminal = '/opt/anaconda3/bin/subliminal'
--=============================================================================
-->>    SUBTITLE LANGUAGE
--=============================================================================
--          Specify languages in this order:
--          { 'language name', 'ISO-639-1', 'ISO-639-2' } !
--          (See: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
local languages = {
--          If subtitles are found for the first language,
--          other languages will NOT be downloaded,
--          so put your preferred language first:
            { 'English', 'en', 'eng' },
            { 'Dutch', 'nl', 'dut' },
--          { 'Spanish', 'es', 'spa' },
--          { 'French', 'fr', 'fre' },
--          { 'German', 'de', 'ger' },
--          { 'Italian', 'it', 'ita' },
--          { 'Portuguese', 'pt', 'por' },
--          { 'Polish', 'pl', 'pol' },
--          { 'Russian', 'ru', 'rus' },
--          { 'Chinese', 'zh', 'chi' },
--          { 'Arabic', 'ar', 'ara' },
}
--=============================================================================
-->>    PROVIDER LOGINS
--=============================================================================
--          These are completely optional and not required
--          for the functioning of the script!
--          If you use any of these services, simply uncomment it
--          and replace 'USERNAME' and 'PASSWORD' with your own:
local logins = {
--          { '--addic7ed', 'USERNAME', 'PASSWORD' },
--          { '--legendastv', 'USERNAME', 'PASSWORD' },
--          { '--opensubtitles', 'USERNAME', 'PASSWORD' },
--          { '--subscenter', 'USERNAME', 'PASSWORD' },
}
--=============================================================================
-->>    ADDITIONAL OPTIONS
--=============================================================================
local bools = {
    auto = true,  -- Automatically download subtitles, no hotkeys required
    debug = true, -- Use `--debug` in subliminal command for debug output
    force = true, -- Force download; will overwrite existing subtitle files
    utf8 = true,  -- Save all subtitle files as UTF-8
}
--_____________________________________________________________________________
--=============================================================================
local utils = require 'mp.utils'


-- Download function: download the best subtitles in most preferred language
function download_subs(language)
    language = language or languages[1]
    log('Searching ' .. language[1] .. ' subtitles ...', 30)
    local directory, filename = utils.split_path(mp.get_property('path'))

    -- Start building the `subliminal` command, starting with the executable:
    local table = { args = { subliminal } }
    local a = table.args

    for _, login in ipairs(logins) do
        a[#a + 1] = login[1]
        a[#a + 1] = login[2]
        a[#a + 1] = login[3]
    end
    if bools.debug then
        -- To see `--debug` output start MPV from the terminal!
        a[#a + 1] = '--debug'
    end

    a[#a + 1] = 'download'
    if bools.force then
        a[#a + 1] = '-f'
    end
    if bools.utf8 then
        a[#a + 1] = '-e'
        a[#a + 1] = 'utf-8'
    end

    a[#a + 1] = '-l'
    a[#a + 1] = language[2]
    a[#a + 1] = '-d'
    a[#a + 1] = directory
    a[#a + 1] = filename --> Subliminal command ends with the movie filename.

    local result = utils.subprocess(table)

    if string.find(result.stdout, 'Downloaded 1 subtitle') then
        -- When multiple external files are present,
        -- always activate the most recently downloaded:
        mp.set_property('slang', language[2])
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
    -- Make MPV accept external subtitle files with language specifier:
    mp.set_property('sub-auto', 'fuzzy')
    -- Set subtitle language preference:
    mp.set_property('slang', languages[1][2])
    mp.msg.warn('Reactivate external subtitle files:')
    mp.commandv('rescan_external_files')

    if not bools.auto then
        mp.msg.warn('Automatic downloading disabled!')
        return
    end

    local duration = tonumber(mp.get_property('duration'))
    if duration < 900 then
        mp.msg.warn('Video is less than 15 minutes\n' ..
                    '=> NOT downloading any subtitles')
        return
    end

    local track_list = mp.get_property_native('track-list')
    -- mp.msg.warn('track_list = ', mp.get_property('track-list'), '\n')
    for _, language in ipairs(languages) do
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

-- Check if new subtitles should be downloaded in this language:
function should_download_subs_in(language, track_list)
    for _, track in ipairs(track_list) do
        if track['type'] == 'sub' then
            if track['external'] == false then
                if embedded_subs_in(language, track) then
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
function embedded_subs_in(language, track)
    if track['lang'] == language[3] or track['lang'] == language[2]
        or (track['title'] and track['title']:lower():find(language[3])) then
            mp.msg.warn('Embedded ' .. language[1] .. ' subtitles are present')
            mp.msg.warn('=> NOT downloading new subtitles')
            sleep(1.5) -- Do not overwrite potential previous OSD message
            if not track['selected'] then
                mp.set_property('sid', track['id'])
                log('Enabled embedded ' .. language[1] .. ' subtitles!')
            else
                log('Embedded ' .. language[1] .. ' subtitles are active')
            end
            return true -- The right embedded subtitles are already present
    end
end

-- Check if external subtitle file is present in the right language:
function external_subs_in(language, track)
    local video_name = mp.get_property('filename/no-ext')
    local sub_name = track['title']:sub(1, -5)
    local lang = sub_name:sub(video_name:len() + 2)
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
            sleep(1.5) -- Do not overwrite potential previous OSD message
            log('Enabled external ' .. language[1] .. ' subtitle file!')
        end
        return true -- The right external subtitle file is already present
    end
end

-- Log function: log to both terminal and MPV OSD (On-Screen Display)
function log(string, secs)
    secs = secs or 2.5  -- secs defaults to 2.5 when secs parameter is absent
    mp.msg.warn(string)          -- This logs to the terminal
    mp.osd_message(string, secs) -- This logs to MPV screen
end

-- Sleep function: give the MPV OSD messages time to be read
-- before being overwritten by the next message
function sleep(s)
    local ntime = os.time() + s
    repeat until os.time() > ntime
end


mp.add_key_binding('b', 'download_subs', download_subs)
mp.add_key_binding('n', 'download_subs2', download_subs2)
mp.register_event('file-loaded', control_downloads)
