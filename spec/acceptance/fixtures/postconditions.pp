exec { 'starting zuul scheduler':
  command => '/etc/init.d/zuul-scheduler start',
}

exec { 'starting zuul merger':
  command => '/etc/init.d/zuul-merger start'
}
