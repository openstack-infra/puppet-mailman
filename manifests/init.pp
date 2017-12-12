# == Class: mailman
#
class mailman(
  $vhost_name = $::fqdn,
  $multihost = false,
) {

  include ::httpd

  package { 'mailman':
    ensure => installed,
  }

  if ($multihost) {
    file { '/etc/mailman/mm_cfg.py':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('mailman/mm_cfg_multihost.py.erb'),
      replace => true,
      require => Package['mailman'],
    }
  } else {
    ::httpd::vhost { $vhost_name:
      port     => 80,
      docroot  => '/var/www/',
      priority => '50',
      template => 'mailman/mailman.vhost.erb',
    }
    file { '/etc/mailman/mm_cfg.py':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('mailman/mm_cfg.py.erb'),
      replace => true,
      require => Package['mailman'],
    }
    service { 'mailman':
      ensure     => running,
      hasrestart => true,
      hasstatus  => false,
      subscribe  => File['/etc/mailman/mm_cfg.py'],
      require    => Package['mailman'],
    }
  }

  httpd_mod { 'rewrite':
    ensure => present,
    before => Service['httpd'],
  }

  httpd_mod { 'cgid':
    ensure => present,
    before => Service['httpd'],
  }

  file { '/etc/mailman/en':
    ensure  => directory,
    owner   => 'root',
    group   => 'list',
    mode    => '0644',
    recurse => true,
    require => Package['mailman'],
    source  => 'puppet:///modules/mailman/html-templates-en',
  }

  file { '/var/www/index.html':
    ensure  => present,
    source  => 'puppet:///modules/mailman/index.html',
    owner   => 'root',
    group   => 'root',
    replace => true,
    mode    => '0444',
  }
}
