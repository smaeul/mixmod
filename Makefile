# Copyright (c) 2013 Samuel Holland <samuel@sholland.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# Run `make DEVICE=<your_device_codename> download' to download prerequisites.
# Run `make DEVICE=<your_device_codename> zip' to generate your zip.

# Environment
ANDROID_VERSION	?= 4.4.2
DEVICE		?= hammerhead

# Source Locations
backup_scr_src	:= $(wildcard prebuilt/backup_script_part*)
config_date	:= $(shell date +%F)
config_file	= config.mk
update_bin_src	= prebuilt/update-binary

# Output Locations
backup_script	= $(dir_system)/addon.d/60-mixmod.sh
dir_backup	= $(dir_system)/addon.d
dir_cache	= $(HOME)/.cache/mixmod
dir_system	= $(dir_zip)/system
dir_tmp		= /tmp/tmpdir.mixmod
dir_update	= $(dir_zip)/META-INF/com/google/android
dir_zip		= $(dir_tmp)/build
zip_unsigned	= $(dir_tmp)/mixmod_unsigned.zip
zip_final	= mixmod_$(DEVICE)_$(ANDROID_VERSION)_$(config_date).zip
update_binary	= $(dir_update)/update-binary
update_script	= $(dir_update)/updater-script

# Initialize Lists
ALL_DIRS	:= $(dir_backup) $(dir_cache) $(dir_system) $(dir_tmp) $(dir_update) $(dir_zip)
ALL_DOWNLOADS	:=
ALL_PLUGINS	:=

# Include local config
# Note: If none exists, the default will be used with a warning.
include $(config_file)

# Include device config
# Note: If it does not exist, this will produce an error. Some things, like
#       partitions, *must* be defined on a per-device basis.
include devices/$(DEVICE).mk

# Include plugins
include plugins/*.mk

# Sanity check
ifeq ($(DEVICE_PART_SYSTEM),)
  $(error System partition undefined! Check device config.)
endif

# Goals
.PHONY: download zip tidy clean

download: $(ALL_DOWNLOADS) | $(dir_cache)
	@echo "All downloads complete! Now run 'make zip'"

zip: $(zip_final)
	@echo Zipfile finished: $(zip_final)

tidy:
	rm -rf $(dir_tmp)

clean:
	rm -rf $(dir_cache) $(dir_tmp)

# Rules - in somewhat reverse order of dependencies
$(zip_final): $(zip_unsigned)
	cp -f $< $@

$(zip_unsigned): $(ALL_PLUGINS) $(backup_script) $(update_binary) $(update_script) | $(dir_tmp)
	cd $(dir_zip) && zip -q -r -9 $@ *

$(update_binary): $(update_bin_src) | $(dir_update)
	cp -f $< $@

export update_scr_del update_scr_ext update_scr_cmds update_scr_perm
$(update_script): $(ALL_PLUGINS) $(backup_script) | $(dir_update)
	echo 'mount("ext4", "EMMC", "$(DEVICE_PART_SYSTEM)", "/system");' > $@
	echo 'set_progress(0.25);' >> $@
	echo 'ui_print("Deleting junk...");' >> $@
	printf "$$update_scr_del\n" >> $@
	echo 'set_progress(0.50);' >> $@
	echo 'ui_print("Extracting new files...");' >> $@
	echo 'package_extract_dir("system", "/system");' >> $@
	printf "$$update_scr_ext\n" >> $@
	echo 'set_progress(0.75);' >> $@
	echo 'ui_print("Configuring...");' >> $@
	printf "$$update_scr_cmds\n" >> $@
	echo 'ui_print("Cleaning up...");' >> $@
	echo 'set_perm(0, 0, 0755, "/system/addon.d/60-mixmod.sh");' >> $@
	printf "$$update_scr_perm\n" >> $@
	echo 'set_progress(1.0);' >> $@
	echo 'ui_print("Done!");' >> $@
	echo 'unmount("/system");' >> $@

export backup_files backup_deletes backup_pre_bak backup_post_bak backup_pre_res backup_post_res
$(backup_script): $(ALL_PLUGINS) $(backup_scr_src) | $(dir_backup)
	cat prebuilt/backup_script_part1 > $@
	printf "$$backup_files\n" >> $@
	cat prebuilt/backup_script_part2 >> $@
	printf "$$backup_deletes\n" >> $@
	cat prebuilt/backup_script_part3 >> $@
	printf "$$backup_pre_bak\n" >> $@
	cat prebuilt/backup_script_part4 >> $@
	printf "$$backup_post_bak\n" >> $@
	cat prebuilt/backup_script_part5 >> $@
	printf "$$backup_pre_res\n" >> $@
	cat prebuilt/backup_script_part6 >> $@
	printf "$$backup_post_res\n" >> $@
	cat prebuilt/backup_script_part7 >> $@

$(config_file): config.default
	$(warn Using default config!)
	cp -f $< $@

# Static rule to make directories
$(ALL_DIRS): %:
	mkdir -p $@
