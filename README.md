# yamisskey-provision

This guide will walk you through the process of setting up Misskey etc using the provided Make and Ansible.

## Steps

### login (via Tailscale SSH)

Access to the server is managed via Tailscale SSH.
Make sure you have Tailscale installed and log in:

```consol
tailscale login
sudo tailscale up --advertise-tags=tag:ssh-access --ssh --accept-dns=false --reset --accept-risk=lose-ssh
```

Now you can SSH into the server without managing keys:

```consol
tailscale ssh balthasar
```

💡 If you prefer to keep a fallback SSH access method (in case Tailscale is unavailable), you may additionally configure an SSH public key and update /etc/ssh/sshd_config manually. This step is optional.

### clone

```consol
git clone https://github.com/yamisskey-dev/yamisskey-provision.git
cd yamisskey-provision
```

### install

Use the Makefile to install the necessary packages and clone the misskey repository:

```consol
make install
make clone
```

### provision

Return to the yamisskey-provision directory and use the Makefile to provision the server:

```consol
cd ~/yamisskey-provision
make install
make inventory
make clone
make provision
```

## help

```consol
make help
```