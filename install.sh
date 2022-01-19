#!/usr/bin/env bash

# Install the latest go version

# Check system architecture
arch(){
    ARCH=$(uname -m)
    SYS=$(uname)

    if [[ $ARCH == "x86_64" ]] && [[ $SYS == "Linux" ]]; then
        DIS="linux-amd64"
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
    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    CUR_VERSION=$(go version | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    PACKAGE="go$VERSION.$DIS.tar.gz"
    
    if [[ "$CUR_VERSION" < "$VERSION" ]]; then
        if [[ ! -e $PACKAGE ]]; then
            echo "Download '${PACKAGE}' from '${URL}'..." 
            curl -LJ "$URL$PACKAGE" -o "$PACKAGE" --progress-bar
        else
            echo "The package already exists."
        fi
    else
        echo "The latest version is already installed!" >& 2
        exit 1 
    fi
}

# Install
installGo(){
    if [[ -d /usr/local/go/ ]]; then
        echo "Delete '/usr/local/go/'..."
        sudo rm -rf /usr/local/go/
    fi
    echo "Untar '${PACKAGE}'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"
}

# Configure Path
configPath(){
    SHPATH=$(env | grep "SHELL")
    if [[ $SHPATH =~ "zsh" ]]; then
        SHFILE=".zshrc"
    elif [[ $SHPATH =~ "bash" ]]; then
        SHFILE=".bashrc"
    fi

    if [[ -e ~/$SHFILE && $(grep -c "GOPATH" ~/$SHFILE) -eq 0 ]]; then
        echo "Configure path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go/"
            echo "export GOPATH=\$HOME/.gopath/"
            echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin"
            echo
        } >> ~/$SHFILE
        # shellcheck source=/dev/null
        source ~/${SHFILE}
    else
        echo "Go configuration already exists, skip..."
    fi
}

# Configure proxy
configProxy(){
    if [[ ! $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        echo "Configure proxy..."
        go env -w GO111MODULE=on
        go env -w GOPROXY=https://goproxy.cn,direct
    fi
}

main(){
    echo "====Start Installation===="
    arch
    checkNet
    downloadGo
    installGo
    configPath
    configProxy
    echo "====Finish installation===="
}

main
