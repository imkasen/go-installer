#!/usr/bin/env bash

# Install the latest go version
GOROOT=/usr/local/go/

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
            echo "Download '${PACKAGE}' from '${URL}'." 
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
    if [[ -d ${GOROOT} ]]; then
        echo "Delete '${GOROOT}'..."
        sudo rm -rf ${GOROOT}
    fi
    echo "Untar '${PACKAGE}'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"
}

main(){
    echo "====Start Installation===="
    arch
    checkNet
    downloadGo
    installGo
    echo "====Finish installation===="
}

main
