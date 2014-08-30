#!/usr/bin/env ruby
# unfollow-bot
# Copyright (c) 2014 nilsding
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "yaml"
require "twitter"
require "ostruct"

CONFIG = YAML.load_file File.expand_path('.', "config.yml")

texts = []
CONFIG["texts"].each { |text| texts << if /^\/(.*)\/$/ =~ text then /#{$1}/i else text end }

$client = Twitter::REST::Client.new do |config|
  config.consumer_key        = CONFIG["oauth"]["consumer_key"]
  config.consumer_secret     = CONFIG["oauth"]["consumer_secret"]
  config.access_token        = CONFIG["oauth"]["access_token"]
  config.access_token_secret = CONFIG["oauth"]["access_token_secret"]
end

streamer = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = CONFIG["oauth"]["consumer_key"]
  config.consumer_secret     = CONFIG["oauth"]["consumer_secret"]
  config.access_token        = CONFIG["oauth"]["access_token"]
  config.access_token_secret = CONFIG["oauth"]["access_token_secret"]
end

begin
  current_user = $client.current_user
rescue Exception => e
  puts "fuck you twitter: #{e.message}"
  # best hack:
  current_user = OpenStruct.new
  current_user.id = CONFIG["oauth"]["access_token"].split("-")[0]
end

# check whether the list was created and create it if it does not exist
if CONFIG["add_to_list"]
  begin
    exists = false
    $client.owned_lists.each { |x| exists = true if x.name == CONFIG["list_name"] }
    unless exists
      # create list
      puts "creating list #{CONFIG["list_name"]}"
      $client.create_list CONFIG["list_name"]
    else
      puts "using list #{CONFIG["list_name"]}"
    end
  rescue Exception => e
    puts "fuck you twitter: #{e.message}"
  end
end

##
# unfollows an user and adds it to the twitter list of unfollowed users if
# +CONFIG["list_name"]+ is set
# @param user [Integer, String] the user id or screen name to unfollow
def unfollow user
  puts "unfollowing #{user}"
  begin
    $client.unfollow user
    $client.add_list_member CONFIG["list_name"], user if CONFIG["add_to_list"]
  rescue Exception => e
    puts "fuck you twitter: #{e.message}"
  end
end

# userstream thing
loop do
  begin
    puts "connected to userstream"
    streamer.user do |object|
      case object
      when Twitter::Tweet
        unless current_user.id == object.user.id    # can't unfollow ourselves
          unless object.text[0..3].include? "RT @"  # ignore retweets
#             puts object.text
            texts.each do |text|
              if text.class == Regexp
                if text.match object.text.downcase
                  unfollow object.user.id
                end
              elsif text.class == String
                if object.text.downcase.include? text.downcase
                  unfollow object.user.id
                end
              end
            end
          end
        end
      end
    end
  rescue Exception => e
    if e.class == Interrupt
      puts "\rexiting..."
      exit 0
    end
    puts "lost userstream connection: #{e.message}"
    puts e.backtrace.join "\n"
  end
  puts "restarting in 30 seconds..."
  sleep 30
end