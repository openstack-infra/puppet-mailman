# == Class: mailman
#
class mailman($vhost_name=$::fqdn) {

  include ::httpd

  package { 'mailman':
    ensure => installed,
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    docroot  => '/var/www/',
    priority => '50',
    template => 'mailman/mailman.vhost.erb',
  }
  httpd_mod { 'rewrite':
    ensure => present,
  }
  httpd_mod { 'cgid':
    ensure => present,
  }

  file { '/var/www/index.html':
    ensure  => present,
    source  => 'puppet:///modules/mailman/index.html',
    owner   => 'root',
    group   => 'root',
    replace => true,
    mode    => '0444',
    require => Httpd::Vhost[$vhost_name],
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

  file { '/etc/mailman/en':
    ensure  => directory,
    owner   => 'root',
    group   => 'list',
    mode    => '0644',
    recurse => true,
    require => Package['mailman'],
    source  => 'puppet:///modules/mailman/html-templates-en',
  }
}
