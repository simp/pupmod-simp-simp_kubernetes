#
class simp_kubernetes::node {

  include '::simp_kubernetes::node::proxy'
  include '::simp_kubernetes::node::kubelet'

}
