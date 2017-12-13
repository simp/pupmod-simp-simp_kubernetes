# Populate the proxy kubernetes configuration
#
class simp_kubernetes::node::proxy {
  assert_private()


  if $::simp_kubernetes::kube_api_protocol == 'https' {
    # https://github.com/kubernetes/kubernetes/issues/27442#issuecomment-241894715
    simp_kubernetes::kubeconfig { '/etc/kubernetes/proxy.kubeconfig':
      current_context => 'proxy-ctx',
      clusters        => [
        {
          'name'    => 'kubernetes',
          'cluster' => {
            'certificate-authority' => $::simp_kubernetes::app_pki_ca,
            'server'                => $::simp_kubernetes::kube_master_urls[0]
          }
        }
      ],
      contexts        => [
        {
          'name'    => 'proxy-ctx',
          'context' => {
            'cluster' => 'kubernetes',
            'user'    => 'proxy'
          }
        }
      ],
      users           => [
        {
          'name' => 'proxy',
          'user' => {
            'client-certificate' => $::simp_kubernetes::app_pki_cert,
            'client-key'         => $::simp_kubernetes::app_pki_key,
          }
        }
      ],
    }
  }
  else {
    simp_kubernetes::kubeconfig { '/etc/kubernetes/proxy.kubeconfig':
      current_context => 'proxy-ctx',
      clusters        => [
        {
          'name'    => 'kubernetes',
          'cluster' => {
            'server' => $::simp_kubernetes::kube_master_urls[0]
          }
        }
      ],
      contexts        => [
        {
          'name'    => 'proxy-ctx',
          'context' => {
            'cluster' => 'kubernetes',
            'user'    => 'proxy'
          }
        }
      ],
      users           => [],
    }
  }


  # proxy uses a kubeconfig just like anything else that talks to the apiserver
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
