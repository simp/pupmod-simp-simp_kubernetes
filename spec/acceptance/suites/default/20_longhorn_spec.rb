require 'spec_helper_acceptance'

test_name 'install longhorn'

describe 'install longhorn' do

  masters    = hosts_with_role(hosts,'master')
  controller = masters.first

  shared_examples_for 'wait for pods to finish deploying' do
    it 'should not have pods in ContainerCreating or Pending status' do
      sleep 20
      retry_on(controller,
        'kubectl get pods --all-namespaces --field-selector=status.phase!=ContainerCreating |& grep "No resources found"',
        desired_exit_codes: 1,
        retry_interval: 15,
        max_retries: 60,
      )
    end
  end

  context 'use kubernetes' do
    it 'should install deps for longhorn' do
      hosts.each do |host|
        on(host, 'yum install -y iscsi-initiator-utils')
      end
    end
    it 'should install longhorn' do
      scp_to(controller, 'spec/acceptance/suites/default/manifests/longhorn', '/root/longhorn')
      on(controller, 'kubectl apply -f /root/longhorn')
    end
  end

  context 'should be healthy' do
    it_behaves_like 'wait for pods to finish deploying'
  end
end
