#!/bin/bash

cd ~/.oh-my-zsh && git pull && \
cd ~/.libs/delta && git pull && \
cd ~/.libs/eza && git pull && \
cd ~/.libs/fzf && git pull && \
asdf plugin update --all && \
cargo install-update -af
