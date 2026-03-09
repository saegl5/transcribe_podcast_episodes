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

curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin \
    -o $HOME/whisper-models/ggml-small.en.bin
```
(Consult [ggerganov/whisper.cpp &#128279;](https://huggingface.co/ggerganov/whisper.cpp/tree/main) for additional models.)

> Launch the Podcasts app to cache the most recent episode.

## Script

```
export PODCAST_TITLE="Apple News Today" # example

export SQLITE_DB="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Documents/MTLibrary.sqlite"

export EPISODE=$(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 1") # store the most recent episode

export PODCASTS="$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache"

export GGML_METAL_PATH_RESOURCES="$(brew --prefix whisper-cpp)/share/whisper-cpp" # use Metal for GPU acceleration

whisper-cli \
    --model $HOME/whisper-models/ggml-small.en.bin \
    --file $PODCASTS/$EPISODE \
    --output-txt \
    --no-timestamps

mv $PODCASTS/$EPISODE.txt .
```
 
The text file will be located in your working directory.

### Optional

Transcribe multiple episodes at once (e.g., seven)

```
export EPISODE=($(sqlite3 $SQLITE_DB \
    "SELECT e.ZUUID || '.mp3'
    FROM ZMTEPISODE e
    JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK
    WHERE p.ZTITLE LIKE '%${PODCAST_TITLE}%'
    ORDER BY e.ZPUBDATE DESC
    LIMIT 7")) # store seven most recent episodes in an array

for index in {1..7}; do
    whisper-cli \
        --model $HOME/whisper-models/ggml-small.en.bin \
        --file $PODCASTS/$EPISODE[$index] \
        --output-txt \
        --no-timestamps

    mv $PODCASTS/$EPISODE[$index].txt .
done
```

### Bonus

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

Archive older episodes.

```
mkdir --parents ./archived-transcripts

for file in *.txt; do
    base=$(basename $file .txt)
    if [[ ! $EPISODE[*] =~ $base ]]; then
        mv $file ./archived-transcripts
    fi
done
```

For the script including optional and bonus content [click here &#128279;](./full_script.txt).
