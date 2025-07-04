# macOS

User data on encrypted volumes other than the boot volume will not mount until
login. To remedy this, see [Unlock] (forked to my GitHub for archival).

## App store

1. iCloud sign in
1. Install App store apps, Xcode

## Install dotfiles

```sh
git clone https://github.com/davidosomething/dotfiles.git ~/.dotfiles/
~/.dotfiles/bootstrap/symlink
# restart terminal
```

## Setup ssh keys

1. Use `sshkeygen` alias to generate new Ed25519 keys
1. Add the public key to GitHub, GitLab, Bitbucket, etc.
1. Optionally change the `~/.dotfiles` origin protocol to SSH

## Install homebrew and install packages

Install homebrew according to <https://brew.sh/>. Install base `Brewfile` (or `personal.Brewfile`).

```sh
brew bundle --file=~/.dotfiles/mac/Brewfile
# brew bundle --file=~/.dotfiles/mac/personal.Brewfile
```

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

### Cask notes

List Homebrew items in mac/Brewfile and run bootstrap/mac after editing to
apply changes. Install additional packages from [cask.md](./cask.md) as
desired.

- bettertouchtool
  - I keep my license in syncthing/gmail/bitwarden
  - Most important thing is three-finger click to middle click
  - Provides better trackpad swipe configs, drag window snapping,
    modifier-hold window resizing
- hammerspoon
  - App launcher (<kbd>⌘</kbd><kbd>space</kbd>) to replace spotlight
    (disable spotlight shortcut first)
  - Audio output device switch in menu bar, relies on `switchaudio-osx` which
    is in homebrew
  - Auto-type from clipboard (<kbd>⌃</kbd><kbd>⌘</kbd><kbd>v</kbd>) for
    paste blockers
  - Caffeinate icon in menu bar
  - Window management keys to use sections of a monitor (try hitting the key
    multiple times) and to throw apps to the next monitor
    (<kbd>⌃</kbd><kbd>⌘</kbd><kbd>⇧</kbd><kbd>f/h/l/z/[/]</kbd>)

## Name the computer

1. Go to https://www.npmjs.com/package/epithet
2. Click "Test with RunKit" and generate snappy name
3. System Preferences > Sharing and enter the new name

## Install development tools

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

## Manually disable some keyboard shortcuts

Remove these using System Preferences:

- `Keyboard` disable a bunch of things in `Text Replacements`
- `Mission Control` owns <kbd>⌃</kbd><kbd>←</kbd> and <kbd>⌃</kbd><kbd>→</kbd>
- `Spotlight` owns <kbd>⌘</kbd><kbd>space</kbd>
  - I remap this to hammerspoon's seal instead.
- Disable `Trackpad` various Zoom options.

[unlock]: https://github.com/davidosomething/Unlock
