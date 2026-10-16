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
# - Removes the "Firebase config (flavor)" build phase and the LM_FLAVOR
#   setting of the builds that had a cloud (the game is offline only).
# - Shared schemes dev and prod (what `flutter run --flavor` looks for).
require 'xcodeproj'

ROOT = File.expand_path('../..', __dir__)
PROJECT = File.join(ROOT, 'ios/Runner.xcodeproj')
FLAVORS = {
  'dev' => { bundle: 'com.londonmystery.app.dev', name: 'London Mystery DEV' },
  'prod' => { bundle: 'com.londonmystery.app', name: 'London Mystery' },
}.freeze
BASES = %w[Debug Release Profile].freeze
OLD_PHASE = 'Firebase config (flavor)'.freeze

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
    r.build_settings.delete('LM_FLAVOR')
    next unless tests
    t = copy_config(tests.build_configuration_list, base, name, project)
    t.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{info[:bundle]}.RunnerTests"
  end
end

runner.shell_script_build_phases.select { |p| p.name == OLD_PHASE }.each(&:remove_from_project)

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
