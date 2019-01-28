#!/usr/bin/env bash
set -euo pipefail

if [[ ${TRAVIS_TAG} != v* ]]; then
  echo "Not on a git tag"
  exit 1
fi

export VERSION="$(echo "$TRAVIS_TAG" | sed 's@^v@@')"

mkdir -p target
cd target

if [ -d homebrew-formulas ]; then
  echo "Removing former homebrew-formulas clone"
  rm -rf homebrew-formulas
fi

echo "Cloning"
git clone "https://${GH_TOKEN}@github.com/$FORMULA_REPO.git" -q -b master homebrew-formulas
cd homebrew-formulas

git config user.name "Travis-CI"
git config user.email "invalid@travis-ci.com"

URL="https://github.com/$REPO/releases/download/$TRAVIS_TAG/$NAME"
curl --fail -Lo launcher "$URL"

SHA256="$(openssl dgst -sha256 -binary < launcher | xxd -p -c 256)"
# rm -f launcher

cat "../../$TEMPLATE" |
  sed 's=@LAUNCHER_VERSION@='"$VERSION"'=g' |
  sed 's=@LAUNCHER_URL@='"$URL"'=g' |
  sed 's=@LAUNCHER_SHA256@='"$SHA256"'=g' > "$NAME.rb"

git add "$NAME.rb"

MSG="Updates for $VERSION"

# probably not fine with i18n
if git status | grep "nothing to commit" >/dev/null 2>&1; then
  echo "Nothing changed"
else
  git commit -m "$MSG"

  echo "Pushing changes"
  git push origin master
fi
