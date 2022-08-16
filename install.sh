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

        if command -v apt &> /dev/null; then
            # 'curl' is not installed
            if ! command -v curl &> /dev/null; then
                colorful_echo $YELLOW "Installing 'curl'..."
                sudo apt install curl -y
            fi
            # sha256sum
            if ! command -v sha256sum &> /dev/null; then
                colorful_echo $YELLOW "Installing 'coreutils'..."
                sudo apt install coreutils -y
            fi
            # tar
            if ! command -v tar &> /dev/null; then
                colorful_echo $YELLOW "Installing 'tar'..."
                sudo apt install tar -y
            fi
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
    if ! ping -c2 -i0.3 -W1 "google.com" &> /dev/null; then
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
    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+(\.\d+)?')
    CUR_VERSION=$(go version 2> /dev/null | grep -oP '\d+\.\d+\.?\d*')
    PACKAGE="go$VERSION.$DIS.$FMT"
    CHECKSUM=$(curl -s $URL | grep -A 5 "$PACKAGE\">$PACKAGE" | grep -oP '(?<=<td><tt>).*(?=</tt></td>)')
    readonly VERSION
    readonly CHECKSUM
    readonly CUR_VERSION
    readonly PACKAGE

    if [[ "$CUR_VERSION" != "$VERSION" ]]; then
        colorful_echo $GREEN "Start downloading go:"
        if [[ ! -e "/tmp/$PACKAGE" ]]; then
            colorful_echo $YELLOW "Downloading '$PACKAGE' from '$URL'..."
            HTTP_CODE=$(curl --connect-timeout 10 -w "%{http_code}" -LJ "$URL$PACKAGE" -o "/tmp/$PACKAGE" --progress-bar)

            if [[ $HTTP_CODE -ne 200 ]]; then
                colorful_echo $RED "Request go package failed with the http code '$RTN_CODE'!"
                exit 1
            fi
        else
            colorful_echo $YELLOW "The package already exists, skip downloading..."
        fi
    else
        colorful_echo $RED "The latest version is already installed, exit!" >& 2
        exit 1
    fi

    if [[ $(sha256sum "/tmp/$PACKAGE" | awk '{print $1}') != "$CHECKSUM" ]]; then
        colorful_echo $RED "The sha256 checksum of downloaded package is wrong, delete it and exit!"
        rm "/tmp/$PACKAGE"
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
    if ! sudo tar -C /usr/local -xzf "/tmp/$PACKAGE" ; then
        colorful_echo $RED "Fail to unpack '$PACKAGE', exit!"
        sudo rm -rf /usr/local/go/
        exit 1
    fi
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
    else
        SHFILE="UNKNOWN"
    fi
    readonly SHFILE

    if [[ -e ~/$SHFILE && $(grep -c "/usr/local/go" ~/$SHFILE) -eq 0 ]]; then
        colorful_echo $YELLOW "Configuring path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go"
            echo "export PATH=\$PATH:\$GOROOT/bin"
            echo
        } >> ~/$SHFILE

        set_proxy
    elif [[ $SHFILE == "UNKNOWN" ]]; then
        colorful_echo $YELLOW "Please add '/usr/local/go/bin' to the 'PATH' environment variable"
    else
        colorful_echo $YELLOW "Configuration already exists, skip setting path."
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
