# macOS/OS X

User data on encrypted volumes other than the boot volume will not mount until
login. To remedy this, see [Unlock] (forked to my GitHub for archival).

## Disable some keyboard shortcuts

Remove these using System Preferences:

- `Mission Control` owns <kbd>⌃</kbd><kbd>←</kbd> and <kbd>⌃</kbd><kbd>→</kbd>
- `Spotlight` owns <kbd>⌘</kbd><kbd>space</kbd>

## Reduce desktop icon size

Click desktop to focus Finder, <kbd>⌘</kbd><kbd>j</kbd> use smallest sizes for
everything.

## App store

1. iCloud sign in
1. Install App store apps

    - [Display Menu]: Set higher/native resolutions
    - [Xcode]: select CLI tools in prefs
    - This is __required__ to build some apps like neovim@HEAD

## Install homebrew

1. Install according to <https://brew.sh/>. Install bundles in a later step.

## Install dotfiles

```sh
git clone https://github.com/davidosomething/dotfiles.git ~/.dotfiles/
```

## Run bootstrap/mac

Mojave no longer installs SDK headers for building certain things. It comes
with mac OS but requires manual execution. Use
[bootstrap/mac](../bootstrap/mac) to install it:

```sh
~/.dotfiles/bootstrap/mac
```

The script will also:

- load the `dotfiles.plist`
- `brew bundle` some default packages
- Run the fzf installer
- Change the user's default shell to the brewed `zsh`

### System-specific

Bundle dumps for specific systems are in my `~/.secret` (not public).

### the dotfiles.plist

`./compile dotfiles.plist.json` generates the `dotfiles.plist` file in the
`mac/LaunchAgents` directory. It depends on the `plist` package from npm.
Redirect the compiled output to the plist file to update.
There is a limitation that it uses `$HOME/.dotfiles` instead of `$DOTFILES`
so you may want to edit (e.g. hardcode) the dotfiles path if you changed it.

The bootstrap script symlinks the plist. You'll have to manually use
`launchctl` command to load it and reboot to start it if you opt in.

## Cask notes

- dropbox
    - Has app settings sync so wait for it to finish syncing.
        - Including some `mackup` backups
    - If the shared directory is on an external volume, disable autostart and
      add [LoginItems/DelayedDropbox.app](LoginItems/DelayedDropbox.app) to
      your login items instead. It is a generic app made using Script Editor.
- bettertouchtool
    - License in synology drive or gmail
    - Provides better trackpad swipe configs, drag window snapping,
      modifier-hold window resizing
    - Synced to Dropbox
- hammerspoon
    - App launcher (<kbd>⌘</kbd><kbd>space</kbd>) to replace spotlight
      (disable spotlight shortcut first)
    - Audio output device switch in menubar, relies on `switchaudio-osx` which
      is in homebrew
    - Auto-type from clipboard (<kbd>⌃</kbd><kbd>⌘</kbd><kbd>v</kbd>) for
      paste blockers
    - Caffeinate in menubar
    - Window management keys to use sections of a monitor (try hitting the key
      multiple times) and to throw apps to the next monitor
      (<kbd>⌃</kbd><kbd>⌘</kbd><kbd>⇧</kbd><kbd>f/h/l/z/[/]</kbd>)

Install the rest of the packages from [cask.md](./cask.md) as desired.

## mackup

A `.mackup.cfg` defines some app settings (such as the itsycal plist) that
I don't keep version controlled (just in dropbox). Run `mackup restore` to
restore them (`mackup` is in the Brewfile).

## Install GPGTools and import key

1. Install the [dotfiles.plist](LaunchAgents/dotfiles.plist) first! It sets
   `GNUPGHOME` in the env for all apps. See the bootstrapping section above.
1. Follow these instructions
   <https://gist.github.com/danieleggert/b029d44d4a54b328c0bac65d46ba4c65>  

## Setup ssh keys

1. `sshkeygen` (alias to generate new ed25519 keys)
1. Add the public key to GitHub, GitLab, Bitbucket, etc.
1. `ssh-add -K ~/.ssh/privatekeyfile` to store the key in Keychain.

## Name the computer

1. Go to https://www.npmjs.com/package/epithet
2. Click "Test with RunKit" and generate snappy name
3. System Preferences > Sharing and enter the new name

## Install development tools

Installed packages before development tools. After you start using `pyenv` it
gets annoying to remember to switch back to system python for each `brew`
operation. Use the `bi` alias for a clean room install if possible.

- Increase file limits a la
  <https://github.com/karma-runner/karma/issues/1979#issuecomment-260790451>
    - See <https://gist.github.com/abernix/a7619b07b687bb97ab573b0dc30928a0>
      if there are still file limit issues
    - REBOOT for `ulimit -n` changes to take effect
- Install `chruby`, `ruby-install`
  1. `ruby-install ruby` to install latest
  1. `chruby` to that version
  1. Install gems using [ruby/install-default-gems](../ruby/install-default-gems)
- Install [nvm] MANUALLY via git clone into `$XDG_CONFIG_HOME`, then use it to
  install a version of `node` (and `npm`)
  1. Use nvm managed node
  1. Install the default packages using [node/install](../node/install)
- Install [pyenv] using `pyenv-installer` (rm `~/.local/pyenv` directory for
  clean install) and make sure to use the libs provided by brew. See the
  packages marked "for pyenv" in the [Brewfile](./Brewfile)
  1. Install the latest python using using
     [bootstrap/pyenv](../bootstrap/pyenv). This will also create a `neovim3`
     virtualenv. It uses [bin/mac-pyenv-install](../bin/mac-pyenv-install) to
     correctly set the SDK (which should have been installed by the mac
     bootstrapper).
  1. Set up the global pyenv as the latest stable (3.x). Check ansible
     compatibility first if it's needed (e.g. ansible is not 3.8.x ready).


[nvm]: https://github.com/nvm-sh/nvm
[pyenv]: https://github.com/pyenv/pyenv
[unlock]: https://github.com/davidosomething/Unlock
[Display Menu]: https://apps.apple.com/us/app/display-menu/id549083868?mt=12
[Xcode]: https://apps.apple.com/us/app/xcode/id497799835?mt=12
