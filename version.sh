#!/bin/sh

# Gets version from pom.xml
# version=$(./mvnw help:evaluate -ntp -Dexpression=project.version -q -DforceStdout) 
version=${node -e "console.log(require('./package.json').version);"}
echo "Current Version: $version"

initial_version=$version

# Splits the version into three segmants based on the dot separator
# "rest" can include the patch version and any build identifier like SNAPSHOT or rc<number>
IFS="." read -r major minor rest <<-EOF
$version
EOF

# Function to check if major or minor version is numeric
is_numeric() {
  case $1 in
    ''|*[!0-9]*) return 1 ;; # Error if its an empty string or not a number
    *) return 0 ;;
  esac
}

# Validate major and minor are numeric values
if ! is_numeric "$major"; then
  echo "Error: Major version is not a numeric value."
  return 1
fi

if ! is_numeric "$minor"; then
  echo "Error: Minor version is not a numeric value."
  return 1
fi

# Extract numeric part from the rest variable
patch=$(echo "$rest" | sed 's/\([0-9]*\).*/\1/')

# Validate patch is a numeric value
if [ -z "$patch" ]; then
  echo "Error: Patch does not contain numeric characters."
  return 1
fi

# Validate the build suffix is as expected
patch_build_suffix=$(echo "$rest" | sed 's/^[0-9]*//')
case "$patch_build_suffix" in
  ''|-SNAPSHOT|-rc[1-9]*) ;;
  *) echo "Error: Build suffix does not follow expected patterns." ; return 1 ;;
esac

case "$2" in 
  major)
    major=$(expr $major + 1)
    minor="0"
    patch="0"
    ;;
  minor)
    minor=$(expr $minor + 1)
    patch="0"
    ;;
  patch)
    patch=$(expr $patch + 1)
    ;;
esac

update() {
  export VERSION=$version
  echo "export VERSION=$version" > version.env

  if [ "$version" = "$initial_version" ]; then
    echo "No version change"
    return 1
  else
    echo "New version = $version"
    # ./mvnw versions:set -ntp -DnewVersion=$version -DgenerateBackupPoms=false # Updates version in pom.xml
    npm version $version --no-git-tag-version

    # git add pom.xml
    git add package.json
    git commit -m "[skip CI]: Version updated to $version"

    return 0
  fi
}

case "$1" in
  snapshot)
    version="$major.$minor.$patch-SNAPSHOT"
    if update; then
      git push
    fi
    ;;
  rc)
    if echo "$patch_build_suffix" | grep -q 'rc'; then
      rc_number=$(echo "$patch_build_suffix" | sed 's/[^0-9]*//')
      rc_number=$(expr $rc_number + 1)
      version="$major.$minor.$patch-rc$rc_number"
    else
      rest=$(echo "$patch" | sed 's/\([0-9]*\).*/\1/')
      version="$major.$minor.$rest-rc1"
    fi
    if update; then
      git push
    fi
    ;;
  main)
    version="$major.$minor.$patch"
    if update; then
      git push origin main
      git tag $version -m $version
      git push --tags origin 
    fi
    ;;
  *)
    echo "Usage: bash version.sh {snapshot|rc|main} [major|minor|patch]"
    return 1
    ;;
esac

return 0
