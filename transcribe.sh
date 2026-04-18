#!/bin/zsh

export PODCAST_TITLE="Halftime Report" # example

export SQLITE_DB="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite"

export EPISODE=($(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 7")) # store filenames of seven most recent episodes in an array

export PODCASTS="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache"

export GGML_METAL_PATH_RESOURCES="$(brew --prefix whisper-cpp)/share/whisper-cpp" # use Metal for GPU acceleration

open --background -a "Podcasts" # launch silently to help ensure episodes are cached

echo "One moment..."
sleep 5 # wait a moment to allow the Podcasts app to try caching episodes

for index in {1..7}; do
    if [[ ! -f $PODCASTS/$EPISODE[$index] ]]; then \
        base=$(basename $EPISODE[$index] .mp3)
        title=$(sqlite3 $SQLITE_DB \
            "SELECT ZTITLE
            FROM ZMTEPISODE
            WHERE ZUUID = '${base}'")
        echo "Error: "$EPISODE[$index]" not found! Make sure the episode \"$title\" is cached in the Podcasts app: Wait a moment longer to retry, otherwise download the episode to cache it."
        return
    fi
done

for index in {1..7}; do
    base=$(basename $EPISODE[$index] .mp3)
    title=$(sqlite3 $SQLITE_DB \
        "SELECT ZTITLE
        FROM ZMTEPISODE
        WHERE ZUUID = '${base}'")
    if [[ ! -f "${title//\//-}".txt ]]; then \
        whisper-cli \
            --model $HOME/whisper-models/ggml-small.en.bin \
            --vad \
            --vad-model $HOME/whisper-models/ggml-silero-v6.2.0.bin \
            --vad-threshold 0.1 \
            --file $PODCASTS/$EPISODE[$index] \
            --output-txt \
            --no-timestamps

        mv $PODCASTS/$EPISODE[$index].txt .
    fi
done

for file in *.txt; do
    if grep --quiet ">> >>" $file; then
        base=$(basename $file .mp3.txt)
        title=$(sqlite3 $SQLITE_DB \
            "SELECT ZTITLE
            FROM ZMTEPISODE
            WHERE ZUUID = '${base}'")
        echo "Transcript for episode \"$title\" is corrupted. Re-download the episode to re-cache it, and then re-transcribe it."
        mv $file $file.old
        return
    fi
done

for index in {1..7}; do
    base=$(basename $EPISODE[$index] .mp3)
    title=$(sqlite3 $SQLITE_DB \
        "SELECT ZTITLE
        FROM ZMTEPISODE
        WHERE ZUUID = '${base}'")

    mv $EPISODE[$index].txt "${title//\//-}".txt # replace slashes in title with dashes to avoid issues in filenames
done

mkdir -p ./archived

for file in *.txt; do
    base_file=$(basename $file .txt)
    found=false

    for index in {1..7}; do
        base_episode=$(basename $EPISODE[$index] .mp3)
        title_episode=$(sqlite3 $SQLITE_DB \
            "SELECT ZTITLE
            FROM ZMTEPISODE
            WHERE ZUUID = '${base_episode}'")
        if [[ "${title_episode//\//-}" =~ "$base_file" ]]; then
            found=true
            break
        fi
    done

    if [[ $found == false ]]; then
        mv $file ./archived
    fi
done

echo "\nDone! Now, you can utilize https://chatgpt.com, https://claude.ai, https://gemini.google.com or another AI assistant to summarize the transcript."