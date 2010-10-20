module RedmineIrcNotifications
  module JournalPatch
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
        notes = RedmineIrcNotifications::Helpers.truncate_words(self.notes)

        RedmineIrcNotifications::IRC.speak "#{self.user.login} edited issue \"#{self.issue.subject}\". Comment: \"#{notes}\". http://#{Setting.host_name}/issues/#{self.issue.id}"
      end
    end
  end
end
