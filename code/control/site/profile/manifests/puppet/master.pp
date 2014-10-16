class profile::puppet::master {

  Firewall {
    proto  => 'tcp',
    action => 'accept',
  }

  include pe_mcollective::role::master

  ## The hiera-eyaml config. This is added via the hiera class below.
  $hiera_config = [':eyaml:',
  "  :datadir: \"${::settings::confdir}/environments/%{environment}/hieradata\"",

  "  :pkcs7_private_key: ${::settings::confdir}/keys/private_key.pkcs7.pem",
  "  :pkcs7_public_key: ${::settings::confdir}/keys/public_key.pkcs7.pem",
  '  :extension: "yaml"',
  ]

  ## Install hiera-eyaml using Puppet Enterprise's 'gem'
  package { 'hiera-eyaml':
    ensure   => 'installed',
    provider => 'pe_gem',
  }

  ## Manage the keys directory for hiera-eyaml
  file { 'keys_dir':
    ensure => 'directory',
    path   => "${::settings::confdir}/keys",
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0700',
  }

  ## Create an example keypair for hiera-eyaml demo
  exec { 'create_eyaml_keys':
    path    => [ '/opt/puppet/bin' ],
    command => 'eyaml createkeys',
    creates => "${::settings::confdir}/keys/private_key.pkcs7.pem",
    cwd     => $::settings::confdir,
    require => [ Package['hiera-eyaml'], File['keys_dir'] ],
  }

  ##
  ## Configure Hiera
  ##
  class { 'hiera':
    hierarchy => [
      'nodes/%{clientcert}',
      '%{environment}/%{app_tier}',
      '%{app_tier}',
      '%{environment}',
      'common',
    ],
    datadir      => "${::settings::confdir}/environments/%{environment}/hieradata",
    backends     => ['eyaml', 'yaml'],
    extra_config => join($hiera_config, "\n"),
    notify       => Service['pe-httpd'],
  }

  ##
  ## Configure r10k
  ##
  class { 'r10k':
    sources  => {
      'control' => {
        'remote'  => 'git@gitlab.vagrant.vm:puppet/control.git',
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    },
    purgedirs         => ["${::settings::confdir}/environments" ],
    manage_modulepath => false,
    mcollective       => true,
    version           => '1.3.4',
    notify            => Service['pe-httpd'],
  }

  include r10k::webhook

  ## The webhook service is provided by the 'r10k::webhook' class
  class { 'r10k::webhook::config':
    enable_ssl => false,
    protected  => false,
    notify     => Service['webhook'],
  }

  ##  Autosign our vagrant instances
  file { 'autosign':
    ensure  => 'present',
    content => '*.vagrant.vm',
    path    => '/etc/puppetlabs/puppet/autosign.conf',
  }

  ## Manage the directory for Puppet's directory environments
  file { "${::settings::confdir}/environments":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  ## Where can Puppet find the 'base' modules (e.g. not environment modules)
  ini_setting { 'basemodulepath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => "${::settings::confdir}/modules:/opt/puppet/share/puppet/modules",
    notify  => Service['pe-httpd'],
  }

  ## Where can Puppet find its environments?
  ini_setting { 'environmentpath':
    ensure  => 'present',
    path    => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value   => "${::settings::confdir}/environments",
    notify  => Service['pe-httpd'],
  }

  ## Manage pe-httpd so we can notify it
  service { 'pe-httpd':
    ensure => 'running',
    enable => true,
  }

  ## For Vagrant, let's manage root's .ssh
  file { '/root/.ssh':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  ## Accept the Gitlab server's identity blindly so we can run r10k right
  ## away without having to accept the host identity
  file { '/root/.ssh/config':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "Host 192.168.137.11 gitlab.vagrant.vm\n  StrictHostKeyChecking no",
  }

  ## Create an SSH keypair for use with Gitlab and r10k
  exec { 'create_ssh_keys':
    path    => [ '/usr/bin' ],
    command => "ssh-keygen -f /root/.ssh/id_rsa -N ''",
    creates => '/root/.ssh/id_rsa',
    require => File['/root/.ssh'],
  }

  firewall { '100 allow puppet':
    port   => '8140',
  }

  firewall { '110 activemq/mcollective':
    port   => [61613, 61616],
  }

  firewall { '120 r10k webhook':
    port   => '8088',
  }

  firewall { '130 puppetdb':
    port   => '8081',
  }

  firewall { '140 enterprise console':
    port   => '443',
  }

  ## Exported resource to add this master to a load balancer pool
  @@haproxy::balancermember { "proxy_${fqdn}":
    listening_service => 'puppet00',
    ports             => '8140',
    server_names      => $::fqdn,
    ipaddresses       => $::ipaddress_eth1,
    options           => 'check',
  }

}
