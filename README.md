This is very alpha, but 'works for me'

## INSTALL

```sh
bundle
cp .env.sample .env
```

Edit the Twitter keys requested in the .env.  See the Twitter gem if you need help finding these.

## Features:

1. Archives tweets
2. Prints with terminal colors
3. Expands URLs in tweets
4. Reports include recommended, search by regex, and all, with Reply-to text
5. Data store is in YAML, though an adapter is available.
6. Data store can be regularly pared down

## Usage

Preferably in a screen or tmux session

```sh
ruby loop.rb
```

This will

1. Run an import of most recent tweets in a forked process (to managed memory leaks)
2. Pare down the tweet archive when it reaches the threshold number of tweets
3. Repeat every 30 minutes

See the `loop.rb` file for how it's being invoked.

```sh
./recs.sh
```

Is in example script that runs the recommended tweet report `ruby lib/report.rb 'recommended' | less`

A 'favs.sh' script may be, e.g. `ruby lib/report.rb 'ruby|rbx|rubinius|rails' | less`

## Color

On my Mac OSX (Mavricks), I can get ANSI codes read in as color in less by typing `-R`

I also use `brew install source-highlight`

In my ~/.profile I have

```bashrc
# Like less but outputs colors instead of raw ansi escape codes
# brew install source-highlight
export LESSOPEN="| `brew --prefix`/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '
export LESSCHARSET=utf-8 # don't print out unicode as e.g. <E2><80><99>
# alias vless='vim -u /usr/share/vim/vim71/macros/less.vim'
# https://superuser.com/questions/71588/how-to-syntax-highlight-via-less
# function cless () {
#     pygmentize -f terminal "$1" | less -R
# }
# alias vless="/Applications/MacVim.app/Contents/Resources/vim/runtime/macros/less.sh"
```


## TODO:

* search across various tweet slices (for dates)
