###############################################################################
## site.pp
## This is a 'global' manifest file that's compiled for every agent when it
## requests a catalog.  Note that this is environment-specific.
###############################################################################

$fact_stomp_server = 'master.vagrant.vm'
$activemq_brokers  = 'master.vagrant.vm'

## Uncomment the following two lines to enable the second master as a STOMP
## server and ActiveMQ broker.  Comment out the two lines above.
#$fact_stomp_server = 'master.vagrant.vm,puppetmaster1.vagrant.vm'
#$activemq_brokers  = 'master.vagrant.vm,puppetmaster1.vagrant.vm'

## Setup the filebucket
filebucket { 'main':
  server => $::servername,
  path   => false,
}

## Any file resource will use the 'main' filebucket by default.
File { backup => 'main' }

## Avoid deprecation warnings about the 'allow_virtual' parameter for packages.
Package {
  allow_virtual => true,
}

## Classify the GitLab server
node /^gitlab/ {
  include role::gitlab
}

## Classify the default, primary master/ca
node /^master/ {
  include role::puppet::ca
}

## This is for additional "compile masters"
node /^puppetmaster/ {
  include role::puppet::master
}

## Our optional HAProxy for Puppet
node /^haproxy/ {
  include role::haproxy
}

## The next two node declarations are for the example systems.  You can
## comment these out to demonstrate classifying via different means
node /^venus/ {
  include role::venus
}

node /^pluto/ {
  include role::plutoweb
}


node default {
  ## Empty for now.  You can classify with:
  ## - PE Console
  ## - This file right here
  ## - Hiera
  ## - Custom ENC (not in this demo)
  ##
  ## To classify with Hiera, add an array in Hiera called 'classes' and
  ## uncomment the following line.
  #hiera_include('classes')

  ## We want agents that aren't specifically classified with something to use
  ## the default role.
  include role::agent
}

## Want to try 'deploy to noop'?  Uncomment the following and toggle the
## 'force_noop' key in Hiera
#$force_noop = hiera('force_noop')
#unless false == $force_noop {
#  notify { "Puppet noop safety latch is enabled in site.pp!": }
#  noop()
#}
