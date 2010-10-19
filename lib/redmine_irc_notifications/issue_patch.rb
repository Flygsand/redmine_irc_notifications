module RedmineIrcNotifications
  module IssuePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        unloadable
        after_create :notify_irc_after_create
        after_update :notify_irc_after_update
      end
    end

    module InstanceMethods
      private
      def notify_irc_after_create
        description = RedmineIrcNotifications::Helpers.truncate_words(self.description)
        
        RedmineIrcNotifications::IRC.speak "#{self.author.login} created issue \"#{self.subject}\". Comment: \"#{description}\". http://#{Setting.host_name}/issues/#{self.id}"
      end

      def notify_irc_after_update
        journal = self.current_journal
        notes = RedmineIrcNotifications::Helpers.truncate_words(journal.notes)
        
        RedmineIrcNotifications::IRC.speak "#{journal.user.login} edited issue \"#{self.subject}\". Comment: \"#{notes}\". http://#{Setting.host_name}/issues/#{self.id}"
      end
    end
  end
end
