#!/bin/zsh

# This script is the final step of setup

echo '[Rectangle] Import RectangleConfig.json'
echo '[iTerm2] Import Profiles.json'

git clone git@github.com:yyh-gl/go-installer.git
echo '[Go] Install Go'

curl \
  -L https://download.oracle.com/java/24/latest/jdk-24_macos-aarch64_bin.tar.gz \
  -o $HOME/jvm/jdk-24
echo '[JVM] Install JDK'

## Google Drive
read STDIN'?Please setup Google Drive. If you complete to setup. -> [ENTER]: '
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/00_Profile $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/01_Wallpapers $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/02_Geeks $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/03_IconsForMac $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/04_SlackStamps $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/05_Works $HOME/Pictures/
ln -s $HOME/GoogleDrive/01_メイン同期フォルダ/01_CasualLife/Pictures/99_Others $HOME/Pictures/
