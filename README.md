IRC Notifier for Redmine
=============================

A Redmine plugin to display activity notifications on IRC. Based on http://github.com/edouard/redmine_campfire_notifications.

**Note:** The plugin won't actually `JOIN` your channel, so you need to either set `-n` on the channel or modify the code.

Installation
------------

- Install the plugin:

`git clone http://github.com/mtah/redmine_irc_notifications.git vendor/plugins/redmine_irc_notifications`

- copy irc.yml.example into config/irc.yml with your IRC settings

`cp vendor/plugins/redmine_irc_notifications/config/irc.yml.example config/irc.yml`
