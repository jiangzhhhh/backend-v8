#!/bin/bash

VERSION=$1
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE="$( cd "$( dirname "$0" )"/.. && pwd )"

if [ "$VERSION" == "10.6.194" ]; then 
    sudo apt-get install -y \
        pkg-config \
        git \
        subversion \
        curl \
        wget \
        build-essential \
        python3 \
        ninja-build \
        xz-utils \
        zip
        
    pip install virtualenv
else
    sudo apt-get install -y \
        pkg-config \
        git \
        subversion \
        curl \
        wget \
        build-essential \
        python \
        xz-utils \
        zip
fi

cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
if [ "$VERSION" != "10.6.194" ]; then 
    cd depot_tools
    git reset --hard 8d16d4a
    cd ..
fi
export DEPOT_TOOLS_UPDATE=0
if [ "$VERSION" == "10.6.194" ]; then 
    export PATH=$(pwd)/depot_tools:$PATH
else
    export PATH=$(pwd)/depot_tools:$(pwd)/depot_tools/.cipd_bin/2.7/bin:$PATH
fi
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['linux']" >> .gclient
cd ~/v8/v8
git checkout refs/tags/$VERSION
gclient sync

# echo "=====[ Patching V8 ]====="
# git apply --cached $GITHUB_WORKSPACE/patches/builtins-puerts.patches
# git checkout -- .

echo "=====[ add ArrayBuffer_New_Without_Stl ]====="
node $GITHUB_WORKSPACE/node-script/add_arraybuffer_new_without_stl.js .

echo "=====[ Building V8 ]====="

if [ "$VERSION" == "10.6.194" ]; then 
    python ./tools/dev/v8gen.py x64.release -vv -- '
    is_debug = false
    v8_enable_i18n_support= false
    v8_use_snapshot = true
    v8_use_external_startup_data = false
    v8_static_library = true
    strip_debug_info = true
    symbol_level=0
    libcxx_abi_unstable = false
    v8_enable_pointer_compression=false
    v8_enable_sandbox = false
    '
else
    python ./tools/dev/v8gen.py x64.release -vv -- '
    is_debug = false
    v8_enable_i18n_support= false
    v8_use_snapshot = true
    v8_use_external_startup_data = false
    v8_static_library = true
    strip_debug_info = true
    symbol_level=0
    libcxx_abi_unstable = false
    v8_enable_pointer_compression=false
    '
fi

ninja -C out.gn/x64.release -t clean
ninja -C out.gn/x64.release wee8

mkdir -p output/v8/Lib/Linux
cp out.gn/x64.release/obj/libwee8.a output/v8/Lib/Linux/
mkdir -p output/v8/Inc/Blob/Linux

