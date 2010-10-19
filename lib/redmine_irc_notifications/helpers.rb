module RedmineIrcNotifications
  module Helpers
    def self.truncate_words(text, length = 20, end_string = '...')
      return if text == nil
      words = text.split()
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    end
  end
end
