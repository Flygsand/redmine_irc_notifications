module RedmineIrcNotifications
  module MessagePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        after_create :notify_irc_after_create
      end
    end

    module InstanceMethods
      private
      def notify_irc_after_create
        board = self.board
        content = RedmineIrcNotifications::Helpers.truncate_words(self.content)
        
        if self.parent
          message = "#{self.author.login} replied a message \"#{self.subject}\" on #{board.project.name}: \"#{content}\". http://#{Setting.host_name}/boards/#{board.id}/topics/#{self.root.id}#message-#{self.id}"
        else
          message = "#{self.author.login} wrote a new message \"#{self.subject}\" on #{board.project.name}: \"#{content}\". http://#{Setting.host_name}/boards/#{board.id}/topics/#{self.root.id}#message-#{self.id}"
        end
        
        RedmineIrcNotifications::IRC.speak message
      end
    end
  end
end
