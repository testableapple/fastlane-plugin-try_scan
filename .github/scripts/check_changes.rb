require 'json'

raise "Projects folder names have to be provided to trigger the tests" if ENV['TRIGGERS'].nil?

required_projects = ENV['TRIGGERS'].split(',').map {|project| project.strip }
except_projects = ENV['EXCLUDE_TRIGGERS'].nil? ? [] : ENV['EXCLUDE_TRIGGERS'].split(',').map {|project| project.strip }
response = JSON.parse(`curl -s -H "authorization: Bearer #{ENV['GITHUB_TOKEN']}" -X GET -G #{ENV['PULL_REQUEST']}/files`)
changed_files = response.map { |file| file['filename'] }
changed_files.select! do |path|
  required_projects.any? do |required_project|
    path.include?("#{required_project}/") && except_projects.none? { |excess_project| path.include?("#{excess_project}/") }
  end
end

puts changed_files.size
