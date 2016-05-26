

# my_ffmpeg_utils

Some scripts for GIF generation/manipulation with `ffmpeg`, `gifsicle` (and more to follow).

[Video to GIF with linux and mac](#ffmpeg_vid2gifsh-linux--mac-)  
[Video to GIF with windows](#video2gifbat-windows)  

----------
## Create gifs from video ##
The following two scripts are basically [this blog entry](http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html) in script form.
### ffmpeg_vid2gif.sh (linux / mac ?) ###

    # ffmpeg_vid2gif.sh --help
    
    USAGE: ffmpeg_vid2gif.sh sourceVideo destinationGif [--fps FPS] [ --size WIDTH:HEIGHT] [--at SECONDS] [--runtime SECONDS] [--dither none|bayer|floyd_steinberg|sierra2|sierra2_4a] [--mode full|diff] [--onestep] [--gifsicle]
    
    -f --fps                       Set the fps. (Default: 15)
    -s --size                      Set the size like WIDTH:HEIGHT. -1 can be used to keep the ratio. (Default: 640:-1)
    -a --at                        Where to  begin in the video in seconds or ffmpeg supported time format. (Default: 0)
    -r --runtime                   Duration in seconds or ffmpeg supported time format. (Default: Till end)
    -d --dither                    Dithering mode to use. One of (none|bayer|floyd_steinberg|sierra2|sierra2_4a) (Default: sierra2)
    -b --bayer-scale               If dither=bayer select the pattern size in the range of 0 - 5. Lower values tend to produce less artefacts but larger images. (DISCLAIMER: i have no clue about such stuff) (Default: 2)
    -m --mode                      'diff' or 'full'. 'diff' optimize the colors of moving objects at the cost of the background quality.  (Default: full)
    -v --verbose                   One of (quiet|fatal|error|warning|info|verbose) (Default: quiet)
    -o --onestep                   Do not generate palette before. Tend to produce worse, but way smaller gifs. Ignores dithering parameter. (Default: Not set)
    -g --gifsicle                  Use gifsicle afterwards to ensure valid gifs.'. (Default: Not set)

###video2gif.bat (windows)###
Basically the above script in interactive form.  
To use it download `ffmpeg`and extract it. Download [the batch script](https://github.com/SleepProgger/my_ffmpeg_utils/raw/master/video2gif.bat) and save it in the same folder as ffmpeg. Call it  `video2gif.bat`.  
If you want to burn subtitles also create an folder called `fonts` and save [this config] (https://github.com/SleepProgger/my_ffmpeg_utils/raw/master/fonts/fonts.conf) in it.
To run it double click the `video2gif.bat` and follow the instructions.  
*This script is not supported by me as i don't have a windows install at the moment.*

