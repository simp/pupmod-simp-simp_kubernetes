# Populate the scheduler kubernetes configuration
#
class simp_kubernetes::master::scheduler {
  assert_private()

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
