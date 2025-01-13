Pod::Spec.new do |spec|

  spec.name = "FaceCapture"
  spec.version = "1.0.0"
  spec.summary = "Capture live face for face recognition"
  spec.homepage = "https://github.com/AppliedRecognition/Face-Capture-Apple"
  spec.license = { :type => "Commercial", :file => "LICENCE.txt" }
  spec.author = "Jakub Dolejs"
  spec.platform = :ios, "13.0"
  spec.swift_versions = ["5.5", "5.6", "5.7", "5.8", "5.9", "5.10"]
  spec.source = { :git => "https://github.com/AppliedRecognition/Face-Capture-Apple.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/FaceCapture/*.swift"
  spec.resource_bundles = {"FaceCapture" => ["Sources/FaceCapture/Resources/**/*"] }
  spec.dependency "VerIDCommonTypes", "~> 1.0.0"
  spec.dependency "LivenessDetectionCore", "~> 1.0.0"

end
