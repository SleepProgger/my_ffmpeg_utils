@ECHO OFF
REM Set the path here if your ffmpeg executable is somewhere else as in the current directory
SET ffmpeg_path=ffmpeg.exe
SET palette=palette.png

if not exist "%ffmpeg_path%" echo "Can't find ffmpeg.exe" & exit /b

SET /P src=Video to convert (you can drag and drop the file): 
if not exist %src% echo "Can't find the video file" & exit /b
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
SET /P stats_mode=Prioritize moving [N]: 
if "%stats_mode%" == "Y" (
	SET stats_mode=diff
) else (
	SET stats_mode=full
)

SET filters=fps=%fps%,scale=%size%:flags=lanczos

echo.
echo Creating palette
"%ffmpeg_path%" -v warning -ss %start_time% -t %duration% -i %src% -vf "%filters%,palettegen=stats_mode=%stats_mode%" -y %palette% || echo Failed creating the palette (Invalid video file ?) && exit /b
echo.
echo Creating GIF
"%ffmpeg_path%" -v warning -ss %start_time% -t %duration% -i %src% -i %palette% -lavfi "%filters% [x]; [x][1:v] paletteuse" -y %dest% || echo Failed creating the gif && exit /b
pause
