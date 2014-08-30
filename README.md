# unfollow-bot

This is a simple bot that unfollows every user that gets on your nerves by
tweeting certain things.  It also adds every unfollowed person to a Twitter
list.

## Usage

Install the dependencies:

    $ bundle install

Configure the bot by copying the `config.yml.example` to `config.yml` and
editing it afterwards.  Create and add access tokens on
[apps.twitter.com][epps].

    $ cp config.yml.example config.yml
    $ vim config.yml

Finally, start the bot.

    $ ruby bot.rb
    
[epps]: https://apps.twitter.com