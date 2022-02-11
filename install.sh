#!/usr/bin/env bash

# Install the latest go version

# Check system architecture
arch(){
    ARCH=$(uname -m)
    SYS=$(uname)

    if [[ $ARCH == "x86_64" ]] && [[ $SYS == "Linux" ]]; then
        DIS="linux-amd64"
        FMT="tar.gz"
    fi
}

# Check area
checkNet(){
    if [[ $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        URL="https://go.dev/dl/"
    else  # China mainland
        URL="https://golang.google.cn/dl/"
    fi
}

# Download
downloadGo(){
    echo "==== start downloading go ===="

    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    CUR_VERSION=$(go version | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    PACKAGE="go$VERSION.$DIS.$FMT"
    
    if [[ "$CUR_VERSION" < "$VERSION" ]]; then
        if [[ ! -e $PACKAGE ]]; then
            echo "Download '${PACKAGE}' from '${URL}'..." 
            curl -LJ "$URL$PACKAGE" -o "$PACKAGE" --progress-bar
        else
            echo "The package already exists."
        fi
    else
        echo "!The latest version is already installed! Exit." >& 2
        exit 1 
    fi

    echo "==== end downloading go ===="
}

# Install
installGo(){
    echo "==== start installing go ===="

    if [[ -d /usr/local/go/ ]]; then
        echo "Delete '/usr/local/go/'..."
        sudo rm -rf /usr/local/go/
    fi
    echo "Untar '${PACKAGE}'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"

    echo "==== end installing go ===="
}

# Configure Path
configPath(){
    echo "==== start configuring path ===="

    SHPATH=$(env | grep "SHELL=")
    if [[ $SHPATH =~ "zsh" ]]; then
        SHFILE=".zshrc"
    elif [[ $SHPATH =~ "bash" ]]; then
        SHFILE=".bashrc"
    fi

    if [[ -e ~/$SHFILE && $(grep -c "/usr/local/go" ~/$SHFILE) -eq 0 ]]; then
        echo "Configure path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go/"
            echo "export PATH=\$PATH:\$GOROOT/bin"
            echo
        } >> ~/$SHFILE
        # shellcheck source=/dev/null
        source ~/${SHFILE}
        configProxy
    else
        echo "Go configuration already exists, skip..."
    fi

    echo "==== end configuring path ===="
}

# Configure proxy
configProxy(){
    echo "==== start configuring proxy ===="

    if [[ ! $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        echo "Configure proxy..."
        go env -w GO111MODULE=on
        go env -w GOPROXY=https://goproxy.cn,direct
    fi

    echo "==== end configuring proxy ===="
}

main(){
    echo "======== Start Installation ========"
    arch
    checkNet
    downloadGo
    installGo
    configPath
    echo "======== Finish installation ========"
}

main
