#!/usr/bin/env ruby
# Adds the TeakLiveActivityWidget extension target and Shared synchronized root
# group to the Xcode project. Run BEFORE `pod install`.

require 'xcodeproj'

project_path = File.join(__dir__, 'TeakSwiftCleanroomPods.xcodeproj')
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'TeakSwiftCleanroomPods' }
abort("Could not find main app target") unless main_target

# --------------------------------------------------------------------------
# 1. Create Shared/ synchronized root group (compiled by both app + widget)
# --------------------------------------------------------------------------
shared_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
shared_group.path = 'Shared'
shared_group.source_tree = '<group>'

# Insert into main group before Products
main_group_children = project.main_group.children
products_index = main_group_children.index { |c| c.display_name == 'Products' } || main_group_children.size
project.main_group.children.insert(products_index, shared_group)

# Add to main app target so Shared/ files compile for the app
main_target.file_system_synchronized_groups << shared_group

# --------------------------------------------------------------------------
# 2. Create the widget extension target
# --------------------------------------------------------------------------
widget_target = project.new_target(
  :app_extension,
  'TeakLiveActivityWidget',
  :ios,
  '18.0',
  nil,
  :swift
)

# --------------------------------------------------------------------------
# 3. Configure build settings to match existing extension patterns
# --------------------------------------------------------------------------
widget_target.build_configurations.each do |config|
  s = config.build_settings

  # Remove defaults that new_target adds but should only be at project level
  s.delete('SDKROOT')
  s.delete('CLANG_ENABLE_OBJC_WEAK')

  s['CODE_SIGN_STYLE']                    = 'Automatic'
  s['CURRENT_PROJECT_VERSION']            = '1'
  s['DEVELOPMENT_TEAM']                   = '7FLZTACJ82'
  s['ENABLE_USER_SCRIPT_SANDBOXING']      = 'YES'
  s['GENERATE_INFOPLIST_FILE']            = 'YES'
  s['INFOPLIST_FILE']                     = 'TeakLiveActivityWidget/Info.plist'
  s['INFOPLIST_KEY_CFBundleDisplayName']   = 'TeakLiveActivityWidget'
  s['INFOPLIST_KEY_NSHumanReadableCopyright'] = ''
  s['IPHONEOS_DEPLOYMENT_TARGET']         = '18.0'
  s['LD_RUNPATH_SEARCH_PATHS']            = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks'
  ]
  s['MARKETING_VERSION']                  = '1.0'
  s['PRODUCT_BUNDLE_IDENTIFIER']          = 'io.teak.TeakSwiftCleanroomPods.TeakLiveActivityWidget'
  s['PRODUCT_NAME']                       = '$(TARGET_NAME)'
  s['SKIP_INSTALL']                       = 'YES'
  s['SWIFT_EMIT_LOC_STRINGS']             = 'YES'
  s['SWIFT_VERSION']                      = '5.0'
  s['TARGETED_DEVICE_FAMILY']             = '1,2'
end

# --------------------------------------------------------------------------
# 4. Remove auto-added Foundation.framework (unnecessary for WidgetKit ext)
# --------------------------------------------------------------------------
widget_target.frameworks_build_phase.files.dup.each do |f|
  ref = f.file_ref
  if ref && (ref.name == 'Foundation.framework' || ref.path.to_s.include?('Foundation'))
    f.remove_from_project
  end
end

# --------------------------------------------------------------------------
# 5. Create TeakLiveActivityWidget/ synchronized root group
# --------------------------------------------------------------------------
widget_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
widget_group.path = 'TeakLiveActivityWidget'
widget_group.source_tree = '<group>'

# Exclude Info.plist from auto-compilation (handled via INFOPLIST_FILE setting)
exception_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
exception_set.target = widget_target
exception_set.membership_exceptions = ['Info.plist']
widget_group.exceptions << exception_set

# Insert into main group before Products
project.main_group.children.insert(products_index + 1, widget_group)

# Add to widget target so TeakLiveActivityWidget/ files compile for the widget
widget_target.file_system_synchronized_groups << widget_group

# --------------------------------------------------------------------------
# 6. Add Shared/ group to widget target too
# --------------------------------------------------------------------------
widget_target.file_system_synchronized_groups << shared_group

# --------------------------------------------------------------------------
# 7. Wire widget into main app: dependency + embed
# --------------------------------------------------------------------------
main_target.add_dependency(widget_target)

# Find existing "Embed Foundation Extensions" phase
embed_phase = main_target.build_phases.find { |bp|
  bp.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
  bp.name == 'Embed Foundation Extensions'
}
abort("Could not find 'Embed Foundation Extensions' build phase") unless embed_phase

build_file = embed_phase.add_file_reference(widget_target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Add product to Products group
products_group = project.main_group.children.find { |c| c.display_name == 'Products' }
products_group.children << widget_target.product_reference if products_group

# --------------------------------------------------------------------------
# 8. Add TargetAttributes
# --------------------------------------------------------------------------
attrs = project.root_object.attributes['TargetAttributes'] || {}
attrs[widget_target.uuid] = { 'CreatedOnToolsVersion' => '16.4' }
project.root_object.attributes['TargetAttributes'] = attrs

# --------------------------------------------------------------------------
# 9. Save
# --------------------------------------------------------------------------
project.save
puts "Successfully added TeakLiveActivityWidget target and Shared group."
puts "Targets: #{project.targets.map(&:name).inspect}"
