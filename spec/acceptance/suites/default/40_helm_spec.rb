require 'spec_helper_acceptance'

test_name 'install helm'

describe 'install helm' do

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
    it 'should install helm' do
      on(controller, 'echo \'export PATH="${PATH}:/usr/local/bin"\' >> .bashrc')
      on(controller, 'curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh')
      on(controller, 'chmod 700 get_helm.sh')
      on(controller, './get_helm.sh')
      on(controller, 'helm init')
    end
  end

  context 'should be healthy' do
    it_behaves_like 'wait for pods to finish deploying'
  end
end
