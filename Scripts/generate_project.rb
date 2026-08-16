require "xcodeproj"

project_path = "FutureBody.xcodeproj"
project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, "FutureBody", :ios, "17.0")
test_target = project.new_target(:unit_test_bundle, "FutureBodyTests", :ios, "17.0")
test_target.add_dependency(target)

project.root_object.attributes["LastUpgradeCheck"] = "1600"

firebase_package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
firebase_package.repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git"
firebase_package.requirement = {
  "kind" => "exactVersion",
  "version" => "12.17.0"
}
project.root_object.package_references << firebase_package

%w[FirebaseCore FirebaseAuth FirebaseFirestore].each do |product_name|
  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.package = firebase_package
  product.product_name = product_name
  target.package_product_dependencies << product
end

project.build_configurations.each do |configuration|
  configuration.build_settings["SWIFT_VERSION"] = "5.0"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  configuration.build_settings.delete("SDKROOT")
end

target.build_configurations.each do |configuration|
  configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "app.futurebody.mobile"
  configuration.build_settings["PRODUCT_NAME"] = "FutureBody"
  configuration.build_settings["SWIFT_VERSION"] = "5.0"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  configuration.build_settings.delete("SDKROOT")
  configuration.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  configuration.build_settings["INFOPLIST_FILE"] = "FutureBody/Info.plist"
  configuration.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
  configuration.build_settings["SUPPORTS_MACCATALYST"] = "NO"
  configuration.build_settings["OTHER_LDFLAGS"] = "$(inherited) -ObjC"
  configuration.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  configuration.build_settings["DEVELOPMENT_TEAM"] = "W7WQFW7K74"
  configuration.build_settings["CURRENT_PROJECT_VERSION"] = "3"
  configuration.build_settings["MARKETING_VERSION"] = "1.0.0"
  configuration.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
end

test_target.build_configurations.each do |configuration|
  configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.example.FutureBodyTests"
  configuration.build_settings["PRODUCT_NAME"] = "FutureBodyTests"
  configuration.build_settings["SWIFT_VERSION"] = "5.0"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  configuration.build_settings.delete("SDKROOT")
  configuration.build_settings["SUPPORTED_PLATFORMS"] = "iphoneos iphonesimulator"
  configuration.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  configuration.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
  configuration.build_settings["DEVELOPMENT_TEAM"] = "W7WQFW7K74"
  configuration.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/FutureBody.app/FutureBody"
  configuration.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

app_group = project.main_group.new_group("FutureBody")
app_group.new_file("FutureBody/Info.plist")
app_group.new_file("FutureBody/Assets.xcassets")

Dir.glob("FutureBody/**/*.swift").sort.each do |path|
  file = app_group.new_file(path)
  target.source_build_phase.add_file_reference(file)
end

Dir.glob("FutureBody/Resources/Fonts/LINESeedJP-{Regular,Bold,ExtraBold}.ttf").sort.each do |path|
  file = app_group.new_file(path)
  target.resources_build_phase.add_file_reference(file)
end

Dir.glob("FutureBody/Resources/*.xcprivacy").sort.each do |path|
  file = app_group.new_file(path)
  target.resources_build_phase.add_file_reference(file)
end

asset_catalog = app_group.files.find { |file| file.path == "FutureBody/Assets.xcassets" }
target.resources_build_phase.add_file_reference(asset_catalog)

firebase_configuration_phase = target.new_shell_script_build_phase("Firebase configuration")
firebase_configuration_phase.shell_script = <<~SH
  if [ -f "${SRCROOT}/FutureBody/GoogleService-Info.plist" ]; then
    cp "${SRCROOT}/FutureBody/GoogleService-Info.plist" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
  fi
SH
firebase_configuration_phase.output_paths = [
  "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist"
]

tests_group = project.main_group.new_group("FutureBodyTests")
test_file = tests_group.new_file("FutureBodyTests/WorkoutStoreTests.swift")
test_target.source_build_phase.add_file_reference(test_file)

project.save

app_scheme = Xcodeproj::XCScheme.new
app_scheme.configure_with_targets(target, nil, launch_target: true)
app_scheme.save_as(project_path, target.name, true)

test_scheme = Xcodeproj::XCScheme.new
test_scheme.configure_with_targets(target, test_target, launch_target: true)
test_scheme.save_as(project_path, "FutureBodyTests", true)
