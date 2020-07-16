require 'json'

raise "Projects folder names have to be provided to trigger the tests" if ENV['TRIGGERS'].nil?

required_projects = ENV['TRIGGERS'].delete(' ').delete('/').split(',')
response = JSON.parse(`curl -s -H "authorization: Bearer #{ENV['GITHUB_TOKEN']}" -X GET -G #{ENV['PULL_REQUEST']}/files`)
changed_files = response.map { |file| file['filename'] }
changes = changed_files.select { |path| required_projects.any? { |project| path.include?("#{project}/") } }.size

puts changes
