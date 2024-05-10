#!/usr/bin/env bash
if [ "$1" != "major" ] && [ "$1" != "minor" ] && [ "$1" != "patch" ];
then
    echo "Could not release!"
    echo "Usage: 'npm run release -- (major|minor|patch)'"
    echo ""
    exit 1
fi

# Note - we need to tag manually because of https://github.com/npm/cli/issues/2010
NEW_VERSION=$(npm version $1)

git add package.json package-lock.json
git commit -m 'Bump version'
git tag $NEW_VERSION
echo "Bumped version to $NEW_VERSION"

# Prompt for pushing
read -p "Push HEAD and tags to $NEW_VERSION? y/n " PUSH
if [ $PUSH = "y" ]
then 
    git push && git push --tags
else
    echo "Not pushing."
fi