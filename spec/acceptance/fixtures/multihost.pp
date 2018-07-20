file { '/srv/mailman':
  ensure => directory,
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
