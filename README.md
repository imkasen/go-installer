# Go Installation Script

Automatically install the latest version of Go.

* Supported Linux: **Ubuntu** / **Debian** or **any** distribution based on them.

## How to install / update

### Online

``` Bash
# default
curl -fsL https://raw.githubusercontent.com/imkasen/go-installer/master/install.sh | bash

# fastgit proxy
curl -fsL https://raw.fastgit.org/imkasen/go-installer/master/install.sh | bash
```

### Offline

Save the script as a file named `install.sh`

``` Bash
bash install.sh
```

## How it works

The script is based on the official installation instruction from [Go Docs](https://go.dev/doc/install).

1. Search for the latest binary release and download it.
    * *People in Mainland China will use the URL `https://golang.google.cn/dl/`.*
2. The release will be installed at `/usr/local/go`.
3. The `GOPATH` will be added to `PATH`.
   * *People in Mainland China will be added a `GOPROXY` setting*

## LICENSE

[GPL v3](https://www.gnu.org/licenses/gpl-3.0.html)
