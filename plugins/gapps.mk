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
# This plugin downloads and extracts a Google Apps package from goo.im/Rootz,
# ParanoidAndroid, or a custom location.


ifeq ($(GAPPS_ENABLED),yes)

# Set default configuration
GAPPS_SOURCE	?= pa

ifeq ($(GAPPS_SOURCE),pa)
  ifneq ($(filter 4.4%,$(ANDROID_VERSION)),)
    gapps_zip := $(CACHE_DIR)/$(shell wget -q "http://goo.im/json2&path=/devs/paranoidandroid/roms/gapps-mini" \
      -O - | grep -o "pa_gapps-modular-mini-$(ANDROID_VERSION)-[0-9]\{8\}-signed.zip" | sort | tail -n1)
    GAPPS_CUSTOM_URL := http://goo.im/devs/paranoidandroid/roms/gapps-mini/$(notdir $(gapps_zip))
  else ifneq ($(filter 4.3%,$(ANDROID_VERSION)),)
    gapps_zip := $(CACHE_DIR)/pa_gapps-modular-mini-4.3-20131024-signed.zip
    $(error GAPPS: Unfortunately, 4.3 PA Google Apps are not hosted in a friendly location. Please download them manually \
	and place them at $(gapps_zip))
  else
    $(error GAPPS: PA Google Apps are not available for your Android version.)
  endif
else ifeq ($(GAPPS_SOURCE),goo)
  ifneq ($(filter 4.3%,$(ANDROID_VERSION)),)
    GAPPS_CUSTOM_URL := http://goo.im/gapps/gapps-jb-20130813-signed.zip
  else ifneq ($(filter 4.2%,$(ANDROID_VERSION)),)
    GAPPS_CUSTOM_URL := http://goo.im/gapps/gapps-jb-20130812-signed.zip
  else ifneq ($(filter 4.1%,$(ANDROID_VERSION)),)
    GAPPS_CUSTOM_URL := http://goo.im/gapps/gapps-jb-20121011-signed.zip
  else ifneq ($(filter 4.0%,$(ANDROID_VERSION)),)
    GAPPS_CUSTOM_URL := http://goo.im/gapps/gapps-ics-20120429-signed.zip
  else
    $(error GAPPS: Goo.im Google Apps are not available for your Android version.)
  endif
  gapps_zip := $(CACHE_DIR)/$(notdir $(GAPPS_CUSTOM_URL))
endif

ifeq ($(GAPPS_CUSTOM_URL),)
  $(error GAPPS: No download URL specified!)
endif

gapps_files_dir	:= $(TMPDIR)/gapps_files

# Add ourselves to the plugin and directory lists
ALL_PLUGINS	+= gapps
ALL_DIRS	+= $(gapps_files_dir)

# Main goal
gapps: gapps_files | $(SYSTEM_DIR)
	cp -r $(gapps_files_dir)/system/* $(SYSTEM_DIR)

# Other rules
# Note: gapps_zip is an order-only dependency so it is not redownloaded
gapps_files: | $(gapps_zip) $(gapps_files_dir)
	unzip -qq $(gapps_zip) -d $(gapps_files_dir)

$(gapps_zip): | $(CACHE_DIR)
	$(DOWNLOAD_CMD) -O $@ $(GAPPS_CUSTOM_URL)

endif
