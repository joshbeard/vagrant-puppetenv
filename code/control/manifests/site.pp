filebucket { 'main':
  server => $::servername,
  path   => false,
}

File { backup => 'main' }

Package {
  allow_virtual => true,
}

## The next two node declarations are for the master and gitlab server
node /^gitlab/ {
  include role::gitlab
}

node /^master/ {
  include role::puppet::master
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
}

## Want to try 'deploy to noop'?  Uncomment the following and toggle the
## 'force_noop' key in Hiera
#$force_noop = hiera('force_noop')
#unless false == $force_noop {
#  notify { "Puppet noop safety latch is enabled in site.pp!": }
#  noop()
#}
