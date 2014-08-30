# unfollow-bot

This is a simple bot that unfollows every user that gets on your nerves by
tweeting certain things.  It also adds every unfollowed person to a Twitter
list.

## Usage

Install the dependencies:

```shell
$ bundle install
```

Configure the bot by copying the `config.yml.example` to `config.yml` and
editing it afterwards.  Create and add access tokens on
[apps.twitter.com][epps].

```shell
$ cp config.yml.example config.yml
$ vim config.yml
```

Finally, start the bot.

```shell
$ ruby bot.rb
```

If you want to add someone to the whitelist, just tweet
`ubot:whitelist-add USERNAME`.  Remove the user by tweeting
`ubot:whitelist-del USERNAME`.
    
[epps]: https://apps.twitter.com