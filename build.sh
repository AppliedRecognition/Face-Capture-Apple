set -e
scheme=FaceCapture
archivePath="archives"
iphoneArchivePath="${archivePath}/${scheme}.xcarchive"
simulatorArchivePath="${archivePath}/${scheme}Simulator.xcarchive"
outputFrameworkPath="${scheme}.xcframework"
rm -rf "${archivePath}"
xcodebuild archive -scheme ${scheme} -destination "generic/platform=iOS" -archivePath "${iphoneArchivePath}" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive -scheme ${scheme} -destination "generic/platform=iOS simulator" -archivePath "${simulatorArchivePath}" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
rm -rf "${outputFrameworkPath}"
xcodebuild -create-xcframework \
    -framework "${iphoneArchivePath}/Products/usr/local/lib/${scheme}.framework" \
    -framework "${simulatorArchivePath}/Products/usr/local/lib/${scheme}.framework" \
    -output "${outputFrameworkPath}"
rm -rf "${archivePath}"
