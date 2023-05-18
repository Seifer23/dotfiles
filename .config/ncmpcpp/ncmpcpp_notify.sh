#!/bin/bash

# Send notification with album art when ncmpcpp plays a new song
# execute_on_song_change must be set in ncmpcpp config

readonly MUSIC_DIR="${HOME}/Music/"
readonly SONG_PATH="$(mpc --format '%file%' current)"
readonly SONG_DIR="$(dirname "${SONG_PATH}")"
readonly ALBUM_ART_PATH="${MUSIC_DIR}/${SONG_DIR}/cover.jpg"
readonly FALLBACK_DIR="${MUSIC_DIR}/fallback.jpg"

cover_path=""

# First we check if the audio file has an embedded album art
ext="$(mpc --format %file% current | sed 's/^.*\.//')"
if [ "$ext" = "flac" ]; then
	# since FFMPEG cannot export embedded FLAC art we use metaflac
	metaflac --export-picture-to=/tmp/mpd_cover.jpg \
   	"$(mpc --format "$MUSIC_DIR"/%file% current)" &&
	cover_path="/tmp/mpd_cover.jpg"
else
	ffmpeg -loglevel quiet -y -i "$(mpc --format "$MUSIC_DIR"/%file% | head -n 1)" \
	/tmp/mpd_cover.jpg &&
	cover_path="/tmp/mpd_cover.jpg"
fi

if [ -f "${ALBUM_ART_PATH}" ] && [ "${cover_path}" == "" ]; then # if we can't find embeded album art go for cover.jpg
	cover_path=${ALBUM_ART_PATH}
elif [ ! -f "${ALBUM_ART_PATH}" ] && [ "${cover_path}" == "" ]; then
	# if everything fails use fallback image
	cover_path=$FALLBACK_DIR
fi

notify-send -i "${cover_path}" "Now Playing" "$(mpc --format '%title% - %artist%' current)"
