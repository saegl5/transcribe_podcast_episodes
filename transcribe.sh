#!/bin/zsh

# Transcribe Podcast Episodes Script
# Requires: whisper-cpp, ffmpeg (install via: brew install whisper-cpp ffmpeg)
# Setup: Download a Whisper model to $HOME/whisper-models/
#        Launch the Podcasts app to cache the episode

# Configuration
export PODCAST_TITLE="Halftime Report" # Change this to the podcast you want to transcribe

export SQLITE_DB="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite"
export PODCASTS="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache"
export GGML_METAL_PATH_RESOURCES="$(brew --prefix whisper-cpp)/share/whisper-cpp" # GPU acceleration

# Find the most recent episode
export EPISODE=$(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 1")

# Verify episode was found
if [[ -z $EPISODE ]]; then
    echo "Error: Episode not found for podcast: ${PODCAST_TITLE}"
    echo "Make sure the podcast is cached in the Podcasts app."
    exit 1
fi

echo "Transcribing episode: $EPISODE"

# Transcribe the episode
whisper-cli \
    --model $HOME/whisper-models/ggml-small.en.bin \
    --file $PODCASTS/$EPISODE \
    --output-txt \
    --no-timestamps

# Move transcript to current directory
if [[ -f "$PODCASTS/$EPISODE.txt" ]]; then
    mv "$PODCASTS/$EPISODE.txt" .
    echo "Transcription complete: ${EPISODE}.txt"
else
    echo "Error: Transcript file not found"
    exit 1
fi
