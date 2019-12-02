# Secret Scanning

Implementing secret scanning helps prevents you from committing passwords and other sensitive information to a git repository. This is a huge problem with people committing valuable secrets (e.g. AWS Access Keys, API keys, private keys etc.) to public repos (e.g. Github). Leaking credentials in this manner can lead to the complete compromise of your service, leading to huge bills, data breaches and massive headaches as we try to piece everything back together.

This document guides you through the configuration of the [gitleaks](https://github.com/zricethezav/gitleaks) secret scanner (other scanners are available) and provides some recommended regexes for you to get started.

**Note:** There are some considerations when using a tool like this:

1. You need to configure this for every repo you have on your workstation. It is not possible to enforce the configuration of git hooks automatically on clone (otherwise an attacker could execute arbitratry code on your machine if you cloned a malicios repo), so these need to be configured per project.
2. Due to the nature of regexes, they can only capture what they are configured to capture. If you are working on a project that utilises secrets or 3rd party services that you know are not covered by the recommended regexes then please raise an issue (or a merge request) with as much information on the format of the secret as possible. The Cyber Security team will be more than happy to work with you to get these included in this project.

# Installation
Install or upgrade [gitleaks](https://github.com/zricethezav/gitleaks/releases/latest), ensure you have at least version 3.0.3 e.g.:

```
➜ gitleaks --version
3.0.3
```

## OSX
Gitleaks is available via HomeBrew on OSX.
```bash
# Install
brew install gitleaks

# Upgrade
brew upgrade gitleaks
```
## Windows
The Windows installation requires you to place the [gitleaks executable](https://github.com/zricethezav/gitleaks/releases/latest) into a folder on your path. If you don't know how to do this just use the script below (you can also use this script for upgrading gitleaks):

```powershell
# Make folder to be added to path
mkdir "$HOME\bin"
# Download latest gitleaks to folder
Invoke-WebRequest https://github.com/zricethezav/gitleaks/releases/latest/download/gitleaks-windows-amd64.exe -OutFile "$HOME\bin\gitleaks.exe"
# Set path for current shell
$env:PATH += ";$HOME/bin"

# Permanently set the PATH
# Get User's current path value
$USER_PATH=[Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
# Add folder to User's path
[Environment]::SetEnvironmentVariable("Path", $USER_PATH + ";$HOME\bin", [System.EnvironmentVariableTarget]::User)
```

# Configuration

1. Create `.gitleaks.toml` in your git repo e.g.:

    ```bash
    cd /path/to/repo
    curl https://gitlab.kainos.com/security/secret-scanning/raw/master/.gitleaks.toml -o .gitleaks.toml
    ```

2. Run a full scan of your entire repo

    ```bash
    gitleaks --config=.gitleaks.toml --repo-path=. --verbose --pretty
    ```

3. Configure **pre-commit** hook to execute gitleaks automatically by creating the file `.git/hooks/pre-commit` e.g. 

    ```bash
    curl https://gitlab.kainos.com/security/secret-scanning/raw/master/pre-commit-hook.sh -o .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    ```

4. Test a commit e.g.:

    ```bash
    TMPFILE=$(mktemp ./XXXXXXXX)
    echo 'aws_access_key_id=AKIAZD4787KAIKLPZY77' > $TMPFILE
    git add $TMPFILE
    git commit $TMPFILE

    # Remove TMPFILE
    git rm -f $TMPFILE
    ```

5. Configure your CI pipeline to perform a secrets scan.

# What to do if you find a leak?

So you've found a leak, what do you do?

1. Assuming the secret identified is a genuine data leak you should raise a [security incident](https://kainoshelp.atlassian.net/servicedesk/customer/portal/18). This will help us track how often these incidents occur and we can help you with the analysis and remediation if necessary. 
2. If you found the leak as part of your pre-commit hook and it has not actually made it into the repo, then you're probably lucky and you just need to fix the issue and move on.
3. If the secret has been committed to the repo then we need to:
    1. Know if the repo is hosted externally?
    2. The Cyber Security team will be happy to help you resolve the issue, and this will most likely result in you [removing sensitive data from a repo](https://help.github.com/en/github/authenticating-to-github/removing-sensitive-data-from-a-repository)

## False Positives
If your project is returning a false positive you can add some whitelisting regexes to individual rules e.g.:

```toml
[[Rules]]
    description = "Generic Password"
    regex = '''(?im)['"]?[a-z-_]*password[a-z-_]*['"]?\s*[=:]\s*('(?:[^'\\]|\\.){6,100}'|"(?:[^"\\]|\\.){6,100}")\s*,?\s*$'''
    tags = ["Password", "Generic"]

    [[Rules.Whitelist]]
        regex = '''passwordElement: '#password'''
        description = "ignore passwordElement"

    [[Rules.Whitelist]]
        regex = '''passwordElement2: '#password'''
        description = "ignore passwordElement2"
```

# Updates

To be notified of changes to the recommended regexes or updates to the guidance please enable notifications for this repo e.g.:

![Notifications - Watch](images/notifications.png)

# Further Information

## Global config
If you prefer to use a system wide config instead of a project specific config you can use the `--config` flag to reference your config e.g.:

```bash
gitleaks --config=/path/to/.gitleaks.toml --repo-path=. --verbose --pretty
```

If you want to use this file with the `pre-commit` hook above then set the environment variable **GITLEAKS_CONFIG** with this path e.g.:

```bash
export GITLEAKS_CONFIG=/path/to/.gitleaks.toml
```

## Proof-of-concept

Commiting secrets to public repos is a really common and often very serious problem. For example, any commit that is pushed to GitHub is made available via their Events API. So there are tools (e.g. [shhgit](https://shhgit.darkport.co.uk/)) that just continually poll this API looking for secrets. You don't have to spend too long on this site to realise how often this occurs.

![shhgit](images/shhgit.png)

## Regexes

We have used the following sources when defining our recommended [regexes](https://regex101.com/). If you have anything you would like to contribute just lets us know:

1. https://github.com/awslabs/git-secrets/blob/master/git-secrets#L233
2. https://github.com/eth0izzle/shhgit/blob/master/config.yaml
3. https://github.com/dxa4481/truffleHogRegexes/blob/master/truffleHogRegexes/regexes.json
4. https://github.com/zricethezav/gitleaks/blob/master/config/default.go
