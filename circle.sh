#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6189010 clang
git clone --depth=1 https://github.com/orgesified/gccarm gcc
git clone --depth=1 https://github.com/orgesified/gcc64
git clone --depth=1 https://github.com/orgesified/AnyKernel3
echo "Done"
KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
TIME=$(date +"%H-%d%m%Y")
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
export CROSS_COMPILE_ARM32=${KERNEL_DIR}/gcc/bin/arm-linux-androideabi-
#export CROSS_COMPILE=${KERNEL_DIR}/gcc64/bin/aarch64-linux-android-
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc64/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=orges
export KBUILD_BUILD_HOST=orges
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgQAAxkBAAIo_l5MYYN3ZMtZj081xnZB8p5GiX8oAAKBAANZAAHcHOvLDn79czuGGAQ" \
        -d chat_id="$chat_id"
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="New build available!%0ADevice : <code>Xiaomi Redmi Note 5</code>%0ALinux version : <code>$KERNEL</code>%0ABranch : <code>${BRANCH}</code>%0ACommit Point : <code>$(git log --pretty=format:'"%h : %s"' -1)</code>"
}
# Push kernel to channel
function push() {
    cd AnyKernel3 || exit 1
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id"
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chatboi" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build threw error(s)"
    LOG=log.txt
    curl -F document=@$LOG "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id"
    exit 1
}
# Build Success
function buildsucs() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chatboi" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build Success. Congratulations!"
}
# Compile plox
function compile() {
    make -j$(nproc) O=out ARCH=arm64 whyred-perf_defconfig
    make -j$(nproc) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- 2>&1 | tee log.txt

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    buildsucs
    cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
}
# Zipping
function zipping() {
    cd AnyKernel3 || exit 1
    zip -r9 IceColdR6_${TIME}.zip *
    cd ..
}
compile
zipping
sticker
KERNEL=$(cat out/.config | grep Linux/arm64 | cut -d " " -f3)
sendinfo
push 
