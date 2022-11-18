#!/bin/bash
PWD=$(pwd)

BIN=$PWD/bin

if [[ ! -d $BIN ]]; then
    mkdir $BIN
fi

ln -sf $PWD/macos/update-emacs.sh $BIN/update-emacs

if [[ -z $(awk -F ":" '$NF ~ "shell/bin" {print $NF}' $HOME/.zshrc) ]]; then
    echo "export PATH=\$PATH:$BIN" >> $HOME/.zshrc
fi
