# Automatic subtitle downloading for the MPV mediaplayer
## Setup
1. This Lua script uses the Python program [subliminal](https://github.com/Diaoul/subliminal) to download subtitles.
   Make sure you have it installed:  
   ```
   pip install subliminal
   ```
2. Copy autosub.lua into **~/.config/mpv/scripts/**:
   ```
   mkdir ~/.config/mpv/scripts
   cat > ~/.config/mpv/scripts/autosub.lua
   [Paste script contents]
   [CTRL+D]
   ```
3. Customize the script with your system's subliminal location:  
   - To determine the correct path, use:  
     ```
     which subliminal
     ```  
   - Copy this path to the subliminal variable on line 3 of your script:  
     ```
     vi ~/.config/mpv/scripts/autosub.lua
     [Modify line 3: subliminal = "/path/to/your/subliminal"]
     [Use `i` to modify, then `CTRL+SHIFT+V` to paste inside vi]
     [Use `ESC`, then `:wq` to write the changes and exit]
     ```
4. Optionally change the subtitle language / [ISO codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) on line 6.
5. Enjoy automatically downloaded subtitles the next time you open MPV!  
   (If necessary, you can manually trigger the download by pressing `b`.)

## Docs
If you wish to modify or adapt this script to your needs,
be sure to check out the [MPV Lua API](https://mpv.io/manual/stable/#lua-scripting).

## Credits
Inspired by [selsta's](https://gist.github.com/selsta/ce3fb37e775dbd15c698) and
[fullmetalsheep's](https://gist.github.com/fullmetalsheep/28c397b200a7348027d983f31a7eddfa) autosub scripts.
