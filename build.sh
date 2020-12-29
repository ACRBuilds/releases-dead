#!/bin/bash
export DRONE_BUILD_EVENT=tag
export outdir="${ROM_DIR}/out/target/product/${device}"
BUILD_START=$(date +"%s")
echo "Build started for ${device}"
if [ "${jenkins}" == "true" ]; then
	telegram -M "Build ${BUILD_DISPLAY_NAME} started for ${device}: [See Progress](${BUILD_URL}console)"
else
	telegram -M "Build started for ${device}"
fi
source build/envsetup.sh
source "${my_dir}/${my_txt}"
# Save devicename for overite (2/2)
export device=$device_real
source "${my_dir}/sourceforgeconfig.sh"
if [ "${official}" == "true" ]; then
	export CUSTOM_BUILD_TYPE="OFFICIAL"
fi
if [ -z "${buildtype}" ]; then
	export buildtype="userdebug"
fi
if [ "${ccache}" == "true" ] && [ -n "${ccache_size}" ]; then
	export USE_CCACHE=1
	ccache -M "${ccache_size}G"
elif [ "${ccache}" == "true" ] && [ -z "${ccache_size}" ]; then
	echo "Please set the ccache_size variable in your config."
	exit 1
fi
lunch "${rom_vendor_name}_${device}-${buildtype}"
rm "${outdir}"/*2020*.zip
rm "${outdir}"/*2020*.zip.md5
if [ "${clean}" == "clean" ]; then
	mka clean
	mka clobber
elif [ "${clean}" == "installclean" ]; then
	mka installclean
fi
mka "${bacon}"
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))

export finalzip_path=$(ls "${outdir}"/*2020*.zip | tail -n -1)
if [ "${upload_recovery}" == "true" ]; then
	export img_path=$(ls "${outdir}"/recovery.img | tail -n -1)
fi
if [ "${upload_boot}" == "true" ]; then
	export boot_path=$(ls "${outdir}"/boot.img | tail -n -1)
fi

export zip_name=$(echo "${finalzip_path}" | sed "s|${outdir}/||")
export tag=$( echo "${zip_name}-$(date +%H%M)" | sed 's|.zip||')
if [ -e "${finalzip_path}" ]; then
	echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

	echo "Uploading ROM to Github https://github.com/${release_repo}/releases/download/${tag}/${zip_name}"

	github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

	Date: $(env TZ="${timezone}" date)" "${finalzip_path}"

	echo "Uploading ROM to Gitea ${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/${zip_name}"

	drone-gitea-release --api-key "${GITEA_TOKEN}" --repo.owner "${repo_owner}" --repo.name "${repo_name}"  --commit.ref "${tag}" --base-url "${gitea_url}"  -title "${tag}" --note "${ROM} for ${device} Date: $(env TZ="${timezone}" date)" --files "${finalzip_path}"

	if [ "${upload_recovery}" == "true" ]; then
		if [ -e "${img_path}" ]; then
			echo

			"Uploading recovery to Gitea ${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/recovery.img"

			drone-gitea-release --api-key "${GITEA_TOKEN}" --repo.owner "${repo_owner}" --repo.name "${repo_name}"  --commit.ref "${tag}" --base-url "${gitea_url}"  --title "${tag}" --note "${ROM} for ${device} Date: $(env TZ="${timezone}" date)" --files "${img_path}"

			echo "Uploading recovery to Github https://github.com/${release_repo}/releases/download/${tag}/recovery.img"

			github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

			Date: $(env TZ="${timezone}" date)" "${img_path}"

		else
			echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
			telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
			curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
			exit 1
		fi
	fi

	if [ "${upload_boot}" == "true" ]; then
		if [ -e "${boot_path}" ]; then
			echo

			"Uploading recovery to Gitea ${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/boot.img"

			drone-gitea-release --api-key "${GITEA_TOKEN}" --repo.owner "${repo_owner}" --repo.name "${repo_name}"  --commit.ref "${tag}" --base-url "${gitea_url}"  --title "${tag}" --note "${ROM} for ${device} Date: $(env TZ="${timezone}" date)" --files "${boot_path}"

			echo "Uploading recovery to Github https://github.com/${release_repo}/releases/download/${tag}/boot.img"

			github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

			Date: $(env TZ="${timezone}" date)" "${boot_path}"

		else
			echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
			telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
			curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
			exit 1
		fi
	fi




	echo "Uploaded"


	if [ "${upload_recovery}" == "true" ]; then
		telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

		Download ROM via Gitea: ["${zip_name}"]("${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/${zip_name}")
		Download ROM via Github: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
		Download recovery via Gitea: ["recovery.img"]("${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/recovery.img")
		Download recovery via Github: ["recovery.img"]("https://github.com/${release_repo}/releases/download/${tag}/recovery.img")"
	elif [ "${upload_boot}" == "true" ]; then
		telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

		Download ROM via Gitea: ["${zip_name}"]("${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/${zip_name}")
		Download ROM via Github: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
		Download boot via Gitea: ["boot.img"]("${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/boot.img")
		Download boot via Github: ["boot.img"]("https://github.com/${release_repo}/releases/download/${tag}/boot.img")"
	else
		telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

		Download ROM via Github: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
		Download ROM via Gitea: ["${zip_name}"]("${gitea_url}/${repo_owner}/${repo_name}/releases/download/${tag}/${zip_name}")"
	fi
	curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker

else
	echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
	telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
	curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
	exit 1
fi
