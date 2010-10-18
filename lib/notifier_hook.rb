# -*- coding: utf-8 -*-

require 'socket'

module RedmineIrcNotifications
  class NotifierHook < Redmine::Hook::Listener
    @@server   = nil
    @@port     = nil
    @@nick     = nil
    @@user     = nil
    @@channel  = nil
    @@nickserv = nil

    @@mutex = Mutex.new

    def self.load_options
      options = YAML::load(File.open(File.join(Rails.root, 'config', 'irc.yml')))
      @@server = options[Rails.env]['server']
      @@nick = options[Rails.env]['nick']
      @@user = options[Rails.env]['user']
      @@channel = options[Rails.env]['channel']
      @@nickserv = options[Rails.env]['nickserv']
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
    def truncate_words(text, length = 20, end_string = '...')
      return if text == nil
      words = text.split()
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    end

    def speak(message)
      Thread.new do
        sock = nil

        begin
          NotifierHook.load_options unless @@server && @@nick && @@user && @@channel
          raise ArgumentError, 'server, nick, user and channel must be set' if @@server.nil? || @@nick.nil? || @@user.nil? || @@channel.nil?
          raise ArgumentError, 'NickServ password must be set' if @@nickserv && @@nickserv['password'].nil?

          @@mutex.synchronize do
            sock = TCPSocket.open(@@server, @@port || 6667)
            sock.puts "USER #{@@user} 0 * #{@@user}"
            sock.puts "NICK #{@@nick}"

            unless nick_available?(sock)
              if @@nickserv
                nickserv_nick = @@nickserv['nick'] || 'NickServ'

                sock.puts "NICK #{random_nick}"
                sock.puts "PRIVMSG #{nickserv_nick} :GHOST #{@@nick} #{@@nickserv['password']}"
                wait_for_nick_to_become_available(sock)
                sock.puts "NICK #{@@nick}"
              else
                raise "Nick \"#{@@nick}\" was not available, and NickServ is not here to help us."
              end
            end

            sock.puts "PRIVMSG #{@@channel} :#{message}"
            sock.puts "QUIT"
          end

        rescue => e
          logger.error "Error during IRC notification: #{e.message}"
        ensure
          if sock
            until sock.eof? do
              sock.gets
            end
            sock.close
          end
        end
      end
    end

    def nick_available?(sock)
      until sock.eof? do
        status = sock.gets.chomp.split(' ')[1]
        return true if status == '001'
        return false if status == '433'
      end

      err_premature_eof
    end

    def wait_for_nick_to_become_available(sock)
      until sock.eof? do
        return if sock.gets =~ /has been ghosted|is not online/
      end

      err_premature_eof
    end

    def err_premature_eof
      raise 'Premature EOF'
    end

    def random_nick(length = 32)
      (0...length).map{65.+(rand(25)).chr}.join
    end
  end
end
