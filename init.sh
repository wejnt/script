#!/bin/bash
PWD=$(pwd)

BIN=$PWD/bin

if [[ ! -d $BIN ]]; then
    mkdir $BIN
fi

ln -sf $PWD/macos/update-emacs.sh $BIN/macos-update-emacs
