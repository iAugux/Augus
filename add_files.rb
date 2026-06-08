require 'xcodeproj'

project_path = 'Augus.xcodeproj'
project = Xcodeproj::Project.open(project_path)

augus_target = project.targets.find { |t| t.name == 'Augus' }
widgets_target = project.targets.find { |t| t.name == 'Widgets' }

def add_file_to_target(project, target, file_path, group_path)
  group = project.main_group.find_subpath(group_path, true)
  file_ref = group.files.find { |f| f.path == file_path.split('/').last }
  
  if file_ref.nil?
    file_ref = group.new_file(file_path)
  end

  if target && !target.source_build_phase.files_references.include?(file_ref)
    target.add_file_references([file_ref])
    puts "Added #{file_path} to #{target.name}"
  end
end

# Add Augus files
add_file_to_target(project, augus_target, 'Augus/MenuBarViewModel.swift', 'Augus')
add_file_to_target(project, augus_target, 'Augus/MenuBarWidgetView.swift', 'Augus')

# Add Shared files to BOTH targets
['BlackSSLUI.swift', 'CodexUI.swift', 'GeminiUI.swift', 'AntigravityUI.swift'].each do |file|
  path = "Shared/#{file}"
  add_file_to_target(project, augus_target, path, 'Shared')
  add_file_to_target(project, widgets_target, path, 'Shared')
end

# Add Intent files to Widgets target only
['RefreshCodexIntent.swift', 'RefreshBlackSSLIntent.swift'].each do |file|
  path = "Widgets/#{file}"
  add_file_to_target(project, widgets_target, path, 'Widgets')
end

project.save
puts "Successfully updated project.pbxproj"
