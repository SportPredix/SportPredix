#!/bin/bash

set -e

cd "$(dirname "$0")"

WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=SportPredix

if [ ! -d "build" ]; then
    mkdir build
fi

cd build



PACKAGES_DIR="$WORKING_LOCATION/build/SourcePackages"


if ! xcodebuild -resolvePackageDependencies \
    -workspace "$WORKSPACE_PATH" \

xcodebuild -resolvePackageDependencies \
    -project "$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.xcodeproj" \

    -scheme "$APPLICATION_NAME" \

    -destination 'generic/platform=iOS' \
    -clonedSourcePackagesDirPath "$PACKAGES_DIR" \
    -quiet > "$WORKING_LOCATION/build/resolve_packages.log" 2>&1; then
  cat "$WORKING_LOCATION/build/resolve_packages.log"
  exit 1
fi

    -clonedSourcePackagesDirPath "$PACKAGES_DIR"


xcodebuild -resolvePackageDependencies \
    -project "$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME"


xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME" \
    -configuration Release \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"

DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/Release-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi


mkdir Payload
cp -r SportPredix.app Payload/SportPredix.app
strip Payload/SportPredix.app/SportPredix
zip -vr SportPredix.ipa Payload
rm -rf SportPredix.app
rm -rf Payload
