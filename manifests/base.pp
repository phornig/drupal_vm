file { '/etc/motd':
  content => "Welcome to the Pixelpark Drupal VM!\nManaged by Puppet.\n----------------\nAliases:\nshared: Go to shared directory\nsrc: Go to shared/src directory\n----------------\n",
}

file { '/home/vagrant/.bash_aliases':
  ensure => present,
  content => "alias ..='cd ..'\nalias shared=' cd /vagrant'\nalias src='cd /vagrant/src'",
  owner => 'vagrant',
  group => 'vagrant',
}

class { 'apache': }
  
apache::mod { 'rewrite': }

class { 'apache::mod::php': }

class php {
  package {'php':
    name => 'php5',
    ensure => installed,
  }
  
  package {'gd':
    name => 'php5-gd',
    ensure => installed,
    require => Package['php'],
  }
  
  package {'imagick':
    name => 'php5-imagick',
    ensure => installed,
    require => Package['php'],
  }
  
  package {'curl':
    name => 'php5-curl',
    ensure => installed,
    require => Package['php'],
  }
  
  package {'mysql':
    name => 'php5-mysql',
    ensure => installed,
    require => Package['php'],
  }
}

class {'php':}

file {'php.ini':
  ensure => file,
  path => '/etc/php5/apache2/php.ini',
  source => '/tmp/vagrant-puppet/files/php.ini',
  notify => Service['httpd'],
  require => Class['php'],
}

file {'php.ini cli':
  ensure => file,
  path => '/etc/php5/cli/php.ini',
  source => '/tmp/vagrant-puppet/files/php-cli.ini',
  notify => Service['httpd'],
  require => Class['php'],
}

class pecl ($module) {
  package {'php5-dev': 
    ensure => installed,
    require => Class['php'],
  }
  
  exec {"pecl install $module": 
    path => '/usr/bin',
    require => [Class['pear'], Package['php5-dev']],
  }
}

class {'pecl':
  module => 'uploadprogress',
}

class xdebug ($remoteip = $ipaddress, $remoteenabled = '1', $remoteport = '9000') {
  package { "xdebug":
    name => 'php5-xdebug',
    ensure => installed,
    require => Package['php'],
    notify => Service['httpd'],
  }
  
  file {'/etc/php5/conf.d/20-xdebug.ini':
    ensure => file,
    require => Package['xdebug'],
    content => template('xdebug.ini.erb'),
  }
}

class {'xdebug':
  remoteip => '192.168.100.1',
}

class drush {
  class {'pear':}
  
  pear::package {'Console_Table':
    require => Class['pear'],
  }
  
  pear::package {'drush':
    repository => 'pear.drush.org',
    require =>  [Pear::Package['Console_Table'], Class['php']],
  }
}

class {'drush': }

class {'mysql': }

class {'mysql::server': 
  config_hash => {
    'default_engine' => 'innodb',
  }
}

package {'subversion': 
  ensure => installed,
}

package {'git': 
  ensure => installed,
}

file { '/vagrant/src' :
  ensure => directory,
}

apache::vhost { 'creative.arte.tv.local':
  port => '80',
  docroot => '/vagrant/src',
  logroot => "/var/log/$title",
  override => 'All',
  notify => Service['httpd'],
  require => File['/vagrant/src'],
}

mysql::db {'artecreative':
  ensure => present,
  user => 'artecreative',
  password => 'artecreative',
  host => 'localhost',
  grant => ['all'],
  charset => 'utf8',,
  require => Class['apache'],
}