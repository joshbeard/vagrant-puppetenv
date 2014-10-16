class profile::haproxy {
  class { '::haproxy': }

  haproxy::listen { 'puppet00':
    ipaddress => $::ipaddress_eth1,
    ports     => '8140',
    options   => {
      'mode'  => 'tcp',
    },
  }

  haproxy::listen { 'stats':
    ipaddress => $::ipaddress_eth1,
    ports     => '9090',
    options   => {
      'mode'  => 'http',
      'stats' => ['uri /', 'auth puppet:puppet']
      },
  }

  firewall { '100 allow puppet':
    port   => [8140],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '110 allow haproxy stats':
    port   => [9090],
    proto  => 'tcp',
    action => 'accept',
  }
}
