#!/opt/puppetlabs/puppet/bin/ruby
require 'open3'
require 'puppet'
require 'etc'

begin
  Puppet.initialize_settings
rescue
  # do nothing otherwise calling init twice raises an error
end

MAX_AGE = 60

def age_of_lockfile(lockfile_path)
  age = Time.now - File.mtime(lockfile_path)
  (age /= 60).round(2)
end

def is_process_alive?(pid)
  Process.getpgid(pid.to_i)
  true
rescue Errno::ESRCH
  false
end

def get_agent_disable_reason(json_string)
  require 'json'
  disable_hash = JSON.parse(json_string)
  disable_hash['disabled_message']
end

effective_user = Etc.getpwuid(Process.euid)

if effective_user.uid != 0
  puts "WARNING: You\'re running these lockfile checks as the non-root user '#{effective_user.name}'"
  puts 'WARNING: Unless you\'re running the Puppet agent as non-root, we recomend you run this task as root or with sudo'
end

puts "Configured Catalog run lockfile setting is #{Puppet[:agent_catalog_run_lockfile]}"
puts "Configured Admin Lockfile setting is #{Puppet[:agent_disabled_lockfile]}"

if File.exist?(Puppet[:agent_catalog_run_lockfile])
  puts "Catalog Lockfile present, PID in file is #{File.read(Puppet[:agent_catalog_run_lockfile])}"
  pid = File.read(Puppet[:agent_catalog_run_lockfile]).strip
  if is_process_alive?(pid)
    puts "PID #{pid} is running"
    lockfile_age = age_of_lockfile(Puppet[:agent_catalog_run_lockfile])
    puts "Lockfile is #{age_of_lockfile(Puppet[:agent_catalog_run_lockfile])} minutes old"
    if lockfile_age > MAX_AGE
      puts 'Lockfile is over an hour old, so we consider it stale and it might be worth killing the process'
      puts 'This could be due to a bug (such as https://tickets.puppetlabs.com/browse/PUP-7517) or a long-running process in a Puppet run'
    end
  else
    puts "PID #{pid} is not running"
  end
else
  puts 'Catalog Lockfile absent'
end

if File.exist?(Puppet[:agent_disabled_lockfile])
  puts "Admin Disable Lockfile present, reason for agent disable given is '#{get_agent_disable_reason(File.read(Puppet[:agent_disabled_lockfile]))}'"
else
  puts 'Admin Disable Lockfile absent'
end
