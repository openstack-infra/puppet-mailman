vcsrepo { '/opt/system-config':
  ensure => present,
  source => 'https://git.openstack.org/openstack-infra/system-config',
  provider => git,
}
file { '/srv/mailman/openstack/templates/en':
  ensure  => directory,
  owner   => 'root',
  group   => 'list',
  mode    => '0644',
  recurse => true,
  require => File['/srv/mailman/openstack/templates'],
  source  => '/opt/system-config/modules/openstack_project/files/mailman/html-templates-en',
}
class { 'mailman':
  multihost => true,
}
mailman::site { 'openstack':
  default_email_host => 'lists.openstack.org',
  default_url_host   => 'lists.openstack.org',
  install_languages  => ['de', 'fr', 'it', 'ko', 'ru', 'vi', 'zh_TW'],
  require            => Class['mailman'],
}
mailman_list { 'mailman@openstack':
  require     => Mailman::Site['openstack'],
  ensure      => present,
  admin       => 'nobody@openstack.org',
  password    => 'listpassword',
  description => 'The mailman site list',
}
