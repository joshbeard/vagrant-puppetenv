class role::puppet::ca {
  include profile::base
  include profile::base::linux
  include profile::puppet::master
}
