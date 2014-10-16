## Profile for managing Puppet masters that are *not* CA servers
class profile::puppet::noca {

  ## Disable the CA functionality
  ini_setting { 'puppet.conf_ca':
    ensure  => 'present',
    section => 'master',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'ca',
    value   => 'false',
  }

  ## Change the PE httpd revocation to disable CA functionality
  file_line { 'pe-httpd_revocation':
    ensure => 'present',
    match  => 'SSLCARevocationFile',
    line   => '    SSLCARevocationFile     /etc/puppetlabs/puppet/ssl/crl.pem',
    path   => '/etc/puppetlabs/httpd/conf.d/puppetmaster.conf',
  }

}
