# Populate the apiserver kubernetes configuration
#
class simp_kubernetes::master::apiserver {
  assert_private()

  $apiserver_template = epp('simp_kubernetes/etc/kubernetes/apiserver.epp', {
      'api_address'       => $::simp_kubernetes::api_listen_address,
      'api_port'          => $::simp_kubernetes::kube_api_port,
      'etcd_servers'      => $::simp_kubernetes::etcd_advertise_client_urls,
      'service_addresses' => $::simp_kubernetes::service_addresses,
      'api_args'          => $::simp_kubernetes::api_args + $::simp_kubernetes::master_api_args,
    }
  )

  file { '/etc/kubernetes/apiserver':
    ensure  => 'file',
    content => $apiserver_template,
  }

  service { 'kube-apiserver':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/kubernetes/apiserver'],
      File['/etc/kubernetes/config']
    ],
  }

}
