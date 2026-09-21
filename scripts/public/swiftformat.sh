#!/bin/bash

PATH=/opt/homebrew/bin/:$PATH

# Never rewrite sources during a CI build. This phase formats the whole repo in place,
# so on CI it would archive a reformatted tree rather than the commit being built --
# and rebuilding an old release branch would silently apply today's SwiftFormat rules
# to frozen sources. CI verifies formatting separately via the check:formater job,
# which runs `swiftformat --lint`.
if [ -n "$CI" ]; then
  echo "note: SwiftFormat build phase skipped on CI (see check:formater job)"
  exit 0
fi

if which swiftformat >/dev/null; then
  swiftformat .
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi
