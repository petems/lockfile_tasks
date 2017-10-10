# lockfile_tasks

[![Build Status](https://travis-ci.org/petems/lockfile_tasks.svg?branch=master)](https://travis-ci.org/petems/lockfile_tasks)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with lockfile_tasks](#setup)
    * [What lockfile_tasks affects](#what-lockfile_tasks-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with lockfile_tasks](#beginning-with-lockfile_tasks)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

Puppet has two main lockfiles:

* `agent_catalog_run_lockfile` - A file created when a Puppet run is happening. The file contains the PID of the running Puppet process
* `agent_disabled_lockfile` - A file created by an admin to stop Puppet runs from occuring, for example `puppet agent --disable "Blocking Puppet during change window - John Smith"

This module contains tasks to inspect, create and delete these Puppet lockfiles on nodes.

There are a few scenarios for needing these tasks or to manually intervene to change the lockfiles:

* A puppet agent process is killed ungracefully (such as with a `kill -9`), which left the old lockfile in place.
* A system hard-rebooted mid Puppet run
* A network issue causes a hung connection to the Puppet master (such as https://tickets.puppetlabs.com/browse/PUP-7517)
* You want to easily mass-disable Puppet runs on a selection of machines for a change-window or to avoid Puppet runs occuring during investigation

## Setup

### What lockfile_tasks affects

This task modifies the Puppet lockfiles, generally `/opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock` and `/opt/puppetlabs/puppet/cache/state/agent_disabled.lock`.

Most of the tasks will have safety-guards to make sure you don't make changes to these files without explicitly asking to, as this can be dangerous. For example,  removing a catalog lockfile whilst an existing Puppet run is happening, causing conflicts.

### Setup Requirements

Relies on Puppet being installed on the target nodes > Puppet 4, as it uses the Puppet ruby path at `/opt/puppetlabs/puppet/bin/ruby`.

It's possible to write code that could work on a Puppet 3 machine, but Puppet 3 is EOL so I won't do it in this module.

### Beginning with lockfile_tasks

Ensure Puppet >= 4 is installed on the target nodes.

## Usage

### `lockfile_tasks::lockfile_details`

```bash
bolt task run lockfile_tasks::lockfile_details --nodes lockfile-tasks.puppet.vm
```

This will give different outputs depending on the presence of lockfiles and the pids or reasons mentioned in the lockfiles:

#### Admin lockfile present and string given

```
lockfile-tasks.puppet.vm:

Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock
Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock
Catalog Lockfile absent
Admin Disable Lockfile present, reason for agent disable given is 'Disabling Puppet runs - John Doe'


Ran on 1 node in 0.53 seconds
```


#### Catalog lockfile present, pid not running

```
lockfile-tasks.puppet.vm:

Configured Catalog run lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock
Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock
Catalog Lockfile present, PID in file is 7777
PID 7777 is not running
Admin Disable Lockfile absent


Ran on 1 node in 0.53 seconds
```

#### Catalog lockfile present, pid running and lockfile not older than an hour

```
Configured Catalog run lockfile setting is /home/vagrant/.puppetlabs/opt/puppet/cache/state/agent_catalog_run.lock
Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock
Catalog Lockfile present, PID in file is 7777
PID 7777 is running
Lockfile is 3 minutes old
Admin Disable Lockfile absent


Ran on 1 node in 0.53 seconds
```

#### Catalog lockfile present, pid running and lockfile older than an hour

```
Configured Catalog run lockfile setting is /home/vagrant/.puppetlabs/opt/puppet/cache/state/agent_catalog_run.lock
Configured Admin Lockfile setting is /opt/puppetlabs/puppet/cache/state/agent_disabled.lock
Catalog Lockfile present, PID in file is 7777
PID 7777 is running
Lockfile is 67 minutes old
Lockfile is over an hour old, so we consider it stale and it might be worth killing the process
This could be due to a bug (such as https://tickets.puppetlabs.com/browse/PUP-7517) or a long-running process in a Puppet run
Admin Disable Lockfile absent


Ran on 1 node in 0.53 seconds
```


## Reference

### `lockfile_tasks::lockfile_details`

`lockfile_tasks::lockfile_details` has no variables or customisation.

## Limitations

Tested on Linux and Windows.

## Development

To test on a local Vagrant VM:

```bash
vagrant up
vagrant ssh-config >> ~/.ssh/config
bolt task run lockfile_tasks --nodes lockfile-tasks.puppet.vm --user vagrant
```

You can also run a quick beaker check:

```
BEAKER_set='ubuntu-1604-docker' bundle exec rspec spec/acceptance/lockfile_details_spec.rb
```

Contribution is welcome.


## Release Notes/Contributors/Etc.

This is the initial release
