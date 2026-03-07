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
mkdir -p $HOME/whisper-models && cd $_

curl -LO https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
```
(Consult [ggerganov/whisper.cpp &#128279;](https://huggingface.co/ggerganov/whisper.cpp/tree/main) for additional models.)

> Launch the Podcasts app to cache the most recent episode.

## Script

(In the process of generalizing it, but basically the script will locate the episode in an SQLITE database and transcribe the episode using the Whisper model. Script has additional features, too.)

