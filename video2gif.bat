@ECHO OFF
Setlocal EnableDelayedExpansion
REM For general infos see http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
REM Set the path here if your ffmpeg executable is somewhere else as in the current directory
SET ffmpeg_path=ffmpeg.exe
SET palette=palette.png

if not exist "%ffmpeg_path%" echo "Can't find ffmpeg.exe" & goto done

SET /P src=Video to convert (you can drag and drop the file): 
if not exist %src% echo "Can't find the video file" & goto done
SET /P start_time=Startime (ss, mm:ss, and hh:mm:ss formats are supported): 
SET /P duration=Duration in seconds: 
SET /P dest=Name and path for the gif [test.gif]: 
if "%dest%" == "" (
	SET dest=test.gif
)
SET /P size=Size [320:-1]("width:height" format. if one is -1 the aspect ratio will be the same): 
if "%size%" == "" (
	SET size=320:-1
)
SET /P fps=FPS [15]: 
if "%fps%" == "" (
	SET fps=15
)
SET stats_mode=full
SET dithering=sierra2_4a

SET /P extended=Change dithering and palette settings ? [N]: 
if not "%extended%" == "Y" goto noextended
SET /P stats_mode=Prioritize moving objects [N]: 
if "%stats_mode%" == "Y" (
	SET stats_mode=diff
)
SET /P dithering=Dithering algo (f.e: none, sierra2_4a, floyd_steinberg, bayer(configurable) ) [sierra2_4a]: 
if "%dithering%" == "bayer" (
	SET /P bayer_scale=Bayer scale 1-5 [1]: 
	if "!bayer_scale!" == "" (
		SET bayer_scale=1
	)
	SET "dithering=bayer:bayer_scale=!bayer_scale!"
	
)
:noextended
SET filters=fps=%fps%,scale=%size%:flags=lanczos

echo.
echo Creating palette
"%ffmpeg_path%" -v warning -ss %start_time% -t %duration% -i %src% -vf "%filters%,palettegen=stats_mode=%stats_mode%" -y %palette% || echo Failed creating the palette (Invalid video file ?) && goto done
echo.
echo Creating GIF
"%ffmpeg_path%" -v warning -ss %start_time% -t %duration% -i %src% -i %palette% -lavfi "%filters% [x]; [x][1:v] paletteuse=dither=%dithering%" -y %dest% || echo Failed creating the gif && goto done

:done
pause
exit /b
