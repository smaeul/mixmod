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

# Run `make DEVICE=<your_device_codename> zip' to generate your zip.

# Environment
ANDROID_VERSION	?= 4.4
CACHE_DIR	?= $(HOME)/.cache/mixmod
CONFIG_FILE	?= config.mk
DATE		:= $(shell date +%F)
DEVICE		?= hammerhead
DOWNLOAD_CMD	?= wget
TMPDIR		:= $(shell mktemp -u)

ALL_DIRS	:= $(CACHE_DIR) $(TMPDIR)
ALL_PLUGINS	:=

# Build location
BUILD_DIR	:= $(TMPDIR)/build
SYSTEM_DIR	:= $(BUILD_DIR)/system
BACKUP_DIR	:= $(SYSTEM_DIR)/addon.d
UPDATER_DIR	:= $(BUILD_DIR)/META_INF/com/google/android

ALL_DIRS	+= $(BUILD_DIR) $(SYSTEM_DIR) $(BACKUP_DIR) $(UPDATER_DIR)

# Generated files
BACKUP_SCRIPT	:= $(SYSTEM_DIR)/addon.d/60-mixmod.sh
UNSIGNED_ZIP	:= $(TMPDIR)/MixMod_unsigned.zip
UPDATE_BINARY	:= $(UPDATER_DIR)/update-binary
UPDATER_SCRIPT	:= $(UPDATER_DIR)/updater-script
ZIPFILE		:= MixMod_$(DEVICE)_$(DATE).zip


# Prebuilt source files
BAK_SCR_PARTS	:= $(foreach part,1,prebuilt/backup_script_part$(part))
UPD_BIN_SRC	:= prebuilt/update-binary
UPD_SCR_PARTS	:= $(foreach part,1,prebuilt/updater_script_part$(part))

# Include local config
# Note: If none exists, the default will be used with a warning.
include $(CONFIG_FILE)

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
zip: $(ZIPFILE)
	@rm -rf $(TMPDIR)
	@echo Zipfile finished: $(ZIPFILE)

clean:
	rm -rf $(CACHE_DIR) $(TMPDIR)

.PHONY: clean zip

# Rules - in reverse order of dependencies
$(ZIPFILE): $(UNSIGNED_ZIP)
	cp -f $< $@

$(UNSIGNED_ZIP): $(ALL_PLUGINS) $(BACKUP_SCRIPT) $(UPDATER_BINARY) $(UPDATER_SCRIPT)
	cd $(BUILD_DIR) && zip -q -r -9 $(UNSIGNED_ZIP) *

$(UPDATE_BINARY): $(UPD_BIN_SRC) | $(UPDATER_DIR)
	cp -f $< $@

$(UPDATER_SCRIPT): $(ALL_PLUGINS) $(BACKUP_SCRIPT) $(UPD_SCR_PARTS) | $(UPDATER_DIR)
	cat prebuilt/updater_script_part1 > $@

$(BACKUP_SCRIPT): $(ALL_PLUGINS) $(BAK_SCR_PARTS) | $(BACKUP_DIR)
	cat prebuilt/backup_script_part1 > $@

$(CONFIG_FILE): | config.default
	$(warn Using default config!)
	cp -f $| $@

$(ALL_DIRS): %:
	mkdir -p $@
