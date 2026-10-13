# Sets up the iOS dev/prod flavors in Runner.xcodeproj, as Android has them.
# Idempotent: running it again changes nothing. Run from the repository root:
#   ruby ios/scripts/setup_flavors.rb
#
# - Build configurations Debug-dev, Release-dev, Profile-dev, Debug-prod,
#   Release-prod, Profile-prod (copies of Debug/Release/Profile, same Flutter
#   xcconfig), on the project and both targets. The original Debug/Release/
#   Profile stay as they were.
# - Bundle ids: dev com.londonmystery.app.dev, prod com.londonmystery.app;
#   home-screen names "London Mystery DEV" / "London Mystery".
# - LM_FLAVOR build setting, read by the "Firebase config (flavor)" phase,
#   which copies ios/config/<flavor>/GoogleService-Info.plist (git-ignored)
#   into the app and refuses one made for another bundle id.
# - Shared schemes dev and prod (what `flutter run --flavor` looks for).
require 'xcodeproj'

ROOT = File.expand_path('../..', __dir__)
PROJECT = File.join(ROOT, 'ios/Runner.xcodeproj')
FLAVORS = {
  'dev' => { bundle: 'com.londonmystery.app.dev', name: 'London Mystery DEV' },
  'prod' => { bundle: 'com.londonmystery.app', name: 'London Mystery' },
}.freeze
BASES = %w[Debug Release Profile].freeze
PHASE = 'Firebase config (flavor)'.freeze
SCRIPT = <<~'SH'.freeze
  # Copies the flavor's Firebase config into the app (see ios/scripts/setup_flavors.rb).
  DST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
  if [ -z "${LM_FLAVOR}" ]; then
    rm -f "$DST"; echo "No flavor: no Firebase config (the game plays as a guest)."; exit 0
  fi
  SRC="${PROJECT_DIR}/config/${LM_FLAVOR}/GoogleService-Info.plist"
  if [ ! -f "$SRC" ]; then
    rm -f "$DST"; echo "warning: no ios/config/${LM_FLAVOR}/GoogleService-Info.plist: Firebase stays off for this build."; exit 0
  fi
  ID=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$SRC" 2>/dev/null)
  if [ "$ID" != "${PRODUCT_BUNDLE_IDENTIFIER}" ]; then
    echo "error: ios/config/${LM_FLAVOR}/GoogleService-Info.plist is for '$ID', this build is '${PRODUCT_BUNDLE_IDENTIFIER}'."; exit 1
  fi
  cp "$SRC" "$DST"; echo "Firebase config: ${LM_FLAVOR} ($ID)"
SH

project = Xcodeproj::Project.open(PROJECT)
runner = project.targets.find { |t| t.name == 'Runner' } or abort('no Runner target')
tests = project.targets.find { |t| t.name == 'RunnerTests' }

def copy_config(list, base_name, new_name, project)
  return list[new_name] if list[new_name]
  base = list[base_name] or abort("no #{base_name} in #{list}")
  config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  config.name = new_name
  config.build_settings = Marshal.load(Marshal.dump(base.build_settings))
  config.base_configuration_reference = base.base_configuration_reference
  list.build_configurations << config
  config
end

# The original configurations keep their name on the home screen.
BASES.each { |b| runner.build_configuration_list[b].build_settings['APP_DISPLAY_NAME'] = 'London Mystery' }

BASES.each do |base|
  FLAVORS.each do |flavor, info|
    name = "#{base}-#{flavor}"
    copy_config(project.build_configuration_list, base, name, project)
    r = copy_config(runner.build_configuration_list, base, name, project)
    r.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = info[:bundle]
    r.build_settings['APP_DISPLAY_NAME'] = info[:name]
    r.build_settings['LM_FLAVOR'] = flavor
    next unless tests
    t = copy_config(tests.build_configuration_list, base, name, project)
    t.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{info[:bundle]}.RunnerTests"
  end
end

phase = runner.shell_script_build_phases.find { |p| p.name == PHASE }
unless phase
  phase = runner.new_shell_script_build_phase(PHASE)
  # After the resources are copied, so the app's resource folder exists.
  resources = runner.resources_build_phase
  runner.build_phases.delete(phase)
  runner.build_phases.insert(runner.build_phases.index(resources) + 1, phase)
end
phase.shell_path = '/bin/sh'
phase.shell_script = SCRIPT
phase.input_paths = ['$(PROJECT_DIR)/config/$(LM_FLAVOR)/GoogleService-Info.plist']
phase.output_paths = ['$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist']
phase.always_out_of_date = '1'

project.save

# Shared schemes dev / prod: the Runner scheme with the flavor's configurations.
schemes = File.join(PROJECT, 'xcshareddata/xcschemes')
runner_scheme = File.read(File.join(schemes, 'Runner.xcscheme'))
FLAVORS.each_key do |flavor|
  xml = runner_scheme
        .gsub('buildConfiguration = "Debug"', "buildConfiguration = \"Debug-#{flavor}\"")
        .gsub('buildConfiguration = "Release"', "buildConfiguration = \"Release-#{flavor}\"")
        .gsub('buildConfiguration = "Profile"', "buildConfiguration = \"Profile-#{flavor}\"")
  File.write(File.join(schemes, "#{flavor}.xcscheme"), xml)
end

puts "Flavors ready: #{FLAVORS.keys.join(', ')} (configs: #{project.build_configuration_list.build_configurations.map(&:name).join(', ')})"
