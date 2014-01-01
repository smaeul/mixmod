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
# This plugin uses the backup/updater script to set a custom DPI

ifeq ($(DPI_ENABLED),yes)

# Set default configuration
DPI_VALUE	?= 400

# Add our line to the backup script
backup_post_res	+= \
sed -i -e '/lcd_density/s/[0-9]\{3\}/$(DPI_VALUE)/' /system/build.prop

# Add our line to the updater script
update_scr_cmds	+= \
run_program("/system/bin/sed", "-i", "-e", "/lcd_density/s/[0-9]\{3\}/$(DPI_VALUE)/", "/system/build.prop");

endif
