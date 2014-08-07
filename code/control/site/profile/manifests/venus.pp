## Sample profile for a Tomcat application
class profile::venus {
  include java

  $catalina_home = hiera('profile::venus::catalina_home')
  $catalina_base = hiera('profile::venus::catalina_base')
  $user          = hiera('profile::venus::user')
  $group         = hiera('profile::venus::group')
  $source_url    = hiera('profile::venus::source_url')
  $java_home     = hiera('profile::venus::java_home')
  $service_name  = hiera('profile::venus::service_name')
  $war_url       = hiera('profile::venus::war_url')

  ## The Tomcat module doesn't manage the home directory.  Let's make sure
  ## it exists here.
  file { '/home/tomcat':
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }

  class { 'tomcat':
    catalina_home => $catalina_home,
    user          => $user,
    group         => $group,
  }

  tomcat::instance { 'tomcat7':
    catalina_home => $catalina_home,
    catalina_base => $catalina_base,
    source_url    => $source_url,
    require       => File['/home/tomcat'],
  }

  tomcat::service { $service_name:
    catalina_home => $catalina_home,
    catalina_base => $catalina_base,
    use_init      => false,
    use_jsvc      => false,
    require       => Tomcat::Instance['tomcat7'],
  }

  tomcat::war { 'sample.war':
    catalina_base => $catalina_base,
    war_source    => $war_url,
    require       => Tomcat::Instance['tomcat7'],
  }

  firewall { '100 allow venusapp':
    port   => '8080',
    proto  => 'tcp',
    action => 'accept',
  }
}
