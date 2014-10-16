class profile::base {
  include ntp

  Ini_setting {
    ensure => 'present',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
  }

  ini_setting { 'puppet.conf_caserver':
    section => 'main',
    setting => 'ca_server',
    value   => 'master.vagrant.vm',
  }

  ini_setting { 'puppet.conf_server':
    section => 'agent',
    setting => 'server',
    value   => 'master.vagrant.vm',
  }
}
