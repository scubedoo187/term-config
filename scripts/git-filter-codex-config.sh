#!/bin/bash
set -euo pipefail

# git clean filter for home/codex/config.toml.
#
# Codex appends a [projects."<abs path>"] block with trust_level = "trusted"
# for every directory it is run in. Those paths only exist on the machine that
# created them, so tracking them means a permanent cross-machine conflict in
# this file for no benefit: a fresh checkout simply gets asked to trust its own
# paths again.
#
# This runs on `git add`, so the blob git stores has the blocks removed while
# the working copy -- which is what ~/.codex/config.toml symlinks to -- keeps
# them and stays fully functional. The smudge side is identity (`cat`).
#
# Register it with scripts/setup-git-filters.sh; .gitattributes points at it.

# Drop every [projects."..."] block: the header plus its body, up to the next
# top-level table or EOF.
awk '
    /^\[projects\./ { skip = 1; next }
    /^\[/           { skip = 0 }
    skip            { next }
                    { print }
' | awk '
    # Collapse the blank lines the removal leaves behind at EOF, while keeping
    # blank lines that separate surviving sections.
    /^[[:space:]]*$/ { pending++; next }
    { while (pending > 0) { print ""; pending-- } print }
'
