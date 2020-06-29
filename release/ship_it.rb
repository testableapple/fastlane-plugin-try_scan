gem_path = `rake build`.split(' ').last.chomp('.')
if File.file?(gem_path)
  gem_ver = 'v' + gem_path.scan(/\d/).join('.')
  puts "try_scan: publishing gem '#{gem_ver}', right? 🤔"
  if gets.to_s.downcase =~ /y/
    puts 'try_scan: okie dokie 🚀'
    output = `gem push #{gem_path} -k alteral`
    puts output
    if output.include?('Successfully registered gem')
      puts `git tag #{gem_ver} && git push origin #{gem_ver}`
    end
  else
    puts 'try_scan: okay 😐'
  end
else
  "try_scan: Something wrong with '#{gem_path}' 🏌️‍♂️"
end
