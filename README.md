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

### edit

Navigate to the `misskey` directory inside the misskey directory and copy the configuration file templates:

```consol
cd /var/www/misskey
cd .config
cp docker_example.yml default.yml
cp docker_example.env docker.env
```

Edit the `docker-compose.yml` and `default.yml` and `docker.env` files.

### configure

Prepare the Cloudflare API credentials file. Create a directory for Cloudflare configuration if it does not exist:

- Access https://dash.cloudflare.com/profile/api-tokens
- Select View for Global API Key
- Enter password to remove hCaptcha and select View

```consol
sudo mkdir /etc/cloudflare
sudo vi /etc/cloudflare/cloudflare.ini
```

Include the following content, replacing placeholders with your actual data:

```config
dns_cloudflare_email = your-email@example.com
dns_cloudflare_api_key = your-cloudflare-global-api-key
```

```consol
sudo chmod 600 /etc/cloudflare/cloudflare.ini
```

### connect

Need to manually log in to cloudflared and warp

#### cloudflared

```consol
cloudflared tunnel login
```

##### locally-managed tunnel

```consol
cloudflared tunnel create yamisskey
cloudflared tunnel list
cloudflared tunnel route dns yamisskey yami.ski
sudo mkdir -p /etc/cloudflared
sudo vim /etc/cloudflared/config.yml
```

```consol
sudo cloudflared tunnel --config /etc/cloudflared/config.yml run yamisskey
```

```consol
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
sudo systemctl restart cloudflared
```

##### cloudflare zero trust(optional)

create cloudflare tunnel named yamisskey by Zero Trust in https://one.dash.cloudflare.com/

```consol
sudo cloudflared service install your_connector_token_value
```

#### warp-cli

##### warp+

subscribe warp licence key in [mobile app](https://play.google.com/store/apps/details?id=com.cloudflare.onedotonedotonedotone&hl=en_US&pli=1) on mobile device

```consol
sudo systemctl enable warp-svc.service
sudo systemctl start warp-svc.service
warp-cli registration new
warp-cli registration license <your-warp-licence-key-subscribed-on-mobile-device>
warp-cli registration show
warp-cli connect
curl https://www.cloudflare.com/cdn-cgi/trace/
warp-cli mode warp+doh
warp-cli settings
```
verify that warp=on.

```consol
sudo systemctl restart warp-svc.service
```

Exclude traffic to Cloudflare's edge servers from routing through WARP to prevent interference with direct cloudflared connections.

```consol
warp-cli tunnel host add region1.v2.argotunnel.com
warp-cli tunnel host add region2.v2.argotunnel.com
warp-cli tunnel host list
```

### provision

Return to the yamisskey-provision directory and use the Makefile to provision the server:

```consol
cd ~/yamisskey-provision
make inventory
make provision
```

## help

```consol
make help
```

```log
Available targets:
  all           - Install, clone, setup, provision, and backup
  install       - Update and install necessary packages
  inventory     - Create Ansible inventory (MODE=migration for migration, default for standard)
  clone         - Clone the repositories if they don't exist
  provision     - Provision the server using Ansible
  backup        - Run the backup playbook

Migration commands:
  migrate       - Migrate MinIO data with encryption and progress monitoring
  test          - Test migration system functionality with enhanced checks
  transfer      - Transfer complete system using export/import playbooks

Migration examples:
  make migrate SOURCE=balthasar TARGET=raspberrypi  # Full progress monitoring
  make inventory MODE=migration SOURCE=balthasar TARGET=raspberrypi  # Migration inventory
  make inventory        # Standard inventory for regular playbooks
  make test             # Test system with progress feature validation
```
