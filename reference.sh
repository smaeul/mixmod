#!/bin/bash
#
# mevmod.sh
# Script to compile Mevordel's JB firmware mod
# Copyright (c) 2013 Samuel Holland <mevordel@gmail.com>
# MIT Licensed
#

# Files and directories to copy (recursively) from the Google apps package
GAPPS_LIST="lib/libjni_latinime.so" # For swipe keyboard

# Parts of the NOGAPPS project to download
# (for now, only location and store work.)
NOGAPPS_LIST="NetworkLocation BlankStore"

# Inverted apps from www.rujelus22.com
# Only those that download APKs (NOT ZIPS) work!
INVERT_LIST=""

# List of domains to exclude from /system/etc/hosts
DOMAIN_WHITELIST="click.linksynergy.com *bitcointalk.org s3.amazonaws.com pastie.org"

# DSP/Equalizer app to use from the NexusLouder package
# (the other is deleted). Must be 'eizo', 'beats', or 'none'
DSP_APP=none

# This list is additional apks found in gapps and stock
GOOGLE_DELETE_LIST="
	app/Books.apk
	app/ChromeBookmarksSyncAdapter.apk
	app/ConfigUpdater.apk
	app/Currents.apk
	app/FaceLock.apk
	app/GenieWidget.apk
	app/Gmail2.apk
	app/GmsCore.apk
	app/GoogleBackupTransport.apk
	app/GoogleCalendarSyncAdapter.apk
	app/GoogleContactsSyncAdapter.apk
	app/GoogleEars.apk
	app/GoogleEarth.apk
	app/GoogleFeedback.apk
	app/GoogleLoginService.apk
	app/GooglePartnerSetup.apk
	app/GoogleServicesFramework.apk
	app/GoogleTTS.apk
	app/LatinImeDictionaryPack.apk
	app/Magazines.apk
	app/Maps.apk
	app/MediaUploader.apk
	app/Music2.apk
	app/NetworkLocation.apk
	app/Phonesky.apk
	app/PlusOne.apk
	app/PrebuiltGmsCore.apk
	app/SetupWizard.apk
	app/Street.apk
	app/Talk.apk
	app/Velvet.apk
	app/VideoEditorGoogle.apk
	app/Videos.apk
	app/Wallet.apk
	app/YouTube.apk"

# Files to delete from /system
DELETE_LIST="
	app/BackupRestoreConfirmation.apk
	app/BasicDreams.apk
	app/CleanMaster.apk
	app/CMAccount.apk
	app/CMFileManager.apk
	app/CMWallpapers.apk
	app/DSPManager.apk
	app/Email2.apk
	app/Exchange2.apk
	app/Galaxy4.apk
	app/GooManager.apk
	app/HTMLViewer.apk
	app/HoloSpiralWallpaper.apk
	app/Launcher2.apk
	app/LiveWallpapers.apk
	app/MagicSmokeWallpapers.apk
	app/Microbes.apk
	app/NoiseField.apk
	app/NovaLauncher.apk
	app/OpenWnn.apk
	app/ParanoidWallpapers.apk
	app/PhaseBeam.apk
	app/PhotoTable.apk
	app/PinyinIME.apk
	app/Provision.apk
	app/QuickSearchBox.apk
	app/SharedStorageBackup.apk
	app/SlimFileManager.apk
	app/SlimIRC.apk
	app/talkback.apk
	app/Talkback.apk
	app/Thinkfree.apk
	app/Trebuchet.apk
	app/UnicornPorn.apk
	app/VideoEditor.apk
	app/VisualizationWallpapers.apk
	app/VoicePlus.apk
	app/VoiceSearchStub.apk"
#	$GOOGLE_DELETE_LIST"

echo 'Initializing...'
	ZIPDIR=$(mktemp -d)
	CACHE=${HOME}/.cache/mevmod
	mkdir -p ${ZIPDIR}/system/{addon.d,app} \
		 ${ZIPDIR}/system/etc/init.d \
		 ${ZIPDIR}/META-INF/com/google/android
	mkdir -p ${CACHE}/{gapps,nogapps,inverts,apps,louder}

echo 'Downloading and unpacking required files...'
echo '  --> Google Apps'
	_gapps=gapps-jb-$(wget -q 'http://goo.im/json2&action=gapps' -O - | sed 's/.*jb42","ro_version":"\(2013[01][0-9][0-3][0-9]\).*/\1/')-signed.zip
	test -e ${CACHE}/${_gapps} || wget -q "http://goo.im/gapps/${_gapps}" -O ${CACHE}/${_gapps}
	test -e ${CACHE}/gapps/META-INF || unzip -qq ${CACHE}/${_gapps} -d ${CACHE}/gapps
	unset _gapps
	for file in ${GAPPS_LIST}
	do
		mkdir -p $(dirname ${ZIPDIR}/system/${file})
		cp -rf ${CACHE}/gapps/system/${file} ${ZIPDIR}/system/${file}
	done
echo '  --> NOGApps'
	wget -q 'http://forum.xda-developers.com/showpost.php?p=27522482' -O ${CACHE}/nogapps.list
	for app in ${NOGAPPS_LIST}
	do
		case ${app} in
			*ocation) _dh=$(grep 'quote.*NetworkLocation' -A1 -m1 ${CACHE}/nogapps.list | cut -d\" -f2 -s) ;;
			*tore) _dh=$(grep 'ICS/JB-ONLY' -A3 -m1 ${CACHE}/nogapps.list | tail -n1 | cut -d\" -f2 -s) ;;
			*) _dh='' ;;
		esac
		if [ ! -z ${_dh} ]
		then
			_apk=$(wget -q "${_dh}" -O - | grep -m1 'http://fs' | cut -d\" -f 4)
			# test -e ${CACHE}/nogapps/$(basename ${_apk}) || # The filenames are the same for every version...
			wget -q "${_apk}" -P ${CACHE}/nogapps
			cp ${CACHE}/nogapps/$(basename ${_apk}) -t ${ZIPDIR}/system/app
		fi
	done
	unset _dh _apk
echo '  --> Inverted Apps'
	wget -q 'http://www.rujelus22.com/evo/m/downloads.php' -O ${CACHE}/inverts.list
	for app in ${INVERT_LIST}
	do
		_invert=$(cat ${CACHE}/inverts.list | grep -A1 'Newest Version' | cut -d\" -f2 -s | grep -i "${app}")
		test -e ${CACHE}/inverts/$(basename "${_invert}") || wget -q "${_invert}" -P ${CACHE}/inverts
		cp -f ${CACHE}/inverts/$(basename "${_invert}") -t ${ZIPDIR}/system/app
	done
	unset _invert
echo '  --> Other Apps'
	# Always download these as they link to the latest version
	wget -q 'http://f-droid.org/FDroid.apk' -P ${ZIPDIR}/system/app
	wget -q 'http://apex.anddoes.com/Download.aspx' -O ${ZIPDIR}/system/app/ApexLauncher.apk
echo "  --> Local-Only Apps"
	# Obviously, you have to have bought them to get the APKs
	cp ${CACHE}/InkaFM.apk -t ${ZIPDIR}/system/app
#	cp ${CACHE}/TricksterModKey.apk -t ${ZIPDIR}/system/app
echo "  --> Hosts List"
	# Gecko because this site blocks wget
	test -e ${CACHE}/hosts || wget -q --user-agent Gecko 'http://adblock.mahakala.is' -O ${CACHE}/hosts
	# Convert whitespace to spaces
	_whitelist=$(echo ${DOMAIN_WHITELIST} | sed 's/ /|	/g')
	# Copy file while allowing certain useful domains
	grep -vE "(	${_whitelist})" ${CACHE}/hosts > ${ZIPDIR}/system/etc/hosts
	unset _whitelist
echo '  --> NexusLouder Package'
	wget -q 'http://forum.xda-developers.com/showpost.php?p=28220627' -O ${CACHE}/louder.list
	_file=$(grep '\.zip' ${CACHE}/louder.list | tail -n2 | head -n1 | cut -d\> -f3 | cut -d\< -f1)
	test -e ${CACHE}/${_file} || wget -q "http://forum.xda-developers.com/$(grep '\.zip' ${CACHE}/louder.list | tail -n2 | head -n1 | cut -d\" -f2 | sed 's/&amp;/\&/g')" -O ${CACHE}/${_file}
	test -e ${CACHE}/louder/META-INF || unzip -qq ${CACHE}/${_file} -d ${CACHE}/louder
	unset _file
	for dir in $(ls -1 ${CACHE}/louder/system)
	do
		cp -r ${CACHE}/louder/system/${dir} -t ${ZIPDIR}/system
	done
	head -n-7 ${CACHE}/louder/tweaks.sh > ${ZIPDIR}/louder.sh
	[ $DSP_APP != beats ] && rm -f ${ZIPDIR}/system/app/AwesomeBEATS.apk
	[ $DSP_APP = eizo ] && cp ${CACHE}/louder/data/app/com.noozxoidelabs.eizo.rewirepro.*.apk ${ZIPDIR}/system/app/EIZORewirePro.apk
echo '  --> Updater Binary'
	# Use the one from the GAPPS package
	cp ${CACHE}/gapps/META-INF/com/google/android/update-binary -t ${ZIPDIR}/META-INF/com/google/android
echo "Generating build-specific configuration..."
echo "  --> Init.d Scripts"
	# This removes the need for Google's SetupWizard or com.android.provision
	cat <<-"END" >> "${ZIPDIR}/system/etc/init.d/99provision"
		#!/system/bin/sh
		sqlite3 /data/data/com.android.providers.settings/databases/settings.db "BEGIN TRANSACTION; DELETE FROM global WHERE name='device_provisioned'; INSERT INTO global(name,value) VALUES('device_provisioned','1'); DELETE FROM secure WHERE name='user_setup_complete'; INSERT INTO secure(name,value) VALUES('user_setup_complete','1'); COMMIT; VACUUM;"
	END
echo "  --> File Backup Script"
	cat <<-"END" > "${ZIPDIR}/system/addon.d/20-mevmod.sh"
		#!/sbin/sh
		#
		# /system/addon.d/20-mevmod.sh
		# During a firmware upgrade, this script backs up MevMod's files.
		# /system is formatted and reinstalled, then the files are restored.
		# Files from the delete list are also removed from the new firmware.
		#

		. /tmp/backuptool.functions

		list_files() {
		cat <<EOF
		END
	pushd "${ZIPDIR}" 2>&1 >/dev/null
	for file in $(find -type f | grep system)
	do
		echo "$file" | cut -d '/' -f 3- >> "${ZIPDIR}/system/addon.d/20-mevmod.sh"
	done
	popd 2>&1 >/dev/null
	cat <<-"END" >> "${ZIPDIR}/system/addon.d/20-mevmod.sh"
		EOF
		}

		list_deletes() {
		cat <<EOF
	END
	for file in ${DELETE_LIST}
	do
		echo "$file" >> "${ZIPDIR}/system/addon.d/20-mevmod.sh"
	done
	cat <<-"END" >> "${ZIPDIR}/system/addon.d/20-mevmod.sh"
		EOF
		}

		case "$1" in
		  backup)
		    list_files | while read FILE DUMMY; do
		      backup_file $S/"$FILE"
		    done
		  ;;
		  restore)
		    list_files | while read FILE REPLACEMENT; do
		      R=""
		      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
		      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
		    done
		  ;;
		  pre-backup)
		    # Stub
		  ;;
		  post-backup)
		    # Stub
		  ;;
		  pre-restore)
		    # Stub
		  ;;
		  post-restore)
		    list_deletes | while read FILE DUMMY; do
		      rm -f $S/"$FILE"
		    done
		    if [ -z $(grep NexusxLoud /system/build.prop) ]
		    then
	END
	grep echo ${CACHE}/louder/tweaks.sh >> ${ZIPDIR}/system/addon.d/20-mevmod.sh
	cat <<-"END" >> ${ZIPDIR}/system/addon.d/20-mevmod.sh
		    fi
		  ;;
		esac
	END
echo "  --> Updater-script"
	cat <<-"END" > "${ZIPDIR}/META-INF/com/google/android/updater-script"
		mount("ext4", "EMMC", "/dev/block/platform/omap/omap_hsmmc.0/by-name/system", "/system");

		set_progress(0.25);
		ui_print("Deleting junk...");
	END
	for file in ${DELETE_LIST}
	do
		echo "delete(\"/system/${file}\");" >> "${ZIPDIR}/META-INF/com/google/android/updater-script"
	done
	cat <<-"END" >> "${ZIPDIR}/META-INF/com/google/android/updater-script"

		set_progress(0.50);
		ui_print("Extracting new files...");
		package_extract_dir("system", "/system");

		set_progress(0.75);
		ui_print("Configuring...");
		package_extract_file("louder.sh", "/tmp/louder.sh");
		set_perm(0, 0, 0755, "/tmp/louder.sh");
		run_program("/tmp/louder.sh");

		ui_print("Cleaning up...");
		set_perm(0, 0, 0755, "/system/addon.d/20-mevmod.sh");
		set_perm_recursive(0, 0, 0755, 0644, "/system/app");
		set_perm(0, 0, 0644, "/system/etc/hosts");
		set_perm_recursive(0, 0, 0755, 0755, "/system/etc/init.d");

		set_progress(1.0);
		ui_print("Done!");
		unmount("/system");
	END
echo "Compressing Zipfile..."
	pushd "${ZIPDIR}" 2>&1 >/dev/null
	zipfile=MevMod-$(date +%F).zip
	zip -q -r -9 "${zipfile}" *
	popd 2>&1 >/dev/null
	mv "${ZIPDIR}/${zipfile}" .
echo "Cleaning Up..."
	rm -rf "${ZIPDIR}"
echo "Done! Enjoy :)"
