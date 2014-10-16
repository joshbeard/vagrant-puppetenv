# Puppet Environment Vagrant Demo

## Overview

### Workflow Testing

This is a Vagrant environment for demonstrating Puppet with a Git-based
workflow.  It makes use of r10k for managing dynamic environments and Gitlab
as a Git server/interface. Example roles, profiles, hiera data, and a
component module are included.

### Multi-master testing

Additionally, it can be used to demonstrate multi-master environments with a
load balancer.  An HAProxy instance and second "compile only" Puppet Master is
included.  This functionality is optional.

NOTE: Internet access is required for this environment

There are two example repositories in the `code/` directory:

**`control`**

This is the Puppet environments' "control" repository.  It includes a
Puppetfile for r10k, roles, profiles, hieradata, and some environment
configuration.

This is also the control repository that is used to provision and manage the
demo systems, such as the PE master itself and Gitlab.

**`motd`**

This is an example component module for demonstration.

## How to use it

There's seven systems in this environment:

| Name          | Description                         | Address        | App URL                                                  |
| ------------- | ----------------------------------- | -------------- | -------------------------------------------------------- |
| master        | The PE Master (full stack)          | 192.168.137.10 | [https://192.168.137.10](https://192.168.137.10)         |
| gitlab        | The Gitlab server                   | 192.168.137.11 | [http://192.168.137.11](http://192.168.137.11)           |
| venus         | Sample Tomcat app server            | 192.168.137.12 | [http://192.168.137.12:8080](http://192.168.137.12:8080) |
| pluto         | Sample PHP webapp server            | 192.168.137.13 | [http://192.168.137.13](http://192.168.137.13)           |
| agent1        | Example agent (unclassified)        | 192.168.137.14 |                                                          |
| haproxy       | HAProxy server for load balancing masters | 192.168.137.20 | [http://puppet:puppet@192.168.137.20:9090](http://puppet:puppet@192.168.137.20:9090)
| puppetmaster1 | Additional Puppet Master (compiler) | 192.168.137.21 | |

The default credentials for the PE Master Console are:

Username: `admin@example.com`

Password: `password`

### Summary of procedure

1. Bring up instances
2. Configure GitLab (create organization, add SSH keys, create repositories)
3. Push local control repository to GitLab
4. Experiment

**Bring up all the nodes in the Vagrant environment:**

```shell
vagrant up
```

(optionally, just bring up the master, gitlab server, and whatever agent you
want)

This will take some time to provision.

Ensure that the PE master is up and provisioned before attempting to start
another system.

The main things for demonstration:

* Puppet Environments (control repository)
* Roles and Profiles
* Hiera
* Git/VCS workflow
* [hiera-eyaml](https://github.com/TomPoulton/hiera-eyaml)
* [r10k](https://github.com/adrienthebo/r10k)
* [trlinkin/noop](https://github.com/trlinkin/trlinkin-noop)

### Provisioning Summary

The Vagrant provisioning will install Puppet Enterprise with the appropriate
configuration for each system.  The Puppet Master will be configured and manged
using Puppet - you can look at the `role::puppet::master` to see what's going
on.  Basically, Puppet is configured for environments, r10k is installed and
configured, and Hiera is installed and configured.  During provisioning, the
provided control repository is cloned to the PE master and a local `puppet apply`
is done for the role.

For Gitlab, the Gitlab software is installed via the Omnibus RPM.  This is
weird, of course, using Puppet to install an Omnibus RPM. The Gitlab server
is just another Puppet agent and is classified with `role::gitlab`

Classification for the master and Gitlab server are done via the
environment-specific `site.pp`

### 1. Create code repositories in Gitlab

**NOTE:** I'd like to automate creating the repositories on the Gitlab server.
Feel free to contribute ;)

Login to the Gitlab web interface at: [http://192.168.137.11](http://192.168.137.11) (default)

**The default credentials are:**

|          |            |
| -------- | ---------- |
| Username | `root`     |
| Password | `5iveL!fe` |


#### 1.1 Create a new "organization" in Gitlab called `puppet`

TODO: Automate this

#### 1.2 Create a new repository in Gitlab with the following settings:

TODO: Automate this

Project Name: `control`

Namespace: `puppet`

Visibility Level: `Public`

#### 1.3 Create a new repository in Gitlab with the following settings:

TODO: Automate this

Project Name: `motd`

Namespace: `puppet`

Visibility Level: `Public`

#### 1.4 Add an SSH key to Gitlab

TODO: Automate this

Go to the "profile settings" in Gitlab and click on "SSH Keys"

Add a public SSH key from your local machine

#### 1.5 Push the example repos

TODO: Automate this

The example repos in `code/` need to be initialized as Git repositories.

```shell
cd control
git init
git checkout -b production
git add .
git commit -m "Initial commit"
git remote add origin git@192.168.137.11:unix/control.git
git push origin production
git push origin production:master  # See note below about this
```

```shell
cd motd
git init
git add .
git commit -m "Initial commit"
git remote add origin git@192.168.137.11:unix/motd.git
git push origin master
```

You should then be able to see the pushed code in the Gitlab repositories.

#### 1.6 Add the PE master's root SSH public key to Gitlab

TODO: Automate this

The root user on the PE master will need to its SSH public key added to the
Gitlab server in order for r10k to synchronize.

The SSH keypair has already been generated during provisioning.

Copy the contents of `/root/.ssh/id_rsa.pub` and paste it into the SSH keys
under Gitlab (you can add it to the Administrator (root) user's key list).


### 2. Do your stuff

This is a free-flow demo to show a few components: r10k, Hiera, roles & profiles,
Puppet environments, and code promotion.

At this point, utilize the present systems to show these components.  Leverage
the example code in the `code/` directory to demonstrate modifying a module and
doing code promotion/review.

r10k will need to be manually run when code changes.  You can do that like:

```shell
r10k deploy environment -pv
```

TODO: Implement a webook for Gitlab to execute r10k

Classification can be done via the console, Hiera, or site.pp.

#### Examples Provided

There's a couple of example roles provided that can be used to classify nodes
with:

**`role::venus`**

This is an example Tomcat application.  If a node is classified with this, a
Tomcat instance should be created and listening on port `8080`.

**`role::plutoweb`**

This is an example PHP web application, powered by Apache.  If a node is
classified with this, an Apache instance with the application should be
available on port `80`

**Component Module: `motd`**

This is a very simple example of a component module, intended to be used to
demonstrate a development workflow (with Git).

## Multi Master Testing

If you would like to use this environment to test multi-master functionality,
follow this procedure.

This assumes the "main" full-stack master is already up and running.

### 1. Bring up the HAProxy server

```shell
vagrant up haproxy
```

This is a standard PE agent installation.

The `haproxy` server will be classified automatically and configured with a
`puppet00` listening pool for masters.  An HAProxy web stats page is available
at [http://puppet:puppet@192.168.137.20:9090](http://puppet:puppet@192.168.137.20:9090)

### 2. Bring up the additional master

```shell
vagrant up puppetmaster1
```

The additional master will apply and be classified with `role::puppet::master`
during provisioning.  It will also run `r10k` and stub out the Puppet directory
environments.

There's a couple of tasks that will need to be completed after installation.

#### 1. Remove the stale SSL data

```shell
rm -rf /etc/puppetlabs/puppet/ssl
```

#### 2. Sign the new certificate on the CA server (`master`)

```shell
puppet cert sign --allow-dns-alt-names puppetmaster1.vagrant.vm
```

#### 3. Restart `pe-httpd` on the additional master

```shell
service pe-httpd restart
```

#### 4. Add authorization for PuppetDB and Console

On the primary master, add the appropriate authorizations for the new master
to access PuppetDB and the Console.

__4.1__ Edit `/etc/puppetlabs/puppetdb/certificate-whitelist` and add the new master's
certificate name to it (`puppetmaster1.vagrant.vm`).

__4.2__ Restart the `pe-puppetdb` service.

__4.3__ Edit `/etc/puppetlabs/console-auth/certificate_authorization.yml` and add the
new master's certificate name to it with `read-write` access.

```yaml
puppetmaster1.vagrant.vm:
  role: read-write
```

__4.4__ Restart the `pe-httpd` service.

#### 5. Run the agent

Run the Puppet agent on the new master __against the primary master__ to
synchronize Mcollective certificates.

```shell
puppet agent -t --server master.vagrant.vm
```

#### 6. Add the new master to the list of stomp servers

In `site.pp`, ensure the following variables are set:

```puppet
$fact_stomp_server = 'master.vagrant.vm,puppetmaster1.vagrant.vm'
$activemq_brokers  = 'master.vagrant.vm,puppetmaster1.vagrant.vm'
```

#### 7. Edit `/etc/hosts`

To point agents to the load balancer, you'll need to edit `/etc/hosts` and
point the entry for `puppet.vagrant.vm` to the load balancer IP address.

#### 8. Run the agent on the HAProxy server

This might have happened in the background already.  For good measure, you
should run the Puppet agent on the HAProxy server so that it can collect the
exported resources that add the masters to the load balancer pool.

```shell
puppet agent -t
```

## Contributing

Contributions would be very welcome.

Particuarily, the items with a "TODO" marked above.  This includes further
automating the Gitlab server (create the group, repositories).

A Puppet module for deploying/managing Gitlab that works well on CentOS
(including el6) would be great.  Something outside installing the RPM.

Further examples of roles and profiles.

Maybe throw a Jenkins box in the mix with some sample tests and code
deployment/promotion pipeline.

## Known issues

The control repo has a "master" branch, but it shouldn't be used.  The reason
it's present is because GitLab has HEAD pointint to "master" when a new repo
is created, and trying to push a masterless-repo there causes clones to fail
until HEAD gets changed (requiring you to change the default branch via the
GitLab interface).

## Other

This makes use of Greg Sarjeant's [data-driven-vagrantfile](https://github.com/gsarjeant/data-driven-vagrantfile)

No Vagrant plugins are required.
