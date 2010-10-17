# -*- coding: utf-8 -*-

require 'socket'

module RedmineIrcNotifications
  class NotifierHook < Redmine::Hook::Listener
    @@server  = nil
    @@port    = nil
    @@nick    = nil
    @@channel = nil

    def self.load_options
      options = YAML::load(File.open(File.join(Rails.root, 'config', 'irc.yml')))
      @@server = options[Rails.env]['server']
      @@port = options[Rails.env]['port'] || 6667
      @@nick = options[Rails.env]['nick']
      @@channel = options[Rails.env]['channel']
    end

    def controller_issues_new_after_save(context = { })
      @project = context[:project]
      @issue = context[:issue]
      @user = @issue.author
      speak "#{@user.login} created issue \"#{@issue.subject}\". Comment: \"#{truncate_words(@issue.description)}\". http://#{Setting.host_name}/issues/#{@issue.id}"
    end

    def controller_issues_edit_after_save(context = { })
      @project = context[:project]
      @issue = context[:issue]
      @journal = context[:journal]
      @user = @journal.user
      speak "#{@user.login} edited issue \"#{@issue.subject}\". Comment: \"#{truncate_words(@journal.notes)}\". http://#{Setting.host_name}/issues/#{@issue.id}"
    end

    def controller_messages_new_after_save(context = { })
      @project = context[:project]
      @message = context[:message]
      @user = @message.author
      speak "#{@user.login} wrote a new message \"#{@message.subject}\" on #{@project.name}: \"#{truncate_words(@message.content)}\". http://#{Setting.host_name}/boards/#{@message.board.id}/topics/#{@message.root.id}#message-#{@message.id}"
    end

    def controller_messages_reply_after_save(context = { })
      @project = context[:project]
      @message = context[:message]
      @user = @message.author
      speak "#{@user.login} replied a message \"#{@message.subject}\" on #{@project.name}: \"#{truncate_words(@message.content)}\". http://#{Setting.host_name}/boards/#{@message.board.id}/topics/#{@message.root.id}#message-#{@message.id}"
    end

    def controller_wiki_edit_after_save(context = { })
      @project = context[:project]
      @page = context[:page]
      @user = @page.content.author
      speak "#{@user.login} edited the wiki \"#{@page.pretty_title}\" on #{@project.name}. http://#{Setting.host_name}/projects/#{@project.identifier}/wiki/#{@page.title}"
    end

    private
    def speak(message)
      NotifierHook.load_options unless @@server && @@port && @@nick && @@channel

      sock = nil
      begin
        sock = TCPSocket.open(@@server, @@port)
        sock.puts "NICK #{@@nick}"
        sock.puts "USER #{@@nick} 0 * #{@@nick}"
        sock.puts "PRIVMSG #{@@channel} :#{message}"
        sock.puts "QUIT"
        until sock.eof? do
          sock.gets
        end
      rescue => e
        logger.error "Error during IRC notification: #{e.message}"
      ensure
        sock.close if sock
      end
    end

    def truncate_words(text, length = 20, end_string = '...')
      return if text == nil
      words = text.split()
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    end
  end
end
