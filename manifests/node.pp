# Container for classes only relevant to Kubernetes nodes
#
class simp_kubernetes::node {

  contain '::simp_kubernetes::node::proxy'
  contain '::simp_kubernetes::node::kubelet'

}
