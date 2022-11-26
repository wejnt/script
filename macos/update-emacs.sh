#!/bin/bash

CMD_HOME=$(dirname $(readlink $0))
BUILD_HOME=${HOME}/tmp/emacs

BRANCH="$1"
if [[ -d ${BUILD_HOME} ]]; then
    cd ${BUILD_HOME}
    # 判断是否是主分支并更新代码
    LOCAL="$(git branch)"
    if [[ $LOCAL =~ $BRANCH ]]; then
        git checkout $BRANCH
    elif [[ ! $LOCAL =~ "master" || ! $LOCAL =~ "main" ]]; then
        git checkout master || git checkout main
        if [[ -n $(git diff --stat) ]]; then
            echo "$(git status)"
            read -p "是否丢弃修改并拉取最新源码:" RESTORE
            if [ "y" == ${RESTORE} ]; then
                git restore .
            fi
        fi
        git pull
    fi
    ./autogen.sh
else
    # Clone Emacs仓库
    git clone git://git.sv.gnu.org/emacs.git ${BUILD_HOME} || exit 1
    cd $BUILD_HOME || exit 1 && ./autogen.sh
fi

read -p "是否开始编译:" BUILD
if [[ -n $BUILD && ! "y" == $BUILD ]];then
    exit 1
fi

if [[ -n $(gmake clean) ]]; then
    echo "cleaning for repository... yes"
fi

./configure \
    --with-ns \
    --with-native-compilation=aot \
    --with-pop \
    --with-mailutils \
    --with-json \
    --without-dbus \
    --without-compress-install \
    --with-gconf \
    --enable-profiling

NCPU=`expr $(getconf _NPROCESSORS_ONLN) + 1`
make bootstrap -j$NCPU || exit 1 && make install -j$NCPU

SERVER_CMD=${CMD_HOME}/emacs
CLIENT_CMD=${CMD_HOME}/ec

cp -r ${SERVER_CMD} ${BUILD_HOME}/nextstep/Emacs.app/Contents/MacOS/bin/
cp -r ${CLIENT_CMD} ${BUILD_HOME}/nextstep/Emacs.app/Contents/MacOS/bin/

chmod 755 ${BUILD_HOME}/nextstep/Emacs.app/Contents/MacOS/bin/emacs
chmod 755 ${BUILD_HOME}/nextstep/Emacs.app/Contents/MacOS/bin/ec

# Copy C source files to Emacs
cp -r ${BUILD_HOME}/src ${BUILD_HOME}/nextstep/Emacs.app/Contents/Resources/

# 关闭Emacs App
pkill -i emacs

# 删除旧版本的app
if [ -e /Applications/Emacs.app ]; then
    if [ command -v trash </dev/null 2>&1 ]; then
        echo "Trashing old emacs..."
        trash /Applications/Emacs.app
    else
        echo "Removing old emacs..."
        rm -rf /Applications/Emacs.app
    fi
fi

# Move build to applications folder
mv ${BUILD_HOME}/nextstep/Emacs.app /Applications

echo "DONE!"

echo "
# ======================================================
# Add executables to path
#
# Be sure to add /Applications/Emacs.app/Contents/MacOS/bin
# to your .zshrc or .profile path like so:
# export PATH=\$PATH:/Applications/Emacs.app/Contents/MacOS/bin
# ======================================================"

if [[ -z $(awk -F ":" '$NF ~ "Applications/Emacs.app" {print $NF}' $HOME/.zshrc) ]]; then
    echo "PATH=\$PATH:/Applications/Emacs.app/Contents/MacOS/bin" >> $HOME/.zshrc
    export PATH=$PATH:/Applications/Emacs.app/Contents/MacOS/bin
else
    source $HOME/.zshrc
fi

echo "
# ======================================================
# Open new emacs server by daemon
# ======================================================"
/Applications/Emacs.app/Contents/MacOS/bin/emacs --daemon

echo "Build script finished!"
