#!/bin/zsh

# Not depend on other scripts

defaults import com.apple.HIToolbox ./.defaults/com.apple.HIToolbox.plist
defaults write -g com.apple.trackpad.scaling -float 3
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
killall SystemUIServer
