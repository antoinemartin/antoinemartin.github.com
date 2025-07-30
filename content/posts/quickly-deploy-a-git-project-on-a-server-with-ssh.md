+++
title = "Quickly Deploy a Git Project on a Server With Ssh"
date = "2012-10-24"
slug = "2012/10/24/quickly-deploy-a-git-project-on-a-server-with-ssh"
Categories = ["DevOps"]
Tags = ["old", "git", "bash", "ssh", "linux", "macos"]
+++

So you have this brand new project `my_project` of yours with your local Git
repository set up and you want to quickly make it available for others to clone
on your repository server.

All your projects are located in your server `git.mycompany.com` under
`/srv/git`. You're using the user named `git` to connect to your server with the
SSH private key located in `~/.ssh/git`.

Here is the quickest way to deploy your project:

<!-- More -->

You first add your SSH key to the SSH agent :

```sh
[antoine@dev my_project] $ ssh-add ~/.ssh/git
```

If the agent is not started, you need to execute first :

```sh
[antoine@dev my_project] $ eval `ssh-agent`
```

Then you create an empty Git bare repository on your server with the name of
your project :

```sh
[antoine@dev my_project] $ ssh git@git.mycompany.com "git --bare init /srv/git/$(basename $(pwd)).git"
Initialized empty Git repository in /srv/git/my_project.git/
```

Then you add your newly created remote Git repository as the origin of your
local repo :

```sh
[antoine@dev my_project] $ git remote add origin "git@git.mycompany.com:/srv/git/$(basename $(pwd)).git"
```

You push your master branch to the remote repository :

```sh
[antoine@dev my_project] $ git push origin master
Counting objects: 3, done.
Writing objects: 100% (3/3), 209 bytes, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@git.mycompany.com:/srv/git/my_project.git
 * [new branch]      master -> master
```

Lastly, you make your local branch track your remote branch :

```sh
[antoine@dev my_project] $ git branch --set-upstream master origin/master
Branch master set up to track remote branch master from origin.
```

The last two steps can be done for any local branch you have that you want to
push on the server.

You can test pulling from the server :

```sh
[antoine@dev my_project] $ git pull
Already up-to-date.
```

That's it !
