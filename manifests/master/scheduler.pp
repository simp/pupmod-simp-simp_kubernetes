# Populate the scheduler kubernetes configuration
#
class simp_kubernetes::master::scheduler {
  assert_private()


  if $::simp_kubernetes::kube_api_protocol == 'https' {
    # https://github.com/kubernetes/kubernetes/issues/27442#issuecomment-241894715
    simp_kubernetes::kubeconfig { '/etc/kubernetes/scheduler.kubeconfig':
      current_context => 'scheduler-ctx',
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
          'name'    => 'scheduler-ctx',
          'context' => {
            'cluster' => 'kubernetes',
            'user'    => 'scheduler'
          }
        }
      ],
      users           => [
        {
          'name' => 'scheduler',
          'user' => {
            'client-certificate' => $::simp_kubernetes::app_pki_cert,
            'client-key'         => $::simp_kubernetes::app_pki_key,
          }
        }
      ],
    }
  }
  else {
    simp_kubernetes::kubeconfig { '/etc/kubernetes/scheduler.kubeconfig':
      current_context => 'scheduler-ctx',
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
          'name'    => 'scheduler-ctx',
          'context' => {
            'cluster' => 'kubernetes',
            'user'    => 'scheduler'
          }
        }
      ],
      users           => []
    }
  }

  # scheduler uses a kubeconfig just like anything else that talks to the apiserver
  $scheduler_template = epp('simp_kubernetes/etc/kubernetes/scheduler.epp', {
      'args' => $::simp_kubernetes::scheduler_args,
    }
  )

  file { '/etc/kubernetes/scheduler':
    ensure  => 'file',
    content => $scheduler_template,
  }

  service { 'kube-scheduler':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/kubernetes/scheduler'],
      File['/etc/kubernetes/config']
    ],
  }

}
