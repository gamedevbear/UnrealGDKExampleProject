#!/usr/bin/env bash

# Make them arguments
GDK_REPO="git@github.com:spatialos/UnrealGDK.git"
GCS_PUBLISH_BUCKET="io-internal-infra-unreal-artifacts-production/UnrealEngine"


EXAMPLEPROJECT_HOME="$(pwd)/../"
GDK_BRANCH_NAME=${GDK_BRANCH:-master}
LAUNCH_DEPLOYMENT=${START_DEPLOYMENT:-true}
GDK_HOME= "${EXAMPLEPROJECT_HOME}/Game/Plugins/UnrealGDK"

mkdir -p "${GDK_HOME}/Game/Plugins"
pushd "$(pwd)/..//Game/Plugins/"
	echo "--- clone-gdk-plugin"
	git clone ${GDK_REPO} --depth 1 -b ${GDK_BRANCH_NAME}
popd


echo "--- get-gdk-head-commit"
pushd ${GDK_HOME}
	# Get the short commit hash of this gdk build for later use in assembly name
	${GDK_COMMIT_HASH} = $(git rev-parse HEAD | cut -c0-6)
    echo "GDK at commit: $gdk_commit_hash on branch $gdk_branch_name"
popd

echo "--- set-up-gdk-plugin"
${GDK_HOME}/Setup.sh --mobile

# Use the cached engine version or set it up if it has not been cached yet.
echo "--- set-up-engine"
ENGINE_DIRECTORY="${EXAMPLEPROJECT_HOME}/UnrealEngine"
${GDK_HOME}/ci/get-engine.ps1 -unreal_path "${ENGINE_DIRECTORY}" # TODO need to rewrite that script for bash probs

echo "--- create-xcode-project"
pushd ${ENGINE_DIRECTORY}

${ENGINE_DIRECTORY}/Engine/Build/BatchFiles/Mac/Build.sh -projectfiles -project="${EXAMPLEPROJECT_HOME}/Game/GDKShooter.uproject" -game -engine -progress

echo "--- build-editor"
spatial worker build build-config
${ENGINE_DIRECTORY}/Engine/Build/BatchFiles/Mac/XcodeBuild.sh GDKShooterEditor Mac Development "${EXAMPLEPROJECT_HOME}/Game/GDKShooter.uproject" -buildscw

echo "--- generate-schema"
pushd "UnrealEngine/Engine/Binaries/Win64"
	UE4Editor.app "${EXAMPLEPROJECT_HOME}/Game/GDKShooter.uproject" -run=GenerateSchemaAndSnapshots -MapPaths="/Maps/FPS-Start_Small"
popd

echo "--- build-macos-client"
${ENGINE_DIRECTORY}/Engine/Build/BatchFiles/Mac/XcodeBuild.sh GDKShooter Mac Development "${EXAMPLEPROJECT_HOME}/Game/GDKShooter.uproject" -buildscw


echo "--- build-ios-client"
${ENGINE_DIRECTORY}/Engine/Build/BatchFiles/Mac/XcodeBuild.sh GDKShooter IOS Development "${EXAMPLEPROJECT_HOME}/Game/GDKShooter.uproject" -buildscw

popd