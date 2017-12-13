# Manage etcd
#
class simp_kubernetes::etcd {

  $client_protocol   = $::simp_kubernetes::etcd_client_protocol
  $client_listen_url = "${client_protocol}://${::simp_kubernetes::etcd_client_listen_address}:${::simp_kubernetes::etcd_client_port}"

  $peers           = $::simp_kubernetes::etcd_peers
  $peer_port       = $::simp_kubernetes::etcd_peer_port
  $peer_protocol   = $::simp_kubernetes::etcd_peer_protocol
  $peer_listen_url = "${peer_protocol}://${::simp_kubernetes::etcd_peer_listen_address}:${peer_port}"

  $etcd_listen_peer_urls = $peers.map |$peer| {
    "${peer_protocol}://${peer}:${peer_port}"
  }
  $etcd_cluster = zip($peers,$etcd_listen_peer_urls).map |$url| {
    if $url[0] == $facts['fqdn'] {
      "${url[0]}=${peer_protocol}://0.0.0.0:${peer_port}"
    }
    else {
      "${url[0]}=${url[1]}"
    }
  }


  $base_params = {
    'etcd_name'             => $facts['fqdn'],
    'listen_client_urls'    => $client_listen_url,
    'advertise_client_urls' => $::simp_kubernetes::etcd_advertise_client_urls.join(','),
    'listen_peer_urls'      => $peer_listen_url,
  }

  if $::simp_kubernetes::etcd_static_cluster {
    $cluster_params = {
      'initial_advertise_peer_urls' => "${peer_protocol}://0.0.0.0:${peer_port}",
      'initial_cluster'             => $etcd_cluster,
    }
  }
  else {
    $cluster_params = {}
  }

  if $peer_protocol == 'https' and $::simp_kubernetes::use_simp_certs {
    $peer_pki_params = {
      'peer_client_cert_auth' => true,
      'peer_cert_file'        => $::simp_kubernetes::etcd_app_pki_key,
      'peer_key_file'         => $::simp_kubernetes::etcd_app_pki_cert,
      'peer_trusted_ca_file'  => $::simp_kubernetes::etcd_app_pki_ca,
    }
    Pki::Copy['simp_kubernetes-etcd'] -> Class['etcd']
  }
  else {
    $peer_pki_params = {}
  }

  if $client_protocol == 'https' and $::simp_kubernetes::use_simp_certs {
    $client_pki_params = {
      'client_cert_auth' => true,
      'cert_file'        => $::simp_kubernetes::etcd_app_pki_key,
      'key_file'         => $::simp_kubernetes::etcd_app_pki_cert,
      'trusted_ca_file'  => $::simp_kubernetes::etcd_app_pki_ca,
    }
    Pki::Copy['simp_kubernetes-etcd'] -> Class['etcd']
  }
  else {
    $client_pki_params = {}
  }


  class { '::etcd':
    # the last hash has highest priority
    * => $cluster_params + $client_pki_params + $peer_pki_params + $base_params + $::simp_kubernetes::etcd_options
  }


  if $::simp_kubernetes::inject_network_config {
    if $::simp_kubernetes::etcd_client_protocol == 'https' {
      $etcdctl_pki = {
        'key_file'  => $::simp_kubernetes::etcd_app_pki_key,
        'cert_file' => $::simp_kubernetes::etcd_app_pki_cert,
        'ca_file'   => $::simp_kubernetes::etcd_app_pki_ca,
        'require'   => Pki::Copy['simp_kubernetes-etcd']
      }
    }
    else {
      $etcdctl_pki = {}
    }
    # TODO move to libkv
    etcd_key { "${simp_kubernetes::etcd_prefix}/config":
      value => $::simp_kubernetes::flannel_network_config.to_json,
      peers => $::simp_kubernetes::etcd_advertise_client_urls.join(','),
      *     => $etcdctl_pki
    }
  }

}
