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
cd ~/misskey
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

### init

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

subscribe warp licence key on mobile device
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

### ai

You need to manually prepare the configuration file `config.json` in ai repository to run. please see [this document](https://github.com/yamisskey-dev/yui?tab=readme-ov-file#docker%E3%81%A7%E5%8B%95%E3%81%8B%E3%81%99).

### provision

Return to the yamisskey-provision directory and use the Makefile to provision the server:

```consol
cd ~/yamisskey-provision
make provision
```

During the provisioning process, the Ansible playbook (playbook.yml) will pause and prompt you to review the configuration files you edited in step 4. Ensure that the configurations are correct, then press ENTER to continue the provisioning process. Once the provisioning is complete, verify that Misskey is running correctly.

### backup

Ensure that you have the necessary environment variables set up to backup. Create a .env file in the misskey-backup directory if it does not exist, and provide the required values:

```config
POSTGRES_HOST=your_postgres_host_in_misskey_config
POSTGRES_USER=your_postgres_user_in_misskey_config
POSTGRES_DB=your_postgres_namein_misskey_config
POSTGRES_PASSWORD=your_postgres_passwordin_misskey_config
R2_PREFIX=your_cloudflare_r2_bucket_prefix
DISCORD_WEBHOOK_URL=your_discord_server_channel_webhook_url
NOTIFICATION=true
```

```consol
make backup
```
