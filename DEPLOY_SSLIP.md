# Deploy APK to sslip.io-hosted server

This project includes a GitHub Actions workflow that builds the Android release APK and can deploy it to a server so it is reachable via an sslip.io hostname.

How sslip.io works
- `X.Y.Z.W.sslip.io` resolves to `X.Y.Z.W` automatically. If your server's public IP is `203.0.113.45`, the hostname `203.0.113.45.sslip.io` points to that IP.

Requirements
- A server with a public IP and SSH access.
- A web server serving files from a directory (for example `/var/www/html/`).
- GitHub repository secrets set: `SSH_HOST`, `SSH_USER`, `SSH_PRIVATE_KEY`. Optional: `SSH_PORT`, `SSH_TARGET_PATH`.

Set up deploy key (one-time)
1. On your local machine, generate a key pair and copy the public key to the server's `~/.ssh/authorized_keys`:

PowerShell example:
```powershell
New-Item -ItemType Directory -Force -Path $env:USERPROFILE\.ssh
ssh-keygen -t ed25519 -C "cafe-pos-deploy" -f $env:USERPROFILE\.ssh\cafe_pos_deploy -N ""
Get-Content $env:USERPROFILE\.ssh\cafe_pos_deploy.pub | ssh user@SERVER_IP "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
```

2. Test the key locally:
```powershell
ssh -i $env:USERPROFILE\.ssh\cafe_pos_deploy user@SERVER_IP
```

Add GitHub secrets
1. Go to your repo → Settings → Secrets and variables → Actions → New repository secret.
2. Add `SSH_PRIVATE_KEY` and paste the full private key contents (the file `cafe_pos_deploy`).
3. Add `SSH_HOST` (public IP), `SSH_USER` (username), and optionally `SSH_PORT` and `SSH_TARGET_PATH` (defaults to `/var/www/html/`).

Triggering deploy
- Push to `main` or run the workflow manually via Actions → Run workflow. The CI builds `app-release.apk` and uploads it to the target path.

Download URL
- If `SSH_HOST` is `203.0.113.45` and you used default `SSH_TARGET_PATH`, the APK will be available at:

  https://203.0.113.45.sslip.io/app-release.apk

Security notes
- Use a restricted, non-root user on the server for uploads.
- Do not make the private key public. Use GitHub Secrets for storage.
- Consider HTTPS termination via Caddy or nginx for production.
