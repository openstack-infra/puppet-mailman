file { '/srv/mailman':
  ensure => directory,
}
class { 'mailman':
  vhost_name => 'lists.openstack.org',
}
