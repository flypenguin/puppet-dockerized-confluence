# == dockerized_confluence
#
# Uses the Docker image 'cptactionhank/atlassian-confluence' to deploy
# confluence on your host.
#
# Can set a couple of things to make confluence play nicely behind a reverse
# proxy, or - in the future - using a HTTPS certificate.
#
# The confluence data is currently mounted on the host under
# `/var/docker-apps/confluence` and `/etc/docker-apps/confluence` if a custom
# `server.xml` file is created (when using `reverse_proxy == true`).
#
#
# === Parameters
#
# [*docker_image*]
# The docker image to use, if not 'cptactionhank/atlassian-confluence:latest'.
#
# [*docker_host_port*]
# Set the port which is opened on the host for confluence.
# Default: 8090
#
# [*extra_systemd_parameters*]
# Routed straight through to the docker::run command, in case you want to
# influce the systemd service behavior.
# Default: <undef>
#
# [*reverse_proxy*]
# Set this to <true> if confluence is behind a reverse proxy (e.g. for SSL
# offloading). If set to <true> the next three parameters influence the content
# of the file 'server.xml'. See http://is.gd/ZjYzh3 for details.
# Default: false
#
# [*reverse_proxy_url*]
# Set this to the original URL which users of confluence use.
# Default: <undef>
#
# [*reverse_proxy_port*]
# Set this to the original port the users of confluence use (e.g. 443).
# Default: <undef>
#
# [*reverse_proxy_scheme*]
# Set this to the original protocol scheme the users of confluence use (e.g.
# "https").
# Default: <undef>
#
#
class dockerized_confluence (

  $docker_image               = 'cptactionhank/atlassian-confluence:latest',
  $docker_host_port           = 8090,

  $extra_systemd_parameters   = undef,

  $reverse_proxy              = false,
  $reverse_proxy_url          = undef,
  $reverse_proxy_scheme       = undef,
  $reverse_proxy_port         = undef,

) {

  include profiles::docker_app_server

  File<|tag == 'confluence_service'|> -> Docker::Run['confluence']


  if $reverse_proxy {

    mkdir::p { '/etc/docker-apps/confluence':
      declare_file => true,
    }

    file { '/etc/docker-apps/confluence/server.xml':
      ensure  => 'present',
      content => template('dockerized_confluence/server.xml.erb'),
      tag     => ['confluence_service'],
    }

    # mount in server.xml with the information about the reverse proxy
    $use_docker_volumes = [
      '/var/docker-apps/confluence:/var/atlassian/confluence',
      '/etc/docker-apps/confluence/server.xml:/opt/atlassian/confluence/conf/server.xml',
    ]

  } else {

    # purge /etc/docker-apps/confluence cause we don't need it
    file { '/etc/docker-apps/confluence':
      ensure  => 'absent',
      recurse => true,
      force   => true,
      purge   => true,
    }

    # don't mount in the server.xml ;)
    $use_docker_volumes = [
      '/var/docker-apps/confluence:/var/atlassian/confluence',
    ]

  }


  mkdir::p { '/var/docker-apps/confluence':  } ->

  # otherwise the container cannot write into the directory
  # MUST depend on the 'mounted' mount point, since we must
  # modify the MOUNTED directory and not the UNMOUNTED directory.
  file { '/var/docker-apps/confluence':
    ensure => 'directory',
    owner  => 'daemon',
    mode   => '0775',
  } ->

  docker::run { 'confluence':
    image                    => $docker_image,
    volumes                  => $use_docker_volumes,
    ports                    => ["${docker_host_port}:8090",],
    # only run if the mount point is present.
    # prevents MANUAL starting of confluence without mount point.
    extra_systemd_parameters => $extra_systemd_parameters,
    # prevents PUPPET starting confluence without mount point
  }

}
