# run a test task
require 'spec_helper_acceptance'

describe 'lockfile_details task' do
  describe 'lockfile_details' do
    it 'execute runs when no lockfiles present' do
      result = run_task(task_name: 'lockfile_tasks::lockfile_details')
      expect_multiple_regexes(result: result, regexes: [
        %r{Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock},
        %r{Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock},
        %r{Catalog Lockfile absent},
        %r{Admin Disable Lockfile absent},
        %r{Ran on 1 node in .+ seconds}
      ])
    end

    it 'execute runs when catalog lockfile present and process absent' do
      shell('mkdir -p /opt/puppetlabs/puppet/cache/state/', acceptable_exit_codes: [0])
      create_remote_file(master, "/opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock", '7777')
      result = run_task(task_name: 'lockfile_tasks::lockfile_details')
      expect_multiple_regexes(result: result, regexes: [
        %r{Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock},
        %r{Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock},
        %r{Catalog Lockfile present, PID in file is 7777},
        %r{PID 7777 is not running},
        %r{Ran on 1 node in .+ seconds}
      ])
    end

    it 'execute runs when catalog lockfile present and process present and not older than an hour' do
      shell('mkdir -p /opt/puppetlabs/puppet/cache/state/', acceptable_exit_codes: [0])
      shell('rm -rf /opt/puppetlabs/puppet/cache/state/*', acceptable_exit_codes: [0])
      shell('python -m SimpleHTTPServer 8000 &> /dev/null & echo $! >> /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock', acceptable_exit_codes: [0])
      result = run_task(task_name: 'lockfile_tasks::lockfile_details')
      expect_multiple_regexes(result: result, regexes: [
        %r{Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock},
        %r{Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock},
        %r{Catalog Lockfile present, PID in file is .+},
        %r{PID .+ is running},
        %r{Ran on 1 node in .+ seconds}
      ])
    end

    it 'execute runs when catalog lockfile present and process present and older than an hour' do
      shell('mkdir -p /opt/puppetlabs/puppet/cache/state/', acceptable_exit_codes: [0])
      shell('rm -rf /opt/puppetlabs/puppet/cache/state/*', acceptable_exit_codes: [0])
      shell('python -m SimpleHTTPServer 8001 &> /dev/null & echo $! >> /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock', acceptable_exit_codes: [0])
      shell('touch -d "2016-01-31 8:46:26" /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock', acceptable_exit_codes: [0])
      result = run_task(task_name: 'lockfile_tasks::lockfile_details')
      expect_multiple_regexes(result: result, regexes: [
        %r{Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock},
        %r{Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock},
        %r{Catalog Lockfile present, PID in file is .+},
        %r{PID .+ is running},
        %r{Ran on 1 node in .+ seconds}
      ])
    end

    it 'execute runs when admin lockfile present' do
      shell('puppet agent --disable "rspec test"', acceptable_exit_codes: [0])
      result = run_task(task_name: 'lockfile_tasks::lockfile_details')
      expect_multiple_regexes(result: result, regexes: [
        %r{Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock},
        %r{Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock},
        %r{Admin Disable Lockfile present, reason for agent disable given is 'rspec test'},
        %r{Ran on 1 node in .+ seconds}
      ])
    end
  end
end
