# Populate the proxy kubernetes configuration
#
class simp_kubernetes::node::kubelet {
  assert_private()

  $kubelet_template = epp('simp_kubernetes/etc/kubernetes/kubelet.epp', {
      'address'      => $::simp_kubernetes::kubelet_listen_address,
      'hostname'     => $::simp_kubernetes::kubelet_hostname,
      'kube_masters' => $::simp_kubernetes::kube_master_urls,
      'args'         => $::simp_kubernetes::kubelet_args,
    }
  )

  file { '/etc/kubernetes/kubelet':
    ensure  => 'file',
    content => $kubelet_template,
  }

  service { 'kubelet':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/kubernetes/kubelet'],
      File['/etc/kubernetes/config']
    ],
  }

}
