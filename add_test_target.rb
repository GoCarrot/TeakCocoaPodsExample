#!/usr/bin/env ruby
# Adds a unit test target to the Xcode project.

require 'xcodeproj'

project_path = File.join(__dir__, 'TeakSwiftCleanroomPods.xcodeproj')
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'TeakSwiftCleanroomPods' }
abort("Could not find main app target") unless main_target

# --------------------------------------------------------------------------
# 1. Create the unit test target
# --------------------------------------------------------------------------
test_target = project.new_target(
  :unit_test_bundle,
  'TeakSwiftCleanroomPodsTests',
  :ios,
  '18.0',
  nil,
  :swift
)

# --------------------------------------------------------------------------
# 2. Configure build settings
# --------------------------------------------------------------------------
test_target.build_configurations.each do |config|
  s = config.build_settings

  s.delete('SDKROOT')
  s.delete('CLANG_ENABLE_OBJC_WEAK')

  s['CODE_SIGN_STYLE']                    = 'Automatic'
  s['CURRENT_PROJECT_VERSION']            = '1'
  s['DEVELOPMENT_TEAM']                   = '7FLZTACJ82'
  s['GENERATE_INFOPLIST_FILE']            = 'YES'
  s['IPHONEOS_DEPLOYMENT_TARGET']         = '18.2'
  s['MARKETING_VERSION']                  = '1.0'
  s['PRODUCT_BUNDLE_IDENTIFIER']          = 'io.teak.TeakSwiftCleanroomPodsTests'
  s['PRODUCT_NAME']                       = '$(TARGET_NAME)'
  s['SWIFT_EMIT_LOC_STRINGS']             = 'NO'
  s['SWIFT_VERSION']                      = '5.0'
  s['TARGETED_DEVICE_FAMILY']             = '1,2'
  s['TEST_HOST']                          = '$(BUILT_PRODUCTS_DIR)/TeakSwiftCleanroomPods.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TeakSwiftCleanroomPods'
  s['BUNDLE_LOADER']                      = '$(TEST_HOST)'
end

# --------------------------------------------------------------------------
# 3. Remove auto-added Foundation.framework
# --------------------------------------------------------------------------
test_target.frameworks_build_phase.files.dup.each do |f|
  ref = f.file_ref
  if ref && (ref.name == 'Foundation.framework' || ref.path.to_s.include?('Foundation'))
    f.remove_from_project
  end
end

# --------------------------------------------------------------------------
# 4. Create test source synchronized root group
# --------------------------------------------------------------------------
test_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
test_group.path = 'TeakSwiftCleanroomPodsTests'
test_group.source_tree = '<group>'

# Insert into main group before Products
products_index = project.main_group.children.index { |c| c.display_name == 'Products' }
project.main_group.children.insert(products_index, test_group)

test_target.file_system_synchronized_groups << test_group

# --------------------------------------------------------------------------
# 5. Also add Shared/ group to test target so it can access ActivityAttributes
# --------------------------------------------------------------------------
shared_group = project.main_group.children.find { |c|
  c.respond_to?(:path) && c.path == 'Shared'
}
abort("Could not find Shared group") unless shared_group
test_target.file_system_synchronized_groups << shared_group

# --------------------------------------------------------------------------
# 6. Wire test target as dependency of main app
# --------------------------------------------------------------------------
main_target.add_dependency(test_target)

# Add product to Products group
products_group = project.main_group.children.find { |c| c.display_name == 'Products' }
products_group.children << test_target.product_reference if products_group

# --------------------------------------------------------------------------
# 7. Add TargetAttributes
# --------------------------------------------------------------------------
attrs = project.root_object.attributes['TargetAttributes'] || {}
attrs[test_target.uuid] = {
  'CreatedOnToolsVersion' => '16.4',
  'TestTargetID' => main_target.uuid
}
project.root_object.attributes['TargetAttributes'] = attrs

# --------------------------------------------------------------------------
# 8. Save
# --------------------------------------------------------------------------
project.save
puts "Successfully added TeakSwiftCleanroomPodsTests target."
puts "Targets: #{project.targets.map(&:name).inspect}"
