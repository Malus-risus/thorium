#!/bin/bash
#
# Copyright (c) 2024 The Chromium Authors and Alex313031. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Let the wrapped binary know that it has been run through the wrapper.
export CHROME_WRAPPER="`readlink -f "$0"`"

HERE="`dirname "$CHROME_WRAPPER"`"

# We include some xdg utilities next to the binary, and we want to prefer them
# over the system versions when we know the system versions are very old. We
# detect whether the system xdg utilities are sufficiently new to be likely to
# work for us by looking for xdg-settings. If we find it, we leave $PATH alone,
# so that the system xdg utilities (including any distro patches) will be used.
if ! which xdg-settings &> /dev/null; then
  # Old xdg utilities. Prepend $HERE to $PATH to use ours instead.
  export PATH="$HERE:$PATH"
else
  # Use system xdg utilities. But first create mimeapps.list if it doesn't
  # exist; some systems have bugs in xdg-mime that make it fail without it.
  xdg_app_dir="${XDG_DATA_HOME:-$HOME/.local/share/applications}"
  mkdir -p "$xdg_app_dir"
  [ -f "$xdg_app_dir/mimeapps.list" ] || touch "$xdg_app_dir/mimeapps.list"
fi

# Always use our versions of ffmpeg libs.
# This also makes RPMs find the compatibly-named library symlinks.
if [[ -n "$LD_LIBRARY_PATH" ]]; then
  LD_LIBRARY_PATH="$HERE:$HERE/lib:$LD_LIBRARY_PATH"
else
  LD_LIBRARY_PATH="$HERE:$HERE/lib"
fi
export LD_LIBRARY_PATH

# APPNAME for GTK.
APPNAME=thorium

# Set DESKTOP variable
# DESKTOP="thorium-browser-stable"

# Set XDG Title variable
TITLE="Thorium Portable"

# Set the correct file name for the desktop file
export CHROME_DESKTOP="thorium-portable.desktop"

# Set CHROME_VERSION_EXTRA text, which is displayed in the About dialog on chrome://help
DIST=`cat /etc/debian_version`
export CHROME_VERSION_EXTRA="stable, (Portable)"

# We don't want bug-buddy intercepting our crashes. http://crbug.com/24120
export GNOME_DISABLE_CRASH_DIALOG=SET_BY_THORIUM

# Sanitize std{in,out,err} because they'll be shared with untrusted child
# processes (http://crbug.com/376567).
exec < /dev/null
exec > >(exec cat)
exec 2> >(exec cat >&2)

# Note: exec -a below is a bashism.
exec -a "$0" "$HERE/thorium" "--user-data-dir=$(pwd)/.config/thorium" "--disk-cache-dir=$(pwd)/.config/cache" "--disable-machine-id" "--disable-encryption" "$@"
