#!/usr/bin/env bash

set -e

if [[ $# -ne 1 ]]; then
  echo "This needs a release tag. e.g. $0 v0.0.1"
  exit 1
fi

if [[ -z "$GITHUB_SUPER_TOKEN" ]]; then
  echo "This script needs a GitHub personal access token."
  exit 1
fi

ACTION_KEYBASE_NOTIFICATIONS_REPO="action-keybase-notifications"
ACTION_AUTOMATIC_RELEASES_REPO="action-automatic-releases"
TAG=$1
GITHUB_LOGIN="marvinpinto"
RELEASE_BODY="This is an mirrored release. Detailed release notes available at https://github.com/marvinpinto/actions/releases/tag/${TAG}."

PRERELEASE="false"
if [[ "$TAG" == "latest" ]]; then
  PRERELEASE="true"
fi

if [[ "$GITHUB_REPOSITORY" != "marvinpinto/actions" ]]; then
  echo "This mirror script is only meant to be run from marvinpinto/actions, not ${GITHUB_REPOSITORY}. Nothing to do here."
  exit 0
fi

create_tagged_release() {
  REPO=$1
  pushd /tmp/${REPO}/

  # Set the local git identity
  git config user.email "${GITHUB_LOGIN}@users.noreply.github.com"
  git config user.name "$GITHUB_LOGIN"

  # Delete previous identical tags, if present
  git tag -d $TAG || true
  git push origin :$TAG || true

  # Add all the changed files and push the changes upstream
  git add -f .
  git commit -m "Update release files for tag: ${TAG}" || true
  git push -f origin master:master
  git tag $TAG
  git push origin $TAG

  # Generate a skeleton release on GitHub
  curl \
    --user ${GITHUB_LOGIN}:${GITHUB_SUPER_TOKEN} \
    --request POST \
    --silent \
    --data @- \
    https://api.github.com/repos/${GITHUB_LOGIN}/${REPO}/releases <<END
  {
    "tag_name": "$TAG",
    "name": "Auto-generated release for tag $TAG",
    "body": "$RELEASE_BODY",
    "draft": false,
    "prerelease": $PRERELEASE
  }
END
  popd
}

# Mirroring Keybase Notifications
rm -rf "/tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}"
git clone "https://marvinpinto:${GITHUB_SUPER_TOKEN}@github.com/marvinpinto/${ACTION_KEYBASE_NOTIFICATIONS_REPO}.git" /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}
mkdir -p /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/dist
cp packages/keybase-notifications/dist/index.js /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/dist/
cp packages/keybase-notifications/dist/keybase /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/dist/
cp -R packages/keybase-notifications/images /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/
cp packages/keybase-notifications/README.md /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/
cp packages/keybase-notifications/action.yml /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/
cp LICENSE /tmp/${ACTION_KEYBASE_NOTIFICATIONS_REPO}/
create_tagged_release "$ACTION_KEYBASE_NOTIFICATIONS_REPO"

# Mirroring Automatic Releases
rm -rf "/tmp/${ACTION_AUTOMATIC_RELEASES_REPO}"
git clone "https://marvinpinto:${GITHUB_SUPER_TOKEN}@github.com/marvinpinto/${ACTION_AUTOMATIC_RELEASES_REPO}.git" /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}
mkdir -p /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}/dist
cp packages/automatic-releases/dist/index.js /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}/dist/
cp packages/automatic-releases/README.md /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}/
cp packages/automatic-releases/action.yml /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}/
cp LICENSE /tmp/${ACTION_AUTOMATIC_RELEASES_REPO}/
create_tagged_release "$ACTION_AUTOMATIC_RELEASES_REPO"
