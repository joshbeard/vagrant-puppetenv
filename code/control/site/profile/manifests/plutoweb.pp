## Sample profile for a PHP web application using Apache
class profile::plutoweb {

  ## Hiera lookups
  $site_name = hiera('profile::plutoweb::site_name')
  $docroot   = hiera('profile::plutoweb::docroot')
  $port      = hiera('profile::plutoweb::port')
  $user      = hiera('profile::plutoweb::user')
  $group     = hiera('profile::plutoweb::group')

  ## Create user/group for the plutoweb
  group { 'plutoweb_group':
    ensure => 'present',
    name   => $group,
  }

  user { 'plutoweb_user':
    ensure => 'present',
    name   => $user,
  }


  ## Apache Configuration
  include apache
  include apache::mod::php

  apache::vhost { $::fqdn:
    port     => $port,
    docroot  => $docroot,
    priority => '10',
  }

  ## Deployment of the application.
  ## Realistically, this will be more sophisticated than this.
  file { 'plutoapp':
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    path    => "${docroot}/index.php",
    content => '<?php echo("Plutoweb!"); phpinfo(); ?>',
    require => Apache::Vhost[$::fqdn],
  }

  ## Open the firewall for port 80
  firewall { '110 allow http':
    port   => '80',
    proto  => 'tcp',
    action => 'accept',
  }

}
