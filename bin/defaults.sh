#!/bin/zsh

# Not depend on other scripts

defaults import com.apple.HIToolbox ./.defaults/com.apple.HIToolbox.plist
defaults write -g com.apple.trackpad.scaling -float 3
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.controlcenter 'NSStatusItem Visible Bluetooth' -bool true
defaults write com.apple.controlcenter 'NSStatusItem Visible Sound' -bool true
# TODO: Not reflected immediately, so comment out for now
# defaults write -g AppleInterfaceStyle -string "Dark"
killall SystemUIServer
