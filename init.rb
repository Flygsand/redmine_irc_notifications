# -*- coding: utf-8 -*-

require 'redmine'
require_dependency 'notifier_hook'

Redmine::Plugin.register :redmine_irc_notifications do
  name 'Redmine IRC notifications plugin'
  author 'Martin Häger'
  description 'A plugin to display activity notifications on IRC'
  version '0.0.1'
end
