# Populate the controller-manager kubernetes configuration
#
class simp_kubernetes::master::controller_manager {
  assert_private()

  $controller_manager_template = epp('simp_kubernetes/etc/kubernetes/controller-manager.epp', {
      'args' => $::simp_kubernetes::controller_args,
    }
  )

  file { '/etc/kubernetes/controller-manager':
    ensure  => 'file',
    content => $controller_manager_template,
  }

  service { 'kube-controller-manager':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/kubernetes/controller-manager'],
      File['/etc/kubernetes/config']
    ],
  }

}
