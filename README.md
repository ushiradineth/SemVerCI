# SemVerCI

Automate Semantic Versioning a Git Repository using [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) Standards

## Really good Alternative: [GitFlow CLI Tool by NVIE](https://github.com/nvie/gitflow)

- A collection of Git extensions to provide high-level repository operations for Vincent Driessen's branching model.
- Highly recommend using this tool for GitFlow workflows, the configurations shared in this repository are for workflows that cannot be supported by GitFlow due to collaboration, complexity or different branching strategies etc.

## Disclaimer

- Please note that GitHub workflows provided in this repository are not tested extensively. Use them at your own risk.
- The scripts are not dependant on Bitbucket Pipelines but was only tested on it.

## Contributing

- Contributions via pull requests are appreciated. Feel free to suggest improvements or report issues.

## Usage

### To switch from Node.js versioning to Spring Boot versioning, make the following changes

- Comment out or remove the Node.js versioning related commands in the version.sh script.
- Uncomment or add Spring Boot versioning related commands in the version.sh script.

## Versioning Scripts

- ‘version.sh’
The ‘version.sh’ script that is used for maintaining the semantic versioning system. It takes two arguments:

1. Release (snapshot, rc, main):

    - snapshot: Sets the version to ‘2.0.0-SNAPSHOT’ in the ‘develop’ branch.

    - rc: Increments and sets the release candidate version in release branches (2.0.0-rc1, 2.0.0-rc2, etc.).

    - main: Cleans up build tags in the main branch (2.0.0-rc1 to 2.0.0) and creates a Git Tag with the version.

2. Semantic Version (major, minor, patch): Increments the specified segment of the semantic version.

- ‘release.sh’
The ‘release.sh’ script is part of the main pipeline. It compares release and develop versions and updates the develop version if needed.

- ‘hotfix.sh’
The ‘hotfix.sh’ script is part of the main pipeline. It increments the patch version for hotfixes, updates develop if needed, and commits the changes.

- ‘initiate-release-branch.sh’
The ‘initiate-release-branch.sh’ script creates a release branch from the develop branch.
