# This just places a sample /etc/motd file from a template
class motd (
  $test_string = "The default string",
) {
  file { '/etc/motd':
    ensure  => 'file',
    content => template('motd/motd.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
