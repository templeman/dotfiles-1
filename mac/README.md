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

    - [Display Menu] or EasyRes: Set higher/native resolutions
    - [Xcode]: select CLI tools in prefs
        - This is __required__ to build some apps like neovim@HEAD

## Setup ssh keys

1. `sshkeygen` (alias to generate new ed25519 keys)
1. Add the public key to GitHub, GitLab, Bitbucket, etc.
1. `ssh-add -K ~/.ssh/privatekeyfile` to store the key in Keychain.

## Install dotfiles

```sh
git clone https://github.com/davidosomething/dotfiles.git ~/.dotfiles/
```

## Install homebrew and bootstrap

Install homebrew according to <https://brew.sh/>.

Mojave no longer installs SDK headers for building certain things. It comes
with mac OS but requires manual execution. Use
[bootstrap/mac](../bootstrap/mac) to install it:

```sh
~/.dotfiles/bootstrap/mac
```

The script will also:

- `brew bundle` some default packages
- Run the fzf installer
- Change the user's default shell to the brewed `zsh`

Bundle dumps for specific systems are in my `~/.secret` (not public).


## GPG

[GPGTools](https://gpgtools.org/) is not required, use Homebrew instead.

Install GPG and pinentry with brew
`bi gnupg pinentry-mac`

Run `echo $GNUPGHOME`
It should output something like `/Users/sam/.config/gnupg`
If not, make sure you've run [bootstrap/xdg](../bootstrap/xdg) and [bootstrap/mac](../bootstrap/mac) for dotfiles
scaffolding.

Check this directory for a `gpg-agent.conf` file. If there is none, create it.

Ensure proper permissions on the gnupg directory by following the steps in
[this gist
comment](https://gist.github.com/oseme-techguy/bae2e309c084d93b75a9b25f49718f85?permalink_comment_id=4198726#gistcomment-4198726)

In `gpg-agent.conf`, add the path to the pinentry program (you can find the correct path
with `which pinentry-mac`)

```
# Connects gpg-agent to the OSX keychain via the brew-installed
# pinentry program from GPGtools. This is the OSX 'magic sauce',
# allowing the gpg key's passphrase to be stored in the login
# keychain, enabling automatic key signing.

pinentry-program /opt/homebrew/bin/pinentry-mac
```

Restart gpg-agent
`gpgconf --kill gpg-agent`

Now you have what you need to generate a new GPG key

Check for existing keys first
`gpg --list-secret-keys --keyid-format=long`

If none are found, generate one
`gpg --full-generate-key`

Recommended options:

- RSA and RSA
- 4096
- Expires: never

Generate a strong password with Bitwarden, and store it there

Sign a test message so pinentry-mac can store your password in the keychain
`echo "test" | gpg --clearsign`

This should open a dialog prompting your password. Remember to check “Save in Keychain”.


### Adding GPG Key to GitHub

First, copy your private key to add to GitHub
`gpg --export --armor your@email.here | pbcopy`

And paste it in [GitHub's Settings > SSH and GPG Keys > New GPG
key](https://github.com/settings/gpg/new)

Second, configure your git environment to use signed commits. I’ve done it globally. First obtain your public GPG keys:

```
$ gpg --list-secret-keys
(...)
sec   rsa2048 2019-01-15 [SC]
      YOUR_GPG_KEY_APPEARS_HERE
uid           [ultimate] Your Name <your@email.here>
ssb   rsa2048 2019-01-15 [E]
```

Then configure git

```
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_GPG_KEY
```
(might not need `--global` since we're using a local config at
`/.dotfiles/local/gitconfig`)

Finally, commit something with the-S argument to make sure it’s signed:
`git commit -S -m "Testing GPG signature"`

Taken from this gist comment: <https://gist.github.com/danieleggert/b029d44d4a54b328c0bac65d46ba4c65?permalink_comment_id=3464269#gistcomment-3464269>  
And this dev.to article: <https://dev.to/wes/how2-using-gpg-on-macos-without-gpgtools-428f>


## Cask notes

- dropbox
    - Has app settings sync so wait for it to finish syncing.
    - If the shared directory is on an external volume, disable autostart and
      add [LoginItems/DelayedDropbox.app](LoginItems/DelayedDropbox.app) to
      your login items instead. It is a generic app made using Script Editor.
- bettertouchtool
    - License in gmail
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

List Homebrew items in mac/Brewfile and run bootstrap/mac after editing to
apply changes. Install additional packages from [cask.md](./cask.md) as
desired.

## mackup

`mackup` backs up application settings. It will be installed if using this
repo's Brewfile.

`dot.mackup.cfg` defines some app settings (such as the itsycal plist). It is
symlinked to `~/.mackup.cfg` by `bootstrap/symlink`.

Mackup is configured to use `~/.local/Mackup` as the storage location. On my
system this is a symlink to a private settings repository.

Run `mackup restore` to restore settings from that repository.

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
- Install PHP packages with composer
  1. Use brew-managed PHP with `brew-php-switcher`
  `bi php@8.1`
  Unlink current php: `brew unlink php`
  `brew-php-switcher 8.1`
  1. Run [php/install-composer-packages](../php/install-composer-packages)
- Install
  [wp-cli](https://make.wordpress.org/cli/handbook/guides/installing/#recommended-installation)
  using the recommended method. Then move the resulting .phar build to
  `/Users/[user]/.config/composer/vendor/bin/wp`

[unlock]: https://github.com/davidosomething/Unlock
[Display Menu]: https://apps.apple.com/us/app/display-menu/id549083868?mt=12
[Xcode]: https://apps.apple.com/us/app/xcode/id497799835?mt=12
