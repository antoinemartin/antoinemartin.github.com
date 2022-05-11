---
title: Multiple Docker environments on Windows
date: 2022-05-11
slug: 2022/05/11/multiple-docker-environments-on-windows
description: |
  WSL rocks to manage docker instantiations
Categories:
  - Development
tags:
  - windows
  - docker
  - wsl
  - powershell
toc:
  enable: true
---

On Windows and docker platforms, your docker enviornment tends to get messy as
time goes by.

You can start over from a clean sheet with `docker system prune --all` but
sometimes you would like to keep some images around. This post shows how to set
up multiple docker environments on Windows with the help of WSL2 (Windows
Subsystem For Linux) and Alpine.

<!-- more -->

## How it works

The idea is to run docker on WSL and use a `docker` alias on the windows side to
invoke the docker command in the WSL distribution. This is a well-known usage
pattern [with](https://docs.docker.com/desktop/windows/wsl/) or
[without](https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9)
Docker desktop.

With this scenario, nothing prevents us having several WSL distributions with
docker. To the contrary, we are going to have several of them, and depending on
the environment we want to target, the actual docker command will run on one
distribution or the other.

To avoid the manual configuration of the several distributions, we are going to
use the
[Wsl-Alpine](https://www.powershellgallery.com/packages/Wsl-Alpine/1.1.1)
powershell module I have created (github
[here](https://github.com/antoinemartin/PowerShell-Wsl-Alpine)). It will allow
us create a distribution template we can reuse for each docker environment.

## Pre-requisites

In order to perform this guide, you will need

- To have a working WSL environment. Instructions are
  [here](https://docs.microsoft.com/en-us/windows/wsl/install).
- To be able to install powershell modules from the
  [Powershell Gallery](https://www.powershellgallery.com/). You may need to
  [update PowershellGet](https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.2#installing-the-latest-version-of-powershellget)
  on your system.

## Installing the Wsl-Alpine module

Install the `Wsl-Alpine` module with the following command:

```powershell
PS> Install-Module -Name Wsl-Alpine
```

## Creating the docker environment

In this step, we are going to create a WSL distribution template to run docker.
We will then use this template for our different docker environments.

We will start by creating a base Alpine WSL distribution:

```powershell
PS❯ install-WslAlpine docker
####> Creating directory [C:\Users\AntoineMartin\AppData\Local\docker]...
####> Downloading https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-minirootfs-3.15.0-x86_64.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\docker\rootfs.tar.gz...
####> Creating distribution [docker]...
####> Running initialization script on distribution [docker]...
####> Done. Command to enter distribution: wsl -d docker
PS❯
```

We will then confgure the distribution for docker:

```bash
# Get into to the distribution
PS❯ wsl -d docker -u root
[powerlevel10k] fetching gitstatusd .. [ok]
# Add docker
❯ apk --update add docker
(1/13) Installing libseccomp (2.5.2-r0)
...
OK: 304 MiB in 103 packages
# Start docker with OpenRC
❯ rc-update add docker default
 * service docker added to runlevel default
# Enable OpenRC (will start docker)
❯ openrc default
 * Caching service dependencies ...         [ ok ]
 * /var/log/docker.log: creating file
 * /var/log/docker.log: correcting owner
 * Starting Docker Daemon ...               [ ok ]
# Allow default user to run docker
❯ addgroup alpine docker
# Return to powershell
❯ exit
PS❯
```

Then we can test the distrbitution can run docker:

```powershell
PS❯ wsl -d docker docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

And we can stop it:

```powershell
# Terminate distrbution
PS❯ wsl --terminate docker
```

## Saving the docker distribution for reuse

Now we are going to save the WSL distribution in its current state in order to
be able to reuse it.

```powershell
PS> Export-WslAlpine docker -OutputFile $env:USERPROFILE\Downloads\docker.tar.gz
Distribution docker saved to C:\Users\AntoineMartin\Downloads\docker.tar.gz
```

The size of the distribution file system is about 115 Mbytes:

![template size](/images/s3.us-west-2.amazonaws.com_Untitled.png)

## Creating another docker environment

From the saved template, we can create a new docker environment that we name
`dockersandbox`:

```powershell
PS> Install-WslAlpine dockersandbox -SkipConfigure -RootFSURL file://$env:USERPROFILE/Downloads/docker.tar.gz
####> Creating directory [C:\Users\AntoineMartin\AppData\Local\dockersandbox]...
####> Downloading file://C:\Users\AntoineMartin/Downloads/docker.tar.gz â†’ C:\Users\AntoineMartin\AppData\Local\dockersandbox\rootfs.tar.gz...
####> Creating distribution [dockersandbox]...
####> Done. Command to enter distribution: wsl -d dockersandbox
PS>
```

{{< admonition warning >}} **Important** Confirguring the automatic start of
openrc through
[wsl.conf](https://docs.microsoft.com/fr-fr/windows/wsl/wsl-config#boot-settings)
doesn’t work (Windows 11 only). In consequence we need to start docker before
using it:

```powershell
PS> wsl -d dockersandbox -u root openrc default
 * Caching service dependencies ...            [ ok ]
 * Starting Docker Daemon ...                  [ ok ]
PS>
```

{{< /admonition >}}

We can test docker in our new environment:

```powershell
PS> wsl -d dockersandbox docker run --rm -it alpine:latest /bin/sh
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
df9b9388f04a: Pull complete
Digest: sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454
Status: Downloaded newer image for alpine:latest
/ # exit
PS>
```

## Switching between environments

Add the following alias to
`%USERPROFILE%\Documents\WindowsPowerShell\profile.ps1`:

```powershell
function RunDockerInWsl {
  # Take $Env:DOCKER_WSL or 'docker' if undefined
  $DockerWSL = if ($null -eq $Env:DOCKER_WSL) { "docker" } else { $Env:DOCKER_WSL }
  # Try to find an existing distribution with the name
  $existing = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss |  Where-Object { $_.GetValue('DistributionName') -eq $DockerWSL }
  if ($null -eq $existing) {
    # Fail if the distribution doesn't exist
    throw "The WSL distribution [$DockerWSL] does not exist !"
  } else {
    # Ensure docker is started
    wsl -d $DockerWSL -u root openrc default
    # Perform the requested command
    wsl -d $DockerWSL /usr/bin/docker $args
  }
}

Set-Alias -Name docker -Value RunDockerInWsl
```

It creates the `docker` alias. It will run docker command in the WSL
distribution specified by the `DOCKER_WSL` environment variable, falling down to
the `docker` WSL distribution if the variable is not defined. In consequence,
switching from one environment to the other is easy :

```powershell
PS> docker image ls
* Caching service dependencies ...         [ ok ]
* Starting Docker Daemon ...               [ ok ]
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
PS>$Env:DOCKER_WSL="dockersandbox"
PS>docker image ls
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
alpine       latest    0ac33e5f5afa   5 weeks ago   5.57MB
```

At this point, the two WSL distributions are running:

```powershell
PS> wsl -l -v
  NAME                    STATE           VERSION
...
  dockersandbox           Running         2
  docker                  Running         2
...
```

They can be stopped at will:

```powershell
PS> wsl --terminate docker
```

## Wrapping up

With WSL, having the ability to run Linux commands **IN** the current windows
directory and treating distrbutions like docker containers provides a lot of
flexibility and options when it comes to development environment setup and use.
