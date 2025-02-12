#!/bin/bash

PACKAGE_ROOT="$(dirname "${SCRIPT_DIR}")"

install_signal() {
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >/tmp/signal-desktop-keyring.gpg
    cat /tmp/signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | sudo tee /etc/apt/sources.list.d/signal-xenial.list
    sudo apt update && sudo apt install signal-desktop && rm /tmp/signal-desktop-keyring.gpg
}

install_ulauncher() {
    sudo add-apt-repository universe -y && sudo apt-add-repository ppa:agornostal/ulauncher -y && sudo apt update && sudo apt install ulauncher
}

install_starship() {
    curl -sS https://starship.rs/install.sh | sh
}

install_wezterm() {
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo apt update && sudo apt install wezterm
}

install_neovim() {
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update && sudo apt install neovim
}

install_go() {
    wget "https://dl.google.com/go/$(curl https://go.dev/VERSION?m=text | head -n1).linux-amd64.tar.gz" -O /tmp/go-linux.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go-linux.tar.gz
}

install_idea() {

    local TMP_DIR="/tmp"
    local INSTALL_DIR="$HOME/.local/share/JetBrains/Toolbox/bin"
    local SYMLINK_DIR="$HOME/.local/bin"

    echo "### INSTALL JETBRAINS TOOLBOX ###"

    echo -e "\e[94mFetching the URL of the latest version...\e[39m"
    ARCHIVE_URL=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' | grep -Po '"linux":.*?[^\\]",' | awk -F ':' '{print $3,":"$4}' | sed 's/[", ]//g')
    ARCHIVE_FILENAME=$(basename "$ARCHIVE_URL")

    echo -e "\e[94mDownloading $ARCHIVE_FILENAME...\e[39m"
    rm "$TMP_DIR/$ARCHIVE_FILENAME" 2>/dev/null || true
    wget -q --show-progress -cO "$TMP_DIR/$ARCHIVE_FILENAME" "$ARCHIVE_URL"

    echo -e "\e[94mExtracting to $INSTALL_DIR...\e[39m"
    mkdir -p "$INSTALL_DIR"
    rm "$INSTALL_DIR/jetbrains-toolbox" 2>/dev/null || true
    tar -xzf "$TMP_DIR/$ARCHIVE_FILENAME" -C "$INSTALL_DIR" --strip-components=1
    rm "$TMP_DIR/$ARCHIVE_FILENAME"
    chmod +x "$INSTALL_DIR/jetbrains-toolbox"

    echo -e "\e[94mSymlinking to $SYMLINK_DIR/jetbrains-toolbox...\e[39m"
    mkdir -p $SYMLINK_DIR
    rm "$SYMLINK_DIR/jetbrains-toolbox" 2>/dev/null || true
    ln -s "$INSTALL_DIR/jetbrains-toolbox" "$SYMLINK_DIR/jetbrains-toolbox"

    if [ -z "$CI" ]; then
        echo -e "\e[94mRunning for the first time to set-up...\e[39m"
        ("$INSTALL_DIR/jetbrains-toolbox" &)
        echo -e "\n\e[32mDone! JetBrains Toolbox should now be running, in your application list, and you can run it in terminal as jetbrains-toolbox (ensure that $SYMLINK_DIR is on your PATH)\e[39m\n"
    else
        echo -e "\n\e[32mDone! Running in a CI -- skipped launching the AppImage.\e[39m\n"
    fi
}

install_nvm() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
}
