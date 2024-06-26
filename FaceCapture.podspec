Pod::Spec.new do |spec|

  spec.name         = "FaceCapture"
  spec.version      = "1.0.0"
  spec.summary      = "Capture live face for face recognition"
  spec.homepage     = "https://github.com/AppliedRecognition/Face-Capture-Apple"
  spec.license      = { :type => "MIT", :file => "LICENCE.txt" }
  spec.author    = "Jakub Dolejs"
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/AppliedRecognition/Face-Capture-Apple.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/FaceCapture/*.swift"
  spec.resources = "Sources/FaceCapture/Resources/*.*"
  spec.dependency "VerIDCommonTypes", :git => "https://github.com/AppliedRecognition/Ver-ID-Common-Types-Apple.git"
  spec.dependency "LivenessDetectionCore", :git => "https://github.com/AppliedRecognition/Liveness-Detection-Core-Apple.git"
  spec.dependency "VerIDLicence", :git => "https://github.com/AppliedRecognition/Ver-ID-Licence-Apple.git"

end
