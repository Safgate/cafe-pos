<#
setup-deploy.ps1

Generates an SSH deploy key, installs the public key on a remote server,
and (optionally) uploads `SSH_*` secrets to a GitHub repo using the `gh` CLI.

Usage examples (run from repo root in PowerShell):
.\scripts\setup-deploy.ps1 -ServerIP 203.0.113.45 -ServerUser deploy -GitHubRepo myuser/myrepo

Prereqs:
- PowerShell with `ssh`, `scp`, and `ssh-keygen` available (OpenSSH client).
- Optional: `gh` (GitHub CLI) authenticated if you want automatic secrets upload.

The script creates a key at `$env:USERPROFILE\.ssh\cafe_pos_deploy` (no passphrase).

#>

param(
    [string]$ServerIP,
    [string]$ServerUser,
    [string]$GitHubRepo,
    [string]$TargetPath = "/var/www/html/",
    [switch]$Force
)

function FailIfMissing($cmd) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "Required command '$cmd' not found. Install it and rerun."
        exit 1
    }
}

FailIfMissing ssh
FailIfMissing ssh-keygen
FailIfMissing scp

$sshDir = Join-Path $env:USERPROFILE '.ssh'
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

$keyPath = Join-Path $sshDir 'cafe_pos_deploy'
if ((Test-Path $keyPath) -and (-not $Force)) {
    Write-Host "Key already exists at $keyPath. Use -Force to regenerate."
} else {
    if (Test-Path $keyPath) { Remove-Item $keyPath -Force -ErrorAction SilentlyContinue; Remove-Item ($keyPath + '.pub') -Force -ErrorAction SilentlyContinue }
    Write-Host "Generating ed25519 key at $keyPath (no passphrase)..."
    ssh-keygen -t ed25519 -C "cafe-pos-deploy" -f $keyPath -N "" | Out-Null
}

$pubPath = "$keyPath.pub"
if (-not (Test-Path $pubPath)) { Write-Error "Public key not found at $pubPath"; exit 1 }

if ($ServerIP -and $ServerUser) {
    Write-Host "Copying public key to $ServerUser@$ServerIP..."
    try {
        scp $pubPath "$ServerUser@$ServerIP:~/cafe_pos_deploy.pub"
        ssh "$ServerUser@$ServerIP" "mkdir -p ~/.ssh; cat ~/cafe_pos_deploy.pub >> ~/.ssh/authorized_keys; rm ~/cafe_pos_deploy.pub; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
        Write-Host "Public key installed on server. Test with: ssh -i $keyPath $ServerUser@$ServerIP"
    } catch {
        Write-Warning "Failed to copy or install public key to server: $_"
    }
} else {
    Write-Host "ServerIP or ServerUser not provided — skipping remote install. You can manually append $pubPath to the server's ~/.ssh/authorized_keys."
}

if (-not $GitHubRepo) {
    # try to infer repo from git origin
    try {
        $url = git remote get-url origin 2>$null
        if ($url -match '[:/]([^/]+/[^/.]+)(?:.git)?$') { $GitHubRepo = $matches[1] }
    } catch { }
}

if ((Get-Command gh -ErrorAction SilentlyContinue) -and $GitHubRepo) {
    Write-Host "Uploading secrets to GitHub repo $GitHubRepo using gh (you must be authenticated)..."
    try {
        gh secret set SSH_PRIVATE_KEY --repo $GitHubRepo --body (Get-Content -Raw $keyPath)
        if ($ServerIP) { gh secret set SSH_HOST --repo $GitHubRepo --body $ServerIP }
        if ($ServerUser) { gh secret set SSH_USER --repo $GitHubRepo --body $ServerUser }
        gh secret set SSH_TARGET_PATH --repo $GitHubRepo --body $TargetPath
        Write-Host "Secrets uploaded. Verify in your GitHub repository Settings → Secrets and variables → Actions."
    } catch {
        Write-Warning "Failed to set secrets via gh: $_"
        Write-Host "You can set secrets manually in the repo settings or use: gh secret set <NAME> --repo $GitHubRepo --body '<value>'"
    }
} else {
    Write-Host "Skipping GitHub secrets upload (missing gh or repo). To add secrets manually, paste the private key content into the repository secret named 'SSH_PRIVATE_KEY' and add 'SSH_HOST' and 'SSH_USER'."
}

Write-Host "Done. Next steps:"
Write-Host "- Ensure the server serves files from $TargetPath (e.g. install a simple HTTP server or configure nginx/caddy)."
Write-Host "- Trigger the workflow (Actions -> Build Android APK and Deploy) or push to main to build and deploy the APK."
