# Dockerized Atlassian Confluence deployment for Puppet

Deploy Atlassian Confluence using a Docker container. The standard image is
[cptactionhank/atlassian-confluence](https://hub.docker.com/r/cptactionhank/atlassian-confluence/).


## Open Items

* Tests
* Tests
* Tests


## Most simple example

```puppet
class { 'dockerized_confluence': }
```


## Confluence behind a reverse proxy

```puppet
class { 'dockerized_confluence':
  reverse_proxy        => true,
  reverse_proxy_scheme => 'https',
  reverse_proxy_url    => 'outside.url.com',
}
```

Please see the `manifests/init.pp` file for extended documentation.
