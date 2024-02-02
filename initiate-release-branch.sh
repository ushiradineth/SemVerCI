#!/bin/sh

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if the branch is "develop"
case "$CURRENT_BRANCH" in
  develop) ;;
  *) 
    echo "initiate-release-branch pipeline is supposed to be triggered from the develop branch"
    return 1
    ;;
esac

# Removes any build indentifiers from the version
# release_version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout | awk -F'[^0-9.]' '{print $1}' | sed '/^$/d')
release_version=$(node -e "console.log(require('./package.json').version);" | awk -F'[^0-9.]' '{print $1}' | sed '/^$/d')

BRANCH="release/$release_version"

if git rev-parse --verify --quiet "$BRANCH"; then
  echo "Branch $BRANCH already exists"
  return 1
fi

git checkout -b $BRANCH
git commit --allow-empty -m "chore: Trigger Build for $release_version"
git push -u origin $BRANCH

return 0

