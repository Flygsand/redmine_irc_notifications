# -*- coding: utf-8 -*-
require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare :redmine_irc_notifications do
  require_dependency 'issue'
  unless Issue.included_modules.include? RedmineIrcNotifications::IssuePatch
    Issue.send(:include, RedmineIrcNotifications::IssuePatch)
  end

  require_dependency 'message'
  unless Message.included_modules.include? RedmineIrcNotifications::MessagePatch
    Message.send(:include, RedmineIrcNotifications::MessagePatch)
  end

  require_dependency 'wiki_content'
  unless WikiContent.included_modules.include? RedmineIrcNotifications::WikiContentPatch
    WikiContent.send(:include, RedmineIrcNotifications::WikiContentPatch)
  end
end

Redmine::Plugin.register :redmine_irc_notifications do
  name 'Redmine IRC notifications plugin'
  author 'Martin Häger'
  description 'A plugin to display activity notifications on IRC'
  version '0.0.1'
  url 'http://github.com/mtah/redmine_irc_notifications'
  author_url 'http://freeasinbeard.org'
end
