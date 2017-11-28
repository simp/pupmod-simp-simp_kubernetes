# Populate the proxy kubernetes configuration
#
class simp_kubernetes::node::proxy {
  assert_private()

  $proxy_template = epp('simp_kubernetes/etc/kubernetes/proxy.epp', {
      'args' => $::simp_kubernetes::proxy_args,
    }
  )

  file { '/etc/kubernetes/proxy':
    ensure  => 'file',
    content => $proxy_template,
  }

  service { 'kube-proxy':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/kubernetes/proxy'],
      File['/etc/kubernetes/config']
    ],
  }

}
