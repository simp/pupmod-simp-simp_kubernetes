# Manage etcd
#
class simp_kubernetes::etcd {

  # $pki_params = {
  #   'client_cert_auth'      => true,
  #   'peer_client_cert_auth' => true,
  #   'cert_file'             => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
  #   'key_file'              => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
  #   'trusted_ca_file'       => '/etc/pki/simp-testing/pki/cacerts/cacerts.pem',
  #   'peer_cert_file'        => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
  #   'peer_key_file'         => "/etc/pki/simp-testing/pki/private/${facts['fqdn']}.pem",
  #   'peer_trusted_ca_file'  => '/etc/pki/simp-testing/pki/cacerts/cacerts.pem',
  # }

  $client_listen_url = "http://${::simp_kubernetes::etcd_client_listen_address}:${::simp_kubernetes::etcd_client_port}"
  $peer_listen_url   = "http://${::simp_kubernetes::etcd_peer_listen_address}:${::simp_kubernetes::etcd_peer_port}"

  $base_params = {
    etcd_name             => $facts['fqdn'],
    listen_client_urls    => $client_listen_url,
    advertise_client_urls => $::simp_kubernetes::etcd_advertise_client_urls.join(','),
    listen_peer_urls      => $peer_listen_url,
  }

  if $::simp_kubernetes::etcd_static_cluster {
    $cluster_params = {
      initial_advertise_peer_urls => $::simp_kubernetes::etcd_listen_peer_urls.join(','),
      initial_cluster             => $::simp_kubernetes::etcd_cluster,
    }
  }
  else {
    $cluster_params = {}
  }

  class { '::etcd':
    # the last hash has highest priority
    *=> $cluster_params + $base_params + $::simp_kubernetes::etcd_options
  }


  if $::simp_kubernetes::inject_network_config {
    # $etcdctl_pki = {
    #   'cert_file' => '',
    #   'key_file'  => '',
    #   'ca_file'   => '',
    # }
    etcd_key { "${simp_kubernetes::etcd_prefix}/config":
      value => $::simp_kubernetes::flannel_network_config.to_json,
      peers => 'http://127.0.0.1:2379',
      # *     => $etcdctl_pki
    }
  }

}
