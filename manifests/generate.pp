# Generate a file using the find-ec2 utility
define findec2::generate (
  $template,
  $output,
  $frequency = 5,
  $tags      = undef,
  $tagname   = 'machinetype',
  $tagvalue  = 'web',
  $ownweight = '99999',
  $dummy     = false,
  $dummyhost = undef,
  $service   = undef ) {

  include findec2

  if ($tags != undef) {
    $combined_tags = "$tagname=$tagvalue,$tags"
  } else {
    $combined_tags = "$tagname=$tagvalue"
  }

  $cmd_start = "/usr/bin/find-ec2 --name ${name} --tags ${combined_tags} --ownazweight ${ownweight}"

  if ($dummy) {
    if ($dummyhost != undef) {
      $cmd_middle = "${cmd_start} --dummy --dummyhostname ${dummyhost}"
    } else {
      $cmd_middle = "${cmd_start} --dummy"
    }
  } else {
    $cmd_middle = $cmd_start
  }

  if ($service) { $cmd_final = "${cmd_middle} --notify ${service} ${template} ${output}" }
  else { $cmd_final = "${cmd_middle} ${template} ${output}" }

  cron { $name:
    command => $cmd_final,
    user    => root,
    minute  => "*/${frequency}",
  }

  # Immediately run the cron job; some services (eg Varnish) cannot be started
  # if the included file doesn't exist
  exec { $name:
    command => $cmd_final,
    creates => $output,
    require => Class['findec2'],
  }
}
