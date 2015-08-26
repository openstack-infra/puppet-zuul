exec { 'starting zuul server':
  command => '/etc/init.d/zuul start',
}

exec { 'starting zuul merger':
  command => '/etc/init.d/zuul-merger start'
}
