require 'spec_helper'

describe 'simp_kubernetes::kubeconfig' do

  let(:title) { '/etc/sysconfig/controller.kubeconfig' }
  let(:params) {{
    current_context: 'http-localhost',
    clusters: [
      {
        'name' => 'default-cluster',
        'cluster' => {
          'certificate-authority' => '/etc/pki/simp_apps/simp_kubernetes/x509/cacerts/cacerts.pem',
          'server' => 'https://master01:6443'
        },
      },
      {
        'name' => 'http-localhost',
        'cluster' => {
          'server' => 'http://localhost:8080'
        },
      }
    ],
    contexts: [
      {
        'name' => 'default-system',
        'context' => {
          'cluster' => 'default-cluster',
          'user' => 'default-admin',
        },
      },
      {
        'name' => 'http-localhost',
        'context' => {
          'cluster' => 'http-localhost'
        },
      }
    ],
    users: [
      {
        'name' => 'default-admin',
        'user' => {
          'client-certificate' => '/etc/pki/simp_apps/simp_kubernetes/x509/private/master01.pem',
          'client-key' => '/etc/pki/simp_apps/simp_kubernetes/x509/private/master01.pem',
        }
      }
    ]
  }}

  context 'with minimal params' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/etc/sysconfig/controller.kubeconfig') \
      .with_content(File.read('spec/defines/controller.kubeconfig.txt')) }
  end

  context 'with a name that is not a path' do
    let(:title) { '.kube/config' }
    it { is_expected.to compile.and_raise_error(/\$name should be an absolute path/) }
  end

  context 'with a context that is not in contexts' do
    let(:params) { super().merge(current_context: 'empty') }
    it { is_expected.to compile.and_raise_error(/\$current_context should be listed in \$contexts/) }
  end

end
