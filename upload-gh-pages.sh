#!/usr/bin/env bash
set -eu

if [[ ${TRAVIS_TAG} != v* ]]; then
  echo "Not on a git tag"
  exit 1
fi

export VERSION="$(echo "$TRAVIS_TAG" | sed 's@^v@@')"

mkdir -p target
cd target

if [ -d gh-pages ]; then
  echo "Removing former gh-pages clone"
  rm -rf gh-pages
fi

LAUNCHER_BRANCH="${LAUNCHER_BRANCH:-"gh-pages"}"
LAUNCHER_REPO="${LAUNCHER_REPO:-"$REPO"}"

echo "Cloning"
git clone "https://${GH_TOKEN}@github.com/$LAUNCHER_REPO.git" -q -b "$LAUNCHER_BRANCH" gh-pages
cd gh-pages

git config user.name "Travis-CI"
git config user.email "invalid@travis-ci.com"

for n in $NAME; do
  curl --fail -Lo "$n" "https://github.com/$REPO/releases/download/$TRAVIS_TAG/$n"
  git add -- "$n"
done

MSG="Add $VERSION launcher"

# probably not fine with i18n
if git status | grep "nothing to commit" >/dev/null 2>&1; then
  echo "Nothing changed"
else
  git commit -m "$MSG"

  echo "Pushing changes"
  git push origin "$LAUNCHER_BRANCH"
fi
