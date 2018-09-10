file { '/srv/mailman':
  ensure => directory,
}
class { 'mailman':
  vhost_name => 'lists.openstack.org',
}
Maillist {
  provider    => 'noaliasmailman',
}
maillist { 'kata-dev':
  ensure      => present,
  admin       => 'jonathan@openstack.org',
  password    => 'listpassword',
  description => 'Kata Containers Development Mailing List (not for usage questions)',
  webserver   => $listdomain,
  mailserver  => $listdomain,
}
