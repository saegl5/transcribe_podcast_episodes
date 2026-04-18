# Transcribe Podcast Episodes

Script for transcribing Apple Podcasts episodes

## Requirement

[Homebrew &#128279;](https://brew.sh/)

## Getting Started

Install packages:

```
brew install whisper-cpp ffmpeg
```

Download Whisper model: (example)

```
mkdir -p $HOME/whisper-models

curl --location https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin \
    --output $HOME/whisper-models/ggml-small.en.bin
```
(Consult [ggerganov/whisper.cpp &#128279;](https://huggingface.co/ggerganov/whisper.cpp/tree/main) for additional models.)

## Z Shell Script

```
#!/bin/zsh

export PODCAST_TITLE="Halftime Report" # example

export SQLITE_DB="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite"

export EPISODE=$(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 1") # store filename of the most recent episode

export PODCASTS="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache"

export GGML_METAL_PATH_RESOURCES="$(brew --prefix whisper-cpp)/share/whisper-cpp" # use Metal for GPU acceleration

whisper-cli \
    --model $HOME/whisper-models/ggml-small.en.bin \
    --file $PODCASTS/$EPISODE \
    --output-txt \
    --no-timestamps

mv $PODCASTS/$EPISODE.txt .
```
 
Save as, for example, "transcribe.sh" and run it: `zsh transcribe.sh`

Be patient! Once the process is completed, the text file will be located in your working directory. Afterword, you can utilize [Claude &#128279;](https://claude.ai), [ChatGPT &#128279;](https://chatgpt.com), [Gemini &#128279;](https://gemini.google.com) or another AI assistant to summarize the transcript. For example, in Claude Code: `claude --model sonnet "Summarize each .txt file, and structure your response as a numbered list."`

### Optional

Transcribe multiple episodes at once (e.g., seven)

```
export EPISODE=($(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 7")) # store filenames of seven most recent episodes in an array

for index in {1..7}; do
    whisper-cli \
        --model $HOME/whisper-models/ggml-small.en.bin \
        --file $PODCASTS/$EPISODE[$index] \
        --output-txt \
        --no-timestamps

    mv $PODCASTS/$EPISODE[$index].txt .
done
```

Check and ensure that episodes are cached.

```
open --background -a "Podcasts"

sleep 5

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
```

Skip episodes you have already transcribed.

```
for index in {1..7}; do
    if [[ ! -f $EPISODE[$index].txt ]]; then \
        whisper-cli \
            --model $HOME/whisper-models/ggml-small.en.bin \
            --file $PODCASTS/$EPISODE[$index] \
            --output-txt \
            --no-timestamps

        mv $PODCASTS/$EPISODE[$index].txt .
    fi
done
```

Check for corrupted transcripts.

```
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
```

Make transcripts easier to identify.

```
for index in {1..7}; do
    base=$(basename $EPISODE[$index] .mp3)
    title=$(sqlite3 $SQLITE_DB \
        "SELECT ZTITLE
        FROM ZMTEPISODE
        WHERE ZUUID = '${base}'")

    mv $EPISODE[$index].txt "${title//\//-}".txt # replace slashes in title with dashes to avoid issues in filenames
done
```

Archive older episodes.

```
mkdir -p ./archived

for file in *.txt; do
    base=$(basename $file .txt)
    if [[ ! $EPISODE[*] =~ $base ]]; then
        mv $file ./archived
    fi
done
```

For the ZSH script with optional content included, [click here &#128279;](./transcribe.sh). Save it, and run it: `zsh transcribe.sh`

## Related

* [Use YouTube API to download transcription of videos for securities trading opportunities (Linux/macOS) &#128279;](https://github.com/yuchild/youtube_transcripts)
* [Transcribe YouTube videos using yt-dlp and whisper-cpp (macOS) &#128279;](https://gist.github.com/saegl5/f5cb33b667c141a262cc13a19c86528b)
