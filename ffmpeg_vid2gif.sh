#!/bin/sh

# See http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
# TODO: Check ffmpeg version
# TODO: subtitles
# TODO: check if video file exists

tmp_dir="/tmp/"
start=""
duration=""

# defaults
fps=15
size="640:-1"
mode="full"
dither="sierra2"
bayer_scale=2
# Am i missing something ? Why isn't this enabled by default ?
# It should be pretty nice for static backgrounds and don't really matter for everything else.
diff_mode="rectangle"
#diff_mode="none"

print_help() {
	printf "\n"
	printf "USAGE: $(basename $0) sourceVideo destinationGif [--fps FPS] [ --size WIDTH:HEIGHT] [--at SECONDS] [--runtime SECONDS] [--dither none|bayer|floyd_steinberg|sierra2|sierra2_4a] [--mode full|diff]\n\n"
	printf "%-30s %s\n" "-f --fps" "Set the fps. (Default: $fps)"
	printf "%-30s %s\n" "-s --size" "Set the size like WIDTH:HEIGHT. -1 can be used to keep the ratio. (Default: $size)"
	printf "%-30s %s\n" "-a --at" "Where to  begin in the video in seconds or ffmpeg supported time format. (Default: 0)"
	printf "%-30s %s\n" "-r --runtime" "Duration in seconds or ffmpeg supported time format. (Default: Till end)"
	printf "%-30s %s\n" "-d --dither" "Dithering mode to use. One of (none|bayer|floyd_steinberg|sierra2|sierra2_4a) (Default: $dither)"
	printf "%-30s %s\n" "-b --bayer-scale" "If dither=bayer select the pattern size in the range of 0 - 5. Lower values tend to produce less artefacts but larger images. (DISCLAIMER: i have no clue about such stuff) (Default: $bayer_scale)"
	printf "%-30s %s\n" "-m --mode" "'diff' or 'full'. 'diff' optimize the colors of moving objects at the cost of the background quality.  (Default: $mode)"
	printf "\n"
	exit 1
}

if [ "$#" -lt "2" ]; then
	print_help "$0"
fi

source="$1"
destination="$2"
shift; shift

while [ $# -gt 1 ]
do
	key="$1"
	case $key in
		-h|--help)
		print_help "$0"
		;;
		-f|--fps)
		fps="$2"
		shift
		;;
		-s|--size)
		size="$2"
		shift
		;;
		-a|--at)
		start="-ss $2"
		shift
		;;
		-r|--runtime)
		duration="-t $2"
		shift
		;;
		-m|--mode)
		if [ "$2" != "diff" ] && [ "$2" != "full" ]; then
			printf "Invalid mode. Must be 'full' or 'diff'\n"
			exit 1
		fi
		mode="$2"
		shift
		;;
		-d|--dither)
		# omg...
		if [ "$2" != "none" ] && [ "$2" != "bayer" ] && [ "$2" != "floyd_steinberg" ] && [ "$2" != "sierra2" ] && [ "$2" != "sierra2_4a" ]; then
			printf "Invalid dither mode. Must be one of (none|bayer|floyd_steinberg|sierra2|sierra2_4a)\n"
			exit 1
		fi
		dither="$2"
		shift
		;;
		-b|--bayer-scale)
		if [ "$2" -lt 0 ] || [ "$2" -gt 5 ]; then
			printf "Invalid bayer scale. Must be >= 0 and <= 5.\n"
			exit 1
		fi
		bayer_scale="$2"
		shift
		;;
		*)
			echo "Unknown option '$key'"
			print_help $0
		;;
	esac
	shift
done

rand=$(od -N4 -tu /dev/random | awk 'NR==1 {print $2} {}')
palette="${tmp_dir}ffpmeg2gif_$rand.png"
filters="fps=$fps,scale=$size:flags=lanczos"
if [ "$dither" = "bayer" ]; then
	dither="bayer:bayer_scale=$bayer_scale"
fi


# TODO: verbose/quite flag
printf "Start: $start\n"
printf "Duration: $duration\n"
printf "FPS: $fps\n"
printf "Size: $size\n"
printf "Dithering mode: $dither\n"
printf "Plattele generation mode:: $mode\n"
printf "Filters: $filters\n"
printf "Palette file: $palette\n"
printf "Sourcefile: $source\n"


printf "Create palette ..."
ffmpeg -v warning $start $duration -i "$source" -vf "$filters,palettegen=stats_mode=$mode" -y $palette || (echo "Failed creating the palette (Invalid video file ?)"x && rm $palette && exit 2)
printf " done\n"

printf "Create video ..."
ffmpeg -v warning $start $duration -i "$source" -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse=diff_mode=$diff_mode:dither=$dither" -y "$destination" || (echo Failed creating the gif && rm $palette && exit 3)
printf " done\n"
rm $palette
