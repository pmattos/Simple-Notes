##
## Podfile for the Simple Notes iOS project.
##
## Podfile syntax reference:
## https://guides.cocoapods.org/syntax/podfile.html
##

# Simple Notes uses iOS 12.1 as minimum version.
platform :ios, '12.1'

# Use frameworks instead of static libraries for Pods.
# This is *required* for Swift-based projects!].
use_frameworks!

# The Podfile retrieves specs from the given list of repositories.
source 'https://github.com/CocoaPods/Specs.git'

# App's dependencies.
target 'Simple Notes' do
	workspace 'Simple Notes.xcworkspace'
	project 'Simple Notes.xcodeproj'

	# Firebase SDK.
	pod 'Firebase/Core'
	pod 'Firebase/Firestore'
end