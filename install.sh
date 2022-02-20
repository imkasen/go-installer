#!/usr/bin/env bash

# Install the latest go version

# echo text with color
RED="31m"
GREEN="32m"
YELLOW="33m"

colorEcho(){
    COLOR=$1
    echo -e "\033[$COLOR${*:2}\033[0m"
}

# Check system architecture
arch(){
    ARCH=$(uname -m)
    SYS=$(uname)

    if [[ $ARCH == "x86_64" ]] && [[ $SYS == "Linux" ]]; then
        DIS="linux-amd64"
        FMT="tar.gz"
    fi
}

# Check network
checkNet(){
    if [[ $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        CNM=0
    else
        CNM=1 # China mainland
    fi
}

# Check area
setURL(){
    if [[ $CNM -eq 0 ]]; then
        URL="https://go.dev/dl/"
    else
        URL="https://golang.google.cn/dl/"
    fi
}

# Download
downloadGo(){
    colorEcho $GREEN "---- start downloading go ----"

    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    CUR_VERSION=$(go version | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    PACKAGE="go$VERSION.$DIS.$FMT"
    
    if [[ "$CUR_VERSION" != "$VERSION" ]]; then
        if [[ ! -e $PACKAGE ]]; then
            colorEcho $YELLOW "Download '$PACKAGE' from '$URL'..." 
            curl -LJ "$URL$PACKAGE" -o "$PACKAGE" --progress-bar
        else
            colorEcho $YELLOW "The package already exists, skip downloading..."
        fi
    else
        colorEcho $RED "The latest version is already installed, exit!" >& 2
        exit 1 
    fi

    colorEcho $GREEN "---- end   downloading go ----"
}

# Install
installGo(){
    colorEcho $GREEN "---- start installing go ----"

    if [[ -d /usr/local/go/ ]]; then
        colorEcho $YELLOW "Delete '/usr/local/go/'..."
        sudo rm -rf /usr/local/go/
    fi
    colorEcho $YELLOW "Untar '$PACKAGE'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"
    rm "$PACKAGE"

    colorEcho $GREEN "---- end   installing go ----"
}

# Configure Path
configPath(){
    colorEcho $GREEN "---- start configuring path ----"

    SHPATH=$(env | grep "SHELL=")
    if [[ $SHPATH =~ "zsh" ]]; then
        SHFILE=".zshrc"
    elif [[ $SHPATH =~ "bash" ]]; then
        SHFILE=".bashrc"
    fi

    if [[ -e ~/$SHFILE && $(grep -c "/usr/local/go" ~/$SHFILE) -eq 0 ]]; then
        colorEcho $YELLOW "Configure path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go/"
            echo "export PATH=\$PATH:\$GOROOT/bin"
            echo
        } >> ~/$SHFILE
        # shellcheck source=/dev/null
        source ~/$SHFILE
        configProxy
    else
        colorEcho $YELLOW "Go configuration already exists, skip..."
    fi

    colorEcho $GREEN "---- end   configuring path ----"
}

# Configure proxy
configProxy(){
    colorEcho $GREEN "---- start configuring proxy ----"

    if [[ $CNM -eq 1 ]]; then
        colorEcho $YELLOW "Configure proxy..."
        go env -w GO111MODULE=on
        go env -w GOPROXY=https://goproxy.cn,direct
    fi

    colorEcho $GREEN "---- end   configuring proxy ----"
}

main(){
    colorEcho $GREEN "======== Start  Installation ========"
    arch
    checkNet
    setURL
    downloadGo
    installGo
    configPath
    colorEcho $GREEN "======== Finish Installation ========"
}

main
