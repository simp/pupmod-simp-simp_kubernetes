# Configure flannel using etcd params from the parent class
#
class simp_kubernetes::flannel {
  assert_private()

  package { 'flannel':
    ensure => $::simp_kubernetes::flannel_package_ensure,
  }

  if $::simp_kubernetes::etcd_client_protocol == 'https' and $::simp_kubernetes::use_simp_certs {
    $pki_params = {
      'etcd-certfile' => $::simp_kubernetes::etcd_app_pki_key,
      'etcd-keyfile'  => $::simp_kubernetes::etcd_app_pki_cert,
      'etcd-cafile'   => $::simp_kubernetes::etcd_app_pki_ca,
    }
  }
  else {
    $pki_params = {}
  }

  $flanneld_template = epp('simp_kubernetes/etc/sysconfig/flanneld', {
      'etcd_endpoints' => $::simp_kubernetes::etcd_advertise_client_urls,
      'etcd_prefix'    => $::simp_kubernetes::etcd_prefix,
      'args'           => $pki_params + $::simp_kubernetes::flannel_args,
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

  if $::simp_kubernetes::flannel_manage_firewall {
    $port = $::simp_kubernetes::flannel_network_config['Port']
    iptables::listen::udp { 'simp_kubernetes flannel':
      trusted_nets => $::simp_kubernetes::trusted_nets,
      dports       => [$port],
    }
  }

}
