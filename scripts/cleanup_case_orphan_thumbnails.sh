#!/bin/bash
#
# Deletes thumbnails orphaned by the lowercase-extension bug in
# reset_thumbnail / rotate_thumbnail.
#
# Those endpoints used to build the thumbnail name as
#     os.path.splitext(file_name)[0] + '.jpg'
# which lowercased the extension, while the client asks for the original case
# whenever the name is already a .jpg.  So rebuilding the thumbnail of
# DSCN5138.JPG wrote DSCN5138.jpg, which nothing ever reads, and left the stale
# DSCN5138.JPG on display.  Each rotate or reset on a .JPG photo left one more
# of these behind.
#
# A thumbnail is deleted only when BOTH hold:
#   1. no original in that month maps to its name, and
#   2. a case-insensitive sibling of it IS the name an original maps to.
# That second condition is what keeps this to genuine case-orphans.  A
# thumbnail with no matching original at all (a deleted photo, say) is only
# reported - deciding those is not this script's job.
#
# Dry run by default.  Pass --apply to actually delete.
#
# Usage:
#   ./cleanup_case_orphan_thumbnails.sh                     # dry run
#   ./cleanup_case_orphan_thumbnails.sh --apply
#   ./cleanup_case_orphan_thumbnails.sh --apply /path/to/photos

set -uo pipefail

APPLY=0
PHOTOS="$HOME/data/aop/photos"
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        *) PHOTOS="$arg" ;;
    esac
done

if [ ! -d "$PHOTOS" ]; then
    echo "photos directory not found: $PHOTOS" >&2
    exit 1
fi

# Mirrors thumbnail_name() in pyserver/src/aopservermain.py and
# thumbnailURL in aopmodel/lib/aop_classes.dart: a name already ending .jpg in
# any case keeps that case, anything else gets a lowercase .jpg extension.
expected_thumb() {
    local f=$1
    local lower=${f,,}
    if [[ $lower == *.jpg ]]; then
        printf '%s' "$f"
    else
        printf '%s.jpg' "${f%.*}"
    fi
}

orphans=0
unmatched=0
bytes=0

for monthdir in "$PHOTOS"/*/; do
    # the glob leaves a trailing / on monthdir, so don't add another
    thumbs="${monthdir}thumbnails"
    [ -d "$thumbs" ] || continue

    # Thumbnail names the originals in this month actually call for.
    declare -A expected=()
    declare -A expected_lc=()
    while IFS= read -r -d '' original; do
        name=$(basename "$original")
        e=$(expected_thumb "$name")
        expected["$e"]=1
        expected_lc["${e,,}"]=1
    done < <(find "$monthdir" -maxdepth 1 -type f -print0)

    while IFS= read -r -d '' thumb; do
        name=$(basename "$thumb")
        # Wanted by some original - keep.
        [ -n "${expected[$name]:-}" ] && continue

        if [ -n "${expected_lc[${name,,}]:-}" ]; then
            # A case-variant of this name is the wanted one: this is an orphan.
            orphans=$((orphans + 1))
            size=$(stat -c %s "$thumb" 2>/dev/null || echo 0)
            bytes=$((bytes + size))
            if [ "$APPLY" = "1" ]; then
                rm -f -- "$thumb"
                echo "deleted : ${thumb#"$PHOTOS"/}"
            else
                echo "would delete: ${thumb#"$PHOTOS"/}"
            fi
        else
            unmatched=$((unmatched + 1))
            echo "no original (left alone): ${thumb#"$PHOTOS"/}"
        fi
    done < <(find "$thumbs" -maxdepth 1 -type f -print0)

    unset expected expected_lc
done

echo
echo "case-orphan thumbnails : $orphans  ($((bytes / 1024)) KB)"
echo "thumbnails with no original (untouched): $unmatched"
if [ "$APPLY" = "1" ]; then
    echo "Deleted. The photos keep their existing thumbnails; nothing needs regenerating."
else
    echo "Dry run - nothing deleted. Re-run with --apply to remove them."
fi
