#!/bin/bash

# Freeciv server version upgrade notes
# ------------------------------------
# 0056-establish_new_connection-Set-wrap_id-to-packet_set_t.patch
#   Fix regression introduced with the new separate wrap setting
#   osdn #45261
# 0026-place_unit-Do-not-add-NoHome-units-to-city-s-units_s
#   Fix recent regression in creation of NoHome units
#   osdn #45196
# 0001-fcmp-Fix-vulnerability-with-crafted-modpack-URLs
#   Fix modpack installer vulnerability
#   osdn #45299
# 0045-Apply-fix-to-CVE-2022-33099-in-included-lua
#   Fix lua vulnerability
#   osdn #45248
# 0046-Maintain-list-of-web-client-connections.patch
#   Web-client compatibility development
#   osdn #45155
# 0038-Add-support-for-admin-locked-settings
#   Make it possible to lock settings so that even ruleset
#   reset cannot change them.
#   osdn #45134
# 0027-do_attack-Shrink-city-only-after-complete-removal-of
#   Fix problems when city gets destroyed after an attack
#   osdn #45240
# 0053-Fix-conversion-of-topology-setting-from-old-savegame
#   Fix recent regression in loading older savegames
#   osdn #45338
# 0002-generate_packets.py-Correctly-identify-cm_parameter-
#   Fix recent regression in generating packet handling code for cma
#   osdn #45267
# 0024-Create-web-packages-only-if-there-s-web-clients-pres
#   Web-client compatibility development
#   osdn #45319

# 0023-Meson-Detect-MagickWand
#   Add MagickWand detection to meson configure.
#   Currently on hold on upstream. osdn #45007

# Not in the upstream Freeciv server
# ----------------------------------
# meson_webperimental installs webperimental ruleset
# freeciv_segfauls_fix is a workaround some segfaults in the Freeciv server. Freeciv bug #23884.
# message_escape is a patch for protecting against script injection in the message texts.
# tutorial_ruleset changes the ruleset of the tutorial to one supported by Freeciv-web.
#      - This should be replaced by modification of the tutorial scenario that allows it to
#        work with multiple rulesets (Requires patch #7362 / SVN r33159)
# win_chance includes 'Chance to win' in Freeciv-web map tile popup.
# disable_global_warming is Freeciv bug #24418
# navajo-remove-long-city-names is a quick-fix to remove city names which would be longer than MAX_LEN_NAME
#     when the name is url encoded in json protocol.
#     MAX_LEN_CITYNAME was increased in patch #7305 (SVN r33048)
#     Giving one of the longer removed city names to a new city still causes problems.
# webperimental_install make "make install" install webperimental.
# webgl_vision_cheat_temporary is a temporary solution to reveal terrain types to the WebGL client.
# longturn implements a very basic longturn mode for Freeciv-web.
# load_command_confirmation adds a log message which confirms that loading is complete, so that Freeciv-web can issue additional commands.
# cityname_length reduces MAX_LEN_CITYNAME to 50 for large longturn games.
# endgame-mapimg is used to generate a mapimg at endgame for hall of fame.

declare -a PATCHLIST=(
  "0023-Meson-Detect-MagickWand"
  "0056-establish_new_connection-Set-wrap_id-to-packet_set_t"
  "0026-place_unit-Do-not-add-NoHome-units-to-city-s-units_s"
  "0001-fcmp-Fix-vulnerability-with-crafted-modpack-URLs"
  "0045-Apply-fix-to-CVE-2022-33099-in-included-lua"
  "0046-Maintain-list-of-web-client-connections"
  "0038-Add-support-for-admin-locked-settings"
  "0027-do_attack-Shrink-city-only-after-complete-removal-of"
  "0053-Fix-conversion-of-topology-setting-from-old-savegame"
  "0002-generate_packets.py-Correctly-identify-cm_parameter-"
  "0024-Create-web-packages-only-if-there-s-web-clients-pres"
  "meson_webperimental"
  "city_impr_fix2"
  "city-naming-change"
  "metachange"
  "text_fixes"
  "freeciv-svn-webclient-changes"
  "goto_fcweb"
  "misc_devversion_sync"
  "tutorial_ruleset"
  "savegame"
  "maphand_ch"
  "ai_traits_crash"
  "server_password"
  "barbarian-names"
  "message_escape"
  "freeciv_segfauls_fix"
  "scorelog_filenames"
  "disable_global_warming"
  "win_chance"
  "navajo-remove-long-city-names"
  "webperimental_install"
  "longturn"
  "load_command_confirmation"
  "cityname_length"
  "webgl_vision_cheat_temporary"
  "endgame-mapimg"
)

apply_patch() {
  echo "*** Applying $1.patch ***"
  if ! patch -u -p1 -d freeciv < patches/$1.patch ; then
    echo "APPLYING PATCH $1.patch FAILED!"
    return 1
  fi
  echo "=== $1.patch applied ==="
}

# APPLY_UNTIL feature is used when rebasing the patches, and the working directory
# is needed to get to correct patch level easily.
if test "x$1" != "x" ; then
  APPLY_UNTIL="$1"
  au_found=false

  for patch in "${PATCHLIST[@]}"
  do
    if test "x$patch" = "x$APPLY_UNTIL" ; then
        au_found=true
        APPLY_UNTIL="${APPLY_UNTIL}.patch"
    elif test "x${patch}.patch" = "x$APPLY_UNTIL" ; then
        au_found=true
    fi
  done
  if test "x$au_found" != "xtrue" ; then
    echo "There's no such patch as \"$APPLY_UNTIL\"" >&2
    exit 1
  fi
else
  APPLY_UNTIL=""
fi

. ./version.txt

CAPSTR_EXPECT="NETWORK_CAPSTRING=\"${ORIGCAPSTR}\""
CAPSTR_SRC="freeciv/fc_version"
echo "Verifying ${CAPSTR_EXPECT}"

if ! grep "$CAPSTR_EXPECT" ${CAPSTR_SRC} 2>/dev/null >/dev/null ; then
  echo "   Found  $(grep 'NETWORK_CAPSTRING=' ${CAPSTR_SRC}) in $(pwd)/freeciv/fc_version" >&2
  echo "Capstring to be replaced does not match that given in version.txt" >&2
  exit 1
fi

sed "s/${ORIGCAPSTR}/${WEBCAPSTR}/" freeciv/fc_version > freeciv/fc_version.tmp
mv freeciv/fc_version.tmp freeciv/fc_version
chmod a+x freeciv/fc_version

for patch in "${PATCHLIST[@]}"
do
  if test "x${patch}.patch" = "x$APPLY_UNTIL" ; then
    echo "$patch not applied as requested to stop"
    break
  fi
  if ! apply_patch $patch ; then
    echo "Patching failed ($patch.patch)" >&2
    exit 1
  fi
done
