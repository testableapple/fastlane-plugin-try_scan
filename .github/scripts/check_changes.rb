require 'json'

required_keys = ENV['TRIGGER'].split(',').map {|key| key.strip }
ignore_keys = ENV['IGNORE'].nil? ? [] : ENV['IGNORE'].split(',').map {|key| key.strip }
response = JSON.parse(`curl -s -H "authorization: Bearer #{ENV['GITHUB_TOKEN']}" -X GET -G #{ENV['PULL_REQUEST']}/files`)
impacted_files = response.map { |file| file['filename'] }
impacted_files.select! do |path|
  required_keys.any? do |required_key|
    should_key_be_considered = ignore_keys.none? { |key| path.include?(key) }
    should_key_be_considered && path.include?(required_key)
  end
end

puts impacted_files.size