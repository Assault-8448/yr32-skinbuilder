#!/bin/bash

set -eu
shopt -s extglob

####################

depends=( ffmpeg curl unzip zip convert bc awk )
notfound=()

for app in ${depends[@]}; do
	if ! type $app > /dev/null 2>&1; then
		notfound+=($app)
	fi
done

if [[ ${#notfound[@]} -ne 0 ]]; then
	echo Failed to lookup dependency:

	for app in ${notfound[@]}; do
		echo - $app
	done

	exit 1
fi

####################

DIR=$(cd $(dirname $0) && pwd)

####################

set -x

mkdir -p "${DIR}/workdir/yr32"
cd "${DIR}/workdir"

####################

if [[ ! -e Inconsolata-Black.ttf ]]; then
	curl -L -s \
		--output Inconsolata-Black.ttf \
		https://github.com/google/fonts/raw/385af64e06099604fd67c2b002c915748892358b/ofl/inconsolata/static/Inconsolata-Black.ttf
fi

if [[ ! -e  Oxanium-Regular.ttf ]]; then
	curl -L -s \
		--output  Oxanium-Regular.ttf  \
		https://github.com/google/fonts/raw/385af64e06099604fd67c2b002c915748892358b/ofl/oxanium/static/Oxanium-Regular.ttf
fi

if [[ ! -d aristia ]]; then
	if [[ ! -e aristia.osk ]]; then
		curl -s \
			-X POST --output aristia.osk \
			"https://osuskins.net/download/k38KhZg"
	fi

	unzip -q aristia.osk -d aristia
fi

###################

function generate_empty_wav() {
	if [[ ! -e empty.wav ]]; then
		ffmpeg -hide_banner -loglevel error \
			-t 0 -f s16le -i /dev/zero \
			-acodec copy \
			empty.wav
	fi

	for f in $@; do
		cp empty.wav yr32/$f.wav
	done
}

function generate_empty_png() {
	if [[ ! -e empty.png ]]; then
		convert \
			-size 1x1 xc:transparent \
			empty.png
	fi

	for f in $@; do
		cp empty.png yr32/$f.png
	done
}

function generate_hit_emoji() {
	color=$1
	label=$2
	output=$3

	convert \
		-size 128x128 \
		-gravity center \
		-font "Inconsolata-Black.ttf" \
		-pointsize 64 \
		-fill white \
		-stroke $color \
		-strokewidth 4 \
		-background transparent \
		"label:$label" \
		\( \
			+clone \
			-background "#33333366" \
			-shadow 80x3+3+3 \
		\) \
		-background transparent \
		+swap \
		-layers merge \
		+repage \
		-rotate 5 \
		-trim \
		$output
}

function generate_ranking_image() {
	rankname=$1
	rankchar=$2
	color=$3
	yshift=$4

	convert \
		-size 800x1000 \
		-gravity center \
		-kerning -250 \
		-font "Oxanium-Regular.ttf" \
		-stroke '#ffffff30' \
		-strokewidth 20 \
		-pointsize 1000 \
		-fill "$color" \
		-background transparent \
		"label:$rankchar" \
		-roll ${yshift}+50 \
		\( \
			+clone \
			-background "#33333366" \
			-shadow 80x16+16+16 \
		\) \
		-background transparent \
		+swap \
		-layers merge \
		+repage \
		yr32/ranking-$rankname@2x.png

	convert \
		yr32/ranking-$rankname@2x.png \
		-resize 64x \
		yr32/ranking-$rankname-small@2x.png
}

function generate_single_char_image(){
	char=$1
	size=$2
	output=$3

	convert \
		-font "Oxanium-Regular.ttf" \
		-fill white \
		-pointsize $2 \
		-background transparent \
		"label:$char" \
		\( \
			+clone \
			-background "#33333366" \
			-shadow 80x2+2+2 \
		\) \
		-background transparent \
		+swap \
		-layers merge \
		+repage \
		$output
}

function generate_string_image() {
	size=$1
	color=$2
	left_spacing=$3
	top_spacing=$4
	label=$5
	output=$6
	convert \
		-font "Oxanium-Regular.ttf" \
		-pointsize $size \
		-fill $color \
		-background transparent \
		"label:$label" \
		\( \
			+clone \
			-background "#33333366" \
			-shadow 80x3+3+3 \
		\) \
		-background transparent \
		+swap \
		-layers merge \
		+repage \
		-trim \
		-gravity northwest \
		-splice ${left_spacing}x${top_spacing} \
		$output
}

function generate_mod_image() {
	color=$1
	label=$4
	output=$5
	convert \
		-size 128x128 \
		-font "Oxanium-Regular.ttf" \
		-pointsize 48 \
		-background $color \
		"label:$label" \
		-draw "circle 64,64 64,24" \
		\( \
			+clone \
			-background "#33333366" \
			-shadow 80x3+3+3 \
		\) \
		-background transparent \
		+swap \
		-layers merge \
		+repage \
		$output
	
}

####################

sound_prefixes=( soft normal drum )

function expand_all_prefix() {

	for f in $@; do
		for prefix in ${sound_prefixes[@]}; do
			echo $prefix-$f
		done
	done
}

####################

rm -rf yr32/*

# osu! - Skinnable Files - Detail List
#   https://docs.google.com/spreadsheets/d/1bhnV-CQRMy3Z0npQd9XSoTdkYxz0ew5e648S00qkJZ8/edit
# Browse Fonts - Google Fonts
#   https://fonts.google.com/

# osu! UI sounds
generate_empty_wav \
	shutter

# osu! UI textures
generate_empty_png \
	star2@2x \
	cursortrail@2x \
	menu-snow@2x \
	scorebar-marker@2x \
	ranking-title@2x \
	scorebar-bg@2x

convert -size 128x128 \
	radial-gradient:#50506733-#a0a0cfee \
	\( \
		-size 128x128 \
		xc:none \
		-draw "circle 64,64 64,24" \
	\) \
	-compose dst_in -composite \
	yr32/cursor@2x.png

convert -size 32x32 \
	xc:#50506733 \
	yr32/cursor-smoke@2x.png

len=20
center=50
pos_x_left=$( expr $center - $len )
pos_x_right=$( expr $center + $len "*" 2 )
pos_y_top=$( echo "$center-sqrt(3)*$len" | bc -l )
pos_y_bottom=$( echo "$center+sqrt(3)*$len" | bc -l )

convert -size 100x100 \
	xc:none \
	-fill '#aaaaaa33' \
	-strokewidth 5 \
	-stroke '#ffffff99' \
	-draw "polygon $pos_x_left,$pos_y_top $pos_x_left,$pos_y_bottom $pos_x_right,$center" \
	-rotate 180 \
	-draw "polygon $pos_x_left,$pos_y_top $pos_x_left,$pos_y_bottom $pos_x_right,$center" \
	-rotate 90 \
	yr32/star@2x.png

convert -size 1600x220 \
	-define gradient:angle=45 \
	gradient:#606060ff-#00000000 \
	-fill none \
	-stroke "#33336666" \
	-strokewidth 5 \
	-draw """
		circle 800,-20 800,155
	""" \
	-strokewidth 10 \
	-draw """
		circle 1000,300 1000,50
	""" \
	\( \
		xc:none \
		-size 1600x220 \
		-stroke none \
		-fill white \
		-draw "roundrectangle 10,15 1400,205 10,10" \
	\) \
	-compose dst_in -composite \
	yr32/menu-button-background@2x.png

convert -size 1290x10 \
	xc:#aaaaff40 \
	yr32/scorebar-colour@2x.png
#
# convert -size 512x512 \
# 	'xc:#eeeeeeff' \
# 	-background transparent \
# 	-gravity center \
# 	\( \
# 		-size 500x28 \
# 		xc:white \
# 		-rotate 45 \
# 		\( +clone -flip \) \
# 		-compose dst_over \
# 		-composite \
# 	\) \
# 	-compose dst_in \
# 	-composite \
# 	\( \
# 		+clone \
# 		-background "#33333366" \
# 		-shadow 80x3+3+3 \
# 	\) \
# 	-background transparent \
# 	+swap \
# 	-layers merge \
# 	+repage \
# 	-trim \
# 	yr32/section-fail@2x.png
#
# convert -size 512x512 \
# 	xc:none \
# 	-background transparent \
# 	-gravity center \
# 	-fill none \
# 	-stroke '#eeeeeeff' \
# 	-strokewidth 25 \
# 	-draw """
# 		circle 256,256 256,15
# 	""" \
# 	\( \
# 		+clone \
# 		-background "#33333366" \
# 		-shadow 80x3+3+3 \
# 	\) \
# 	-background transparent \
# 	+swap \
# 	-layers merge \
# 	+repage \
# 	-trim \
# 	yr32/section-pass@2x.png

generate_ranking_image xh SS '#eeeeeeff' +0
generate_ranking_image sh S '#eeeeeeff' +0
generate_ranking_image x SS '#ffff66ff' +0
generate_ranking_image s S '#ffff66ff' +0
generate_ranking_image a A '#66bb66ff' +0
generate_ranking_image b B '#6666bbff' +0
generate_ranking_image c C '#bb66bbff' -40
generate_ranking_image d D '#bb6666ff' +0

for n in `seq 0 9`; do
	generate_single_char_image $n 64 yr32/score-$n@2x.png
done


generate_single_char_image ',' 64 yr32/score-comma@2x.png
generate_single_char_image '.' 64 yr32/score-dot@2x.png
generate_single_char_image '%' 64 yr32/score-percent@2x.png
generate_single_char_image 'x' 64 yr32/score-x@2x.png

for f in ./yr32/score-*@2x.png; do
	filename=$(basename $f)
	char=${filename#score-}
	char=${char%@2x.png}
	convert \
		yr32/score-$char@2x.png \
		-scale x32 \
		yr32/scoreentry-$char@2x.png
done

generate_string_image 192 '#eeeeeeff' 0 0 '!UNRANKED!' yr32/play-unranked@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 'CLEAR' yr32/spinner-clear@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 'PASS' yr32/section-pass@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 'FAILURE' yr32/section-fail@2x.png
generate_string_image 96 '#eeeeeeff' 0 0 '- PERFECT -' yr32/ranking-perfect@2x.png
generate_string_image 64 '#eeeeeeff' 20 0 'combo' yr32/ranking-maxcombo@2x.png
generate_string_image 64 '#eeeeeeff' 0 0 'accuracy' yr32/ranking-accuracy@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 '3' yr32/count3@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 '2' yr32/count2@2x.png
generate_string_image 192 '#eeeeeeff' 0 0 '1' yr32/count1@2x.png
generate_string_image 128 '#eeeeeeff' 0 0 'START' yr32/go@2x.png


convert -size 1200x975 \
	-define gradient:angle=135 \
	gradient:#00003388-#00003300 \
	-fill '#000033aa' \
	-draw "polygon 0,110 0,130 1200,110 1200,110" \
	yr32/ranking-panel@2x.png


# osu! play textures
generate_empty_png \
	hit300@2x hit300g@2x hit300k@2x \
	sliderendcircle@2x \
	sliderfollowcircle@2x \
	spinner-glow@2x \
	spinner-middle@2x \
	spinner-middle2@2x \
	spinner-top@2x \
	spinner-approachcircle@2x \
	spinner-spin@2x \
	spinner-osu@2x \
	followpoint-0@2x followpoint-1@2x \
	followpoint-2@2x followpoint-3@2x \
	ready@2x

len=350
center=800
pos_x_left=$( expr $center - $len ) || true
pos_x_right=$( expr $center + $len "*" 2 )
pos_y_top=$( echo "$center-sqrt(3)*$len" | bc -l )
pos_y_bottom=$( echo "$center+sqrt(3)*$len" | bc -l )

convert -size 1600x1600 \
	xc:none \
	-fill "#00003311" \
	-stroke "#ffffffee" \
	-strokewidth 15 \
	-draw """
		circle $center,$center $center,$( expr $center + $len "*" 2 )
	""" \
	-fill "#ffffffee" \
	-stroke none \
	-draw """
		circle $center,$center $center,$( expr $center - 15 )
	""" \
	yr32/spinner-bottom@2x.png

convert -size 256x256 \
	xc:none \
	-stroke  "#ffffffff" \
	-strokewidth 12 \
	-fill none \
	-draw "circle 128,128 128,15" \
	yr32/hitcircleoverlay@2x.png

cp yr32/hitcircleoverlay@2x.png yr32/sliderb@2x.png

convert -size 256x256 \
	xc:none \
	-stroke  "#ffffff88" \
	-strokewidth 5 \
	-fill none \
	-draw "circle 128,128 128,15" \
	yr32/approachcircle@2x.png

convert -size 256x256 \
	gradient:#00000060-#ffffff60 \
	\( \
		-size 256x256 \
		xc:none \
		-draw "circle 128,128 128,10" \
	\) \
	-compose dst_in -composite \
	yr32/hitcircle@2x.png

# plz set skin.ini [Fonts] HitCircleOverlap to size
for n in `seq 0 9`; do
	convert -size 64x64 \
		xc:none \
		-fill "#eeeeeeff" \
		-draw "circle 32,32 32,1" \
		yr32/default-$n@2x.png
done

for n in `seq 0 9`; do
	convert -size 256x8 \
		"radial-gradient:#ffffff1${n}-#ffffff00" \
		yr32/followpoint-$(expr $n + 3)@2x.png
done

len=16
center=128
pos_x_left=$( expr $center - $len - 32)
pos_x_right=$( expr $center + $len "*" 2 - 32)
pos_y_top=$( echo "$center-sqrt(3)*$len" | bc -l )
pos_y_bottom=$( echo "$center+sqrt(3)*$len" | bc -l )

convert -size 256x256 \
	xc:none \
	-fill "#ffffffaa" \
	-draw "polygon $pos_x_left,$pos_y_top $pos_x_left,$pos_y_bottom $pos_x_right,$center" \
	yr32/reversearrow@2x.png

generate_hit_emoji "#60A020" "-_¡" yr32/hit100@2x.png
generate_hit_emoji "#60A020" "-_¡" yr32/hit100k@2x.png
generate_hit_emoji "#2060A0" "-_¡" yr32/hit50@2x.png
generate_hit_emoji "#2060A0" "-_¡" yr32/hit50k@2x.png
generate_hit_emoji "#E04040" "¡_¡" yr32/hit0@2x.png

convert -size 32x32 \
	xc:none \
	-fill "#ffffff88" \
	-draw "circle 16,16 16,5" \
	yr32/sliderscorepoint@2x.png


# Set true to render slider end
if false; then
	convert -size 32x32 \
		xc:none \
		-fill "#ffffff88" \
		-draw "circle 16,16 16,0" \
		yr32/sliderendcircle@2x.png
fi


# osu! play sounds

generate_empty_wav \
	$(expand_all_prefix sliderslide) \
	$(expand_all_prefix sliderwhistle) \
	readys

ffmpeg \
	-i aristia/applause.wav \
	yr32/applause.mp3

copy_list=( \
	spinnerbonus.wav \
	count1s.wav \
	count2s.wav \
	count3s.wav \
	gos.wav \
	combobreak.wav \
	sectionpass.wav \
	sectionfail.wav \
	failsound.mp3 \
)

for f in ${copy_list[@]}; do
	cp aristia/$f yr32/$f
done

copy_list=(hitclap hitfinish hitnormal hitwhistle slidertick)
for f in ${copy_list[@]}; do
	for prefix in ${sound_prefixes[@]}; do
		cp aristia/normal-$f.wav yr32/$prefix-$f.wav
	done
done


####################

cd ./yr32

# for f in $(ls *@2x.png); do
# 	convert $f -resize 50% ${f%@2x*}.png
# done

cp "${DIR}/skin.ini" skin.ini

zip -r "${DIR}/yr32.osk" .

