#!/bin/sh

# Function to compare two semantic versions (ignores build identifiers)
version_gt() {
  v1=$(echo "$1" | awk -F'[^0-9.]' '{print $1}')
  v2=$(echo "$2" | awk -F'[^0-9.]' '{print $1}')
  awk -v v1="$v1" -v v2="$v2" 'BEGIN { if (v1 > v2) return 0; else return 1 }'
}

COMMIT_INFO=$(git log -1 --pretty=%B)

# Ensures that the commit message matches the following format: "Merged in <branch> (pull request" and extracts the branch
if [ "$(echo "$COMMIT_INFO" | grep -c "pull request")" -gt 0 ]; then
  PR_BRANCH=$(echo "$COMMIT_INFO" | sed -n 's/.*Merged[[:space:]]in[[:space:]]\(.*\)[[:space:]](pull[[:space:]]request.*/\1/p')
fi

# Check if the branch starts with "release/"
case "$PR_BRANCH" in
  release/*) ;;
  *) 
    echo "release.sh script skipped on non release/* source branches"
    return 0
    ;;
esac

# release_version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout)
release_version=$(node -e "console.log(require('./package.json').version);")

git checkout develop

# develop_version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout)
develop_version=$(node -e "console.log(require('./package.json').version);")

if version_gt "$release_version" "$develop_version"; then
  echo "ERROR: Release version ($release_version) is greater than the develop version ($develop_version)"
  return 1
fi

git pull origin main --no-edit

# ./mvnw versions:set -ntp -DnewVersion="$develop_version" -DgenerateBackupPoms=false
npm version $develop_version --no-git-tag-version

# git add pom.xml
git add package.json
git commit --allow-empty -m "chore: Trigger Build for main branch merge"
git push origin develop

return 0

