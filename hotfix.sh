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

# Check if the branch starts with "hotfix/"
case "$PR_BRANCH" in
  hotfix/*) ;;
  *) 
    echo "hotfix.sh script skipped on non hotfix/* source branches"
    return 0
    ;;
esac

# hotfix_version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout)
hotfix_version=$(node -e "console.log(require('./package.json').version);")

# Splits the version into three segmants based on the dot separator
# "rest" can include the patch version and any build identifier like SNAPSHOT or rc<number>
IFS="." read -r major minor rest <<-EOF
$hotfix_version
EOF

# Extract numeric part from the rest variable
patch=$(echo "$rest" | sed 's/\([0-9]*\).*/\1/')

# Validate patch is a numeric value
if [ -z "$patch" ]; then
  echo "Error: Patch does not contain numeric characters."
  return 1
fi

hotfix_version="$major.$minor.$(expr $patch + 1)"

# ./mvnw versions:set -ntp -DnewVersion="$hotfix_version" -DgenerateBackupPoms=false
npm version $hotfix_version --no-git-tag-version

# git add pom.xml
git add package.json

git commit -m "chore: Increment version for hotfix $hotfix_version"
git push origin main

echo "export VERSION=$hotfix_version" > version.env

git checkout develop

# develop_version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout)
develop_version=$(node -e "console.log(require('./package.json').version);")

git pull origin main --no-edit

# Set the develop version to hotfix version only if develop version is behind
if version_gt "$hotfix_version" "$develop_version"; then
  # ./mvnw versions:set -ntp -DnewVersion="$hotfix_version" -DgenerateBackupPoms=false
  npm version $hotfix_version --no-git-tag-version

  # git add pom.xml
  # git add package.json

  git commit --allow-empty -m "chore: Version bump to $hotfix_version"
else
  git commit --allow-empty -m "chore: Trigger Build for main branch merge"
fi

git push origin develop

git push --delete origin "$PR_BRANCH"

return 0

