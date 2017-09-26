require "base64"
require "openssl"
require "pathname"

require "encruby/version"
require "encruby/message"
require "encruby/file"

module Encruby
  class Error < StandardError; end

  def self.root
    Pathname.new(__FILE__).dirname.dirname
  end

  def self.bin_path
    exes = ENV['PATH'].split(":").map do |p|
      path = Pathname.new(p).join(self.class.name.downcase)
      path if path.executable?
    end.compact
    exes.any? ? exes.min : Encruby.root.join("exe", "encruby")
  end
end
