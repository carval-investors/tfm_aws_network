set -uex

#github token added to localized files for git auth
git config --global credential.helper store
git config --global github.token $GITHUB_TOKEN
echo "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
echo "[user]
	name = ${GITHUB_USER}
[credential]
	helper = store" > ~/.gitconfig

# function for parsing versions
function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

# Create github release for deploy to master, if we deployed correctly
if [ $CIRCLE_BRANCH == "master" ];then
    text="Current release"
    branch=$(git rev-parse --abbrev-ref HEAD)
    repo_full_name=$CIRCLE_PROJECT_REPONAME
    token=$GITHUB_TOKEN

    # read version for release from CHANGELOG
    version=$(head -4 CHANGELOG.md | grep '[0-9]' | cut -d" " -f2)
    old_ver=$(curl -s "https://api.github.com/repos/$repo_full_name/releases/latest?access_token=$token" | jq -r .tag_name)

    if [ $(version $version) -gt $(version $old_ver) ];then
        echo "Create release $version for repo: $repo_full_name branch: $branch"
        curl "https://api.github.com/repos/$repo_full_name/releases?access_token=$token" \
        --data @- <<END;
{
    "tag_name": "$version",
    "target_commitish": "$branch",
    "name": "$version",
    "body": "$text",
    "draft": false,
    "prerelease": false
}
END
    else
        echo "New version $version is not newer than current: $old_ver, failing release tagging"
        exit 1
    fi
fi
