module RedmineIrcNotifications
  module WikiContentPatch
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
        page = self.page
        comment = "Comment: \"#{self.comments}\". " unless self.comments.nil? || self.comments.empty?
        
        RedmineIrcNotifications::IRC.speak "#{self.author.login} created the wiki \"#{page.pretty_title}\" on #{page.project.name}. #{comment}http://#{Setting.host_name}/projects/#{page.project.identifier}/wiki/#{page.title}"
      end

      def notify_irc_after_update
        page = self.page
        comment = "Comment: \"#{self.comments}\". " unless self.comments.nil? || self.comments.empty?
        
        RedmineIrcNotifications::IRC.speak "#{self.author.login} edited the wiki \"#{page.pretty_title}\" on #{page.project.name}. #{comment}http://#{Setting.host_name}/projects/#{page.project.identifier}/wiki/#{page.title}"
      end
    end
  end
end
