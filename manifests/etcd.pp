# Manage etcd
#
class simp_kubernetes::etcd {

  # $class_pki_args = {
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

  class { '::etcd':
    etcd_name                   => $facts['fqdn'],
    listen_client_urls          => $client_listen_url,
    advertise_client_urls       => $::simp_kubernetes::etcd_advertise_client_urls.join(','),
    listen_peer_urls            => $peer_listen_url,

    initial_advertise_peer_urls => $::simp_kubernetes::etcd_listen_peer_urls.join(','),
    initial_cluster             => $::simp_kubernetes::etcd_cluster,
    # *                           => $class_pki_args + $::simp_kubernetes::etcd_options
  }

  if $::simp_kubernetes::bootstrap_etcd {
    # $etcdctl_pki = {}
    inspect($::simp_kubernetes::flannel_network_config.to_json)
    etcd_key { "${simp_kubernetes::etcd_prefix}/config":
      value => $::simp_kubernetes::flannel_network_config.to_json,
      peers => 'http://127.0.0.1:2379',
      # *     => $etcdctl_pki
    }
  }

}
