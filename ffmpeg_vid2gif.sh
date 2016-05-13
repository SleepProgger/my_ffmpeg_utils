#!/bin/sh

# See http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
# TODO: Check ffmpeg version
# TODO: subtitles
# TODO: check if video file exists
# TODO: add some wisedom about the dithering modes. (Aquire such wisedom first)

tmp_dir="/tmp/"
start=""
duration=""

# defaults
fps=15
size="640:-1"
mode="full"
dither="sierra2"
bayer_scale=2
onestep=0
verbose="quiet"
gifsicle=0
# Am i missing something ? Why isn't this enabled by default ?
# It should be pretty nice for static backgrounds and don't really matter for everything else.
diff_mode="rectangle"
#diff_mode="none"

print_help() {
	printf "\n"
	printf "USAGE: $(basename $0) sourceVideo destinationGif [--fps FPS] [ --size WIDTH:HEIGHT] [--at SECONDS] [--runtime SECONDS] [--dither none|bayer|floyd_steinberg|sierra2|sierra2_4a] [--mode full|diff] [--onestep] [--gifsicle]\n\n"
	printf "%-30s %s\n" "-f --fps" "Set the fps. (Default: $fps)"
	printf "%-30s %s\n" "-s --size" "Set the size like WIDTH:HEIGHT. -1 can be used to keep the ratio. (Default: $size)"
	printf "%-30s %s\n" "-a --at" "Where to  begin in the video in seconds or ffmpeg supported time format. (Default: 0)"
	printf "%-30s %s\n" "-r --runtime" "Duration in seconds or ffmpeg supported time format. (Default: Till end)"
	printf "%-30s %s\n" "-d --dither" "Dithering mode to use. One of (none|bayer|floyd_steinberg|sierra2|sierra2_4a) (Default: $dither)"
	printf "%-30s %s\n" "-b --bayer-scale" "If dither=bayer select the pattern size in the range of 0 - 5. Lower values tend to produce less artefacts but larger images. (DISCLAIMER: i have no clue about such stuff) (Default: $bayer_scale)"
	printf "%-30s %s\n" "-m --mode" "'diff' or 'full'. 'diff' optimize the colors of moving objects at the cost of the background quality.  (Default: $mode)"
	printf "%-30s %s\n" "-v --verbose" "One of (quiet|fatal|error|warning|info|verbose) (Default: $verbose)"
	printf "%-30s %s\n" "-o --onestep" "Do not generate palette before. Tend to produce worse, but way smaller gifs. Ignores dithering parameter. (Default: Not set)"
	printf "%-30s %s\n" "-g --gifsicle" "Use gifsicle afterwards to ensure valid gifs.'. (Default: Not set)"
	printf "\n"
	exit 1
}

if [ "$#" -lt "2" ]; then
	print_help "$0"
fi

source="$1"
destination="$2"
shift; shift

while [ $# -gt 0 ]
do
	key="$1"
	case $key in
		-h|--help)
		print_help "$0"
		;;
		-o|--onestep)
			onestep="1"
		;;
		-g|--gifsicle)
		gifsicle=1
		;;
		-f|--fps)
		[ $# -lt 2 ] && printf "FPS need parameter" && print_help "$0"
		fps="$2"
		shift
		;;
		-s|--size)
		[ $# -lt 2 ] && printf "Size need parameter" && print_help "$0"
		size="$2"
		shift
		;;
		-a|--at)
		[ $# -lt 2 ] && printf "Start need parameter" && print_help "$0"
		start="-ss $2"
		shift
		;;
		-r|--runtime)
		[ $# -lt 2 ] && printf "Runtime need parameter" && print_help "$0"
		duration="-t $2"
		shift
		;;
		-m|--mode)
		[ $# -lt 2 ] && printf "Mode need parameter" && print_help "$0"
		if [ "$2" != "diff" ] && [ "$2" != "full" ]; then
			printf "Invalid mode. Must be 'full' or 'diff'\n"
			exit 1
		fi
		mode="$2"
		shift
		;;
		-d|--dither)
		[ $# -lt 2 ] && printf "Dither need parameter" && print_help "$0"
		# omg...
		if [ "$2" != "none" ] && [ "$2" != "bayer" ] && [ "$2" != "floyd_steinberg" ] && [ "$2" != "sierra2" ] && [ "$2" != "sierra2_4a" ]; then
			printf "Invalid dither mode. Must be one of (none|bayer|floyd_steinberg|sierra2|sierra2_4a)\n"
			exit 1
		fi
		dither="$2"
		shift
		;;
		-b|--bayer-scale)
		[ $# -lt 2 ] && printf "Bayer scale need parameter" && print_help "$0"
		if [ "$2" -lt 0 ] || [ "$2" -gt 5 ]; then
			printf "Invalid bayer scale. Must be >= 0 and <= 5.\n"
			exit 1
		fi
		bayer_scale="$2"
		shift
		;;
		-v|--verbose)
		[ $# -lt 2 ] && printf "Verbose need parameter" && print_help "$0"
		if [ "$2" != "quiet" ] && [ "$2" != "fatal" ] && [ "$2" != "error" ] && [ "$2" != "warning" ] && [ "$2" != "info" ] && [ "$2" != "verbose" ]; then
			printf "Invalid verbose mode. Must be one of (quiet|fatal|error|warning|info|verbose)\n"
			exit 1
		fi
		verbose="$2"
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


if [ "$verbose" = "info" ] || [ "$verbose" = "verbose" ]; then
	printf "Start: $start\n"
	printf "Duration: $duration\n"
	printf "FPS: $fps\n"
	printf "Size: $size\n"
	printf "Dithering mode: $dither\n"
	printf "Plattele generation mode:: $mode\n"
	printf "Filters: $filters\n"
	printf "Palette file: $palette\n"
	printf "Sourcefile: $source\n"
fi


if [ "$onestep" = "1" ]; then
	ffmpeg -v "$verbose" $start $duration -i "$source" -vf "$filters" "$destination"
else
	[ $verbose != "quiet" ] && printf "Create palette ..."
	ffmpeg -v "$verbose" $start $duration -i "$source" -vf "$filters,palettegen=stats_mode=$mode" -y $palette || (printf "Failed creating the palette (Invalid video file ?)\n" && rm $palette && exit 2)
	[ $verbose != "quiet" ] && printf " done\n"

	[ $verbose != "quiet" ] && printf "Create video ..."
	ffmpeg -v "$verbose" $start $duration -i "$source" -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse=diff_mode=$diff_mode:dither=$dither" -y "$destination" || (printf "Failed creating the gif\n" && rm $palette && exit 3)
	[ $verbose != "quiet" ] && printf " done\n"
	rm $palette
fi

if [ "$gifsicle" = "1" ]; then
	[ $verbose != "quiet" ] && printf "Running gifsicle\n"
	gifsicle --careful --batch "$destination"
fi
