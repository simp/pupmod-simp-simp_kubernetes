# Reference

## Classes
* [`simp_kubernetes`](#simp_kubernetes): Full description of SIMP module 'simp_kubernetes' here.
## Defined types
* [`simp_kubernetes::kubeconfig`](#simp_kuberneteskubeconfig): Lay down kubeconfig files. Useful for configuring control plane components Not recommended for personal kubeconfig files
## Classes

### simp_kubernetes

Full description of SIMP module 'simp_kubernetes' here.


#### Parameters

The following parameters are available in the `simp_kubernetes` class.

##### `is_master`

Data type: `Boolean`

Enable if the node is to the kubernetes master

##### `master_ports`

Data type: `Hash`

Ports to be opened if `$is_master` is true

##### `worker_ports`

Data type: `Hash`

Ports to be opened if `$is_master` is false

##### `use_simp_docker`

Data type: `Boolean`

Use simp/simp_docker to manage docker

##### `manage_repo`

Data type: `Boolean`

Manage the upstream kubernetes repo using the internet

##### `repo_enabled`

Data type: `Boolean`

Enable the internet kubernetes repo

##### `manage_packages`

Data type: `Boolean`

Use this module to install package dependencies

##### `packages`

Data type: `Array[String]`

Kubernetes related packages to install

##### `package_ensure`

Data type: `String`

Ensure parameter to be forwarded to the packages

##### `manage_kubelet_sevice`

Data type: `Boolean`

Manage the kubelet service. This is turned off by
default for bootstrapping reasons

##### `service_ensure`

Data type: `Optional[String]`

Ensure parameter to be forwarded to the service

##### `kubelet_overrides`

Data type: `String`

Contents of a systemd overrides file, for changing
runtime configuration of the kubelet


## Defined types

### simp_kubernetes::kubeconfig

Lay down kubeconfig files. Useful for configuring control plane components
Not recommended for personal kubeconfig files


#### Parameters

The following parameters are available in the `simp_kubernetes::kubeconfig` defined type.

##### `current_context`

Data type: `String`

`kubectl config use-context <context>`

##### `clusters`

Data type: `Array[Simp_kubernetes::Kubeconfig::Cluster]`

`kubectl config set-cluster`

##### `contexts`

Data type: `Array[Simp_kubernetes::Kubeconfig::Context]`

`kubectl config set-context`

##### `users`

Data type: `Array[Simp_kubernetes::Kubeconfig::User]`

`kubectl config set-credentials`

##### `content`

Data type: `Optional[Variant[Hash,String]]`

The raw content to stick in this kubeconfig. Can be a string or a hash.

Default value: `undef`

##### `api_version`

Data type: `String`



Default value: 'v1'

##### `preferences`

Data type: `Hash`



Default value: {}


