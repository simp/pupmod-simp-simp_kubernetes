#
class simp_kubernetes::flannel {
  assert_private()

  package { 'flannel':
    ensure => $::simp_kubernetes::flannel_package_ensure,
  }

  $flanneld_template = epp('simp_kubernetes/etc/sysconfig/flanneld', {
      'etcd_endpoints' => $::simp_kubernetes::etcd_advertise_client_urls,
      'etcd_prefix'    => $::simp_kubernetes::etcd_prefix,
      'args'           => $::simp_kubernetes::flannel_args,
    }
  )

  file { '/etc/sysconfig/flanneld':
    ensure  => 'file',
    content => $flanneld_template,
  }

  service { 'flanneld':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/sysconfig/flanneld']
  }

}
