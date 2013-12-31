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
  GAPPS_CUSTOM_URL := $(shell echo foobar)
else ifeq ($(GAPPS_SOURCE),goo)
  GAPPS_CUSTOM_URL := gapps-jb-$(shell wget -q 'http://goo.im/json2&action=gapps' -O - | sed 's/.*jb42","ro_version":"\(2013[01][0-9][0-3][0-9]\).*/\1/')-signed.zip
endif

ifeq ($(GAPPS_CUSTOM_URL),)
  $(error GAPPS: No download URL specified!)
endif

gapps_files_dir	:= $(TMPDIR)/gapps_files
gapps_zip	:= $(CACHE_DIR)/gapps.zip

# Add ourselves to the plugin and directory lists
ALL_PLUGINS	+= gapps
ALL_DIRS	+= $(gapps_files_dir)

# Main goal
gapps: gapps_files | $(SYSTEM_DIR)
	cp -r $(gapps_files_dir)/* $(SYSTEM_DIR)

# Other rules
# Note: gapps_zip is an order-only dependency so it is not redownloaded
gapps_files: | $(gapps_zip) $(gapps_files_dir)
	unzip -qq $(gapps_zip) -d $(gapps_files_dir)

$(gapps_zip): | $(CACHE_DIR)
	$(DOWNLOAD_CMD) -O $@ $(GAPPS_CUSTOM_URL)

endif
