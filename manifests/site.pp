# Copyright (C) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

define mailman::site ($default_email_host, $default_url_host)
{
  include ::httpd

  $root = "/srv/mailman/${name}"
  $dirs = [
    "${root}/",
    "${root}/etc",
    "${root}/lists",
    "${root}/logs",
    "${root}/locks",
    "${root}/data",
    "${root}/spam",
    "${root}/mail",
    "${root}/run",
    "${root}/archives",
    "${root}/archives/public",
    "${root}/archives/private",
    "${root}/qfiles",
    "${root}/qfiles/in",
    "${root}/qfiles/out",
    "${root}/qfiles/commands",
    "${root}/qfiles/bounces",
    "${root}/qfiles/news",
    "${root}/qfiles/archive",
    "${root}/qfiles/shunt",
    "${root}/qfiles/virgin",
    "${root}/qfiles/bad",
    "${root}/qfiles/retry",
    "${root}/qfiles/maildir",
  ]

  file { $dirs:
    ensure => directory,
    owner  => 'list',
    group  => 'list',
    mode   => '2775',
  }

  file { "/srv/mailman/${name}/etc/mm_cfg_local.py":
    ensure  => present,
    content => template('mailman/mm_site_cfg.py.erb'),
  }

  if ! defined(File['/etc/mailman/sites']) {
    file { '/etc/mailman/sites':
      ensure => present,
    }
  }

  file_line { "mailman_site_file_${name}":
    require => File['/etc/mailman/sites'],
    path    => '/etc/mailman/sites',
    line    => "${default_email_host}: /srv/mailman/${name}",
  }

  ::httpd::vhost { $default_url_host:
    port     => 80,
    docroot  => '/var/www/',
    priority => '50',
    template => 'mailman/mailman_multihost.vhost.erb',
  }

  file { "/etc/init.d/mailman-${name}":
    ensure  => present,
    content => template('mailman/mailman.init.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  service { "mailman-${name}":
    enable     => true,
    hasrestart => true,
    hasstatus  => false,
    require    => File["/etc/init.d/mailman-${name}"],
  }
}
