require 'socket'

module RedmineIrcNotifications
  class IRC
    @@server   = nil
    @@port     = nil
    @@nick     = nil
    @@user     = nil
    @@channel  = nil
    @@nickserv = nil

    @@mutex = Mutex.new

    def self.speak(message)
      Thread.new do
        sock = nil

        begin
          load_options unless @@server && @@nick && @@user && @@channel
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

    private
    def self.load_options
      options = YAML::load(File.open(File.join(Rails.root, 'config', 'irc.yml')))
      @@server = options[Rails.env]['server']
      @@nick = options[Rails.env]['nick']
      @@user = options[Rails.env]['user']
      @@channel = options[Rails.env]['channel']
      @@nickserv = options[Rails.env]['nickserv']
    end

    def self.nick_available?(sock)
      until sock.eof? do
        status = sock.gets.chomp.split(' ')[1]
        return true if status == '001'
        return false if status == '433'
      end

      err_premature_eof
    end

    def self.wait_for_nick_to_become_available(sock)
      until sock.eof? do
        return if sock.gets =~ /has been ghosted|is not online/
      end

      err_premature_eof
    end

    def self.err_premature_eof
      raise 'Premature EOF'
    end

    def self.random_nick(length = 32)
      (0...length).map{65.+(rand(25)).chr}.join
    end
    
  end
end
