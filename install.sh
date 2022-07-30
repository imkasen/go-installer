#!/usr/bin/env bash
#
# Install the latest version of Go.

#----------------------------------------------------------
# functions

#######################################
# colorful_echo function
#
# echo text with different colors
#######################################
readonly RED="31m"
readonly GREEN="32m"
readonly YELLOW="33m"

colorful_echo(){
    COLOR=$1
    echo -e "\033[$COLOR${*:2}\033[0m"
}

#######################################
# check_os function
#
# check architecture and version
#######################################
check_os(){
    ARCH=$(uname -m)
    SYS=$(uname -s)
    readonly ARCH
    readonly SYS

    if [[ $ARCH == "x86_64" ]] && [[ $SYS == "Linux" ]]; then
        DIS="linux-amd64"
        FMT="tar.gz"

        # 'curl' is not installed
        if command -v apt &> /dev/null && ! command -v curl &> /dev/null; then
            colorful_echo $YELLOW "Installing 'curl'..."
            sudo apt install curl
        fi
    fi
    readonly DIS
    readonly FMT
}

#######################################
# check_network function
#
# adjust for Mainland China
#######################################
check_network(){
    if [[ ! $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        readonly CNM=1 # Mainland China
        URL="https://golang.google.cn/dl/"
    else
        URL="https://go.dev/dl/"
    fi
    readonly URL
}

#######################################
# download function
#
# download go package from web,
# skip if the package exists,
# quit if the latest version exists
#######################################
download(){
    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+(\.\d+)?' | head -n 1)
    CUR_VERSION=$(go version 2> /dev/null | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    PACKAGE="go$VERSION.$DIS.$FMT"
    readonly VERSION
    readonly CUR_VERSION
    readonly PACKAGE

    if [[ -z $CUR_VERSION ]]; then
        readonly FIRST_INSTALL=1
    fi

    if [[ "$CUR_VERSION" != "$VERSION" ]]; then
        colorful_echo $GREEN "Start downloading go:"
        if [[ ! -e $PACKAGE ]]; then
            colorful_echo $YELLOW "Downloading '$PACKAGE' from '$URL'..."
            curl -LJ "$URL$PACKAGE" -o "$PACKAGE" --progress-bar
        else
            colorful_echo $YELLOW "The package already exists, skip downloading..."
        fi
    else
        colorful_echo $RED "The latest version is already installed, exit!" >& 2
        exit 1
    fi

    clear
}

#######################################
# install function
#
# delete the old version if it exists
# unpack the downloaded package
#######################################
install(){
    colorful_echo $GREEN "Start installing go:"

    if [[ -d /usr/local/go/ ]]; then
        colorful_echo $YELLOW "Deleting '/usr/local/go/'..."
        sudo rm -rf /usr/local/go/
    fi

    colorful_echo $YELLOW "Unpacking '$PACKAGE'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"
    rm "$PACKAGE"
}

#######################################
# set_path function
#
# set go path when installing for the first time
#######################################
set_path(){
    SHPATH=$(env | grep "SHELL=")
    readonly SHPATH

    if [[ $SHPATH =~ "zsh" ]]; then
        SHFILE=".zshrc"
    elif [[ $SHPATH =~ "bash" ]]; then
        SHFILE=".bashrc"
    fi
    readonly SHFILE

    if [[ -e ~/$SHFILE && $FIRST_INSTALL -eq 1 ]]; then
        colorful_echo $YELLOW "Configuring path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go"
            echo "export PATH=\$PATH:\$GOROOT/bin"
            echo
        } >> ~/$SHFILE

        set_proxy
    else
        colorful_echo $YELLOW "Skip setting path."
    fi
}

#######################################
# set_proxy function
#
# set proxy for Chinese when installing for the first time
#######################################
set_proxy(){
    if [[ $CNM -eq 1 ]]; then
        colorful_echo $YELLOW "Configuring proxy..."
        {
            echo "# Go Proxy for Chinese"
            echo "export GO111MODULE=on"
            echo "export GOPROXY=https://goproxy.cn,direct"
            echo
        } >> ~/$SHFILE
    fi

    colorful_echo $YELLOW "PLEASE SOURCE YOUR '$SHFILE' FILE!"
}

#----------------------------------------------------------
# main

check_os
check_network
download
install
set_path
colorful_echo $GREEN "Finish Installation."
