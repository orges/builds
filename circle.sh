#!/usr/bin/env bash
echo "Cloning dependencies"
#git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6189010 clang
git clone --depth=1 https://github.com/orgesified/gccarm gcc
git clone --depth=1 https://github.com/orgesified/gcc64
git clone https://github.com/z4nyx/AnyKernel3.git -b lavender --depth=1 AnyKernel
echo "Done"
KERNEL_DIR=$(pwd)
IMAGE="${KERNEL_DIR}/out/arch/arm64/boot/Image.gz-dtb"
TIME=$(date +"%H-%d%m%Y")
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
#PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
#export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_USER=orges
export KBUILD_BUILD_HOST=orges
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgEAAxkBAAEJRyNeLAQBsqsQ-nqCBK4Ph0FALp9LBwACKQADvi-SJaJf5A1MOFiHGAQ" \
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
                    ARCH=arm64

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
