class role::puppet::master {
  include profile::base
  include profile::base::linux

  include profile::puppet::master
  include profile::puppet::noca
  include profile::puppet::mco
}
