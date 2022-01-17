#!/bin/bash
echo "Sync started for ${manifest_url}/tree/${branch}"
if [ "${jenkins}" == "true" ]; then
    telegram -M "Синхронизация [${ROM} ${ROM_VERSION}](${manifest_url}/tree/${branch}) начата: [Подробнее](${BUILD_URL}console)"
else
    telegram -M "Синхронизация [${ROM} ${ROM_VERSION}](${manifest_url}/tree/${branch}) начата"
fi
SYNC_START=$(date +"%s")
if [ ! -d "${ROM_DIR}"/.repo ]; then
    repo init -u "${manifest_url}" -b "${branch}" --depth 1
fi
if [ "${official}" != "true" ]; then
    rm -rf .repo/local_manifests
    mkdir -p .repo/local_manifests
    wget "${local_manifest_url}" -O .repo/local_manifests/manifest.xml
fi
cores=$(nproc --all)
if [ "${cores}" -gt "12" ]; then
    cores=12
fi
repo sync --force-sync --no-tags --no-clone-bundle --optimized-fetch --prune "-j${cores}" -c -v
syncsuccessful="${?}"
SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))
if [ "${syncsuccessful}" == "0" ]; then
    echo "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    telegram -N -M "Синхронизация завершена успешно через $((SYNC_DIFF / 60)) минут(ы) $((SYNC_DIFF % 60)) секунд(ы)"
    source "${my_dir}/build.sh"
else
    echo "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    telegram -N -M "Синхронизация завершена с ошибкой через $((SYNC_DIFF / 60)) минут(ы) $((SYNC_DIFF % 60)) секунд(ы)"
    curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
    exit 1
fi
