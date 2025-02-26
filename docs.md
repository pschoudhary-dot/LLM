Commands:

Install Termux:
Download latest Termux APK from: https://github.com/termux/termux-app/releases


Set Up Environment:
termux-setup-storage
pkg upgrade
pkg install git cmake golang

Install Ollama:
git clone --depth 1 https://github.com/ollama/ollama.git
cd ollama
go generate ./...
go build .
./ollama serve &

Run DeepSeek-R1:
./ollama run deepseek-r1:1.5b --verbose

Optional Cleanup:
chmod -R 700 ~/go
rm -r ~/go
cp ollama/ollama /data/data/com.termux/files/usr/bin/