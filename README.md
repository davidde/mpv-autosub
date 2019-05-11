# Automatic subtitle downloading for the MPV mediaplayer
## Usage
1. This Lua script uses the Python program [subliminal](https://github.com/Diaoul/subliminal) to download subtitles. Make sure you have it installed:  
`pip install subliminal`
2. Copy this autosub.lua script into **~/.config/mpv/scripts/**:
   ```shell
   mkdir ~/.config/mpv/scripts
   cat > ~/.config/mpv/scripts/autosub.lua
   [Paste script contents]
   [CTRL+D]
   ```
3. Enjoy automatically downloaded subtitles the next time you open MPV!

## Docs
If you wish to modify or adapt this script to your needs,
be sure to check out the [MPV Lua API](https://mpv.io/manual/stable/#lua-scripting).

## Credits
Inspired by [selsta's](https://gist.github.com/selsta/ce3fb37e775dbd15c698) and
[fullmetalsheep's](https://gist.github.com/fullmetalsheep/28c397b200a7348027d983f31a7eddfa) autosub scripts.
