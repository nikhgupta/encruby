module Encruby
  class CLI < Thor

    desc "encrypt FILE", "Encrypt a ruby source code."
    method_option :identity_file, aliases: "-i", type: :string, required: true
    method_option :replace, aliases: "-r", type: :boolean, default: false
    def encrypt(path)
      _, digest = Encruby::File.new(path, options).encrypt
      say_status "Success", "Done!", :green
      say_status "Digest", digest, :cyan
    end

    desc "decrypt FILE", "Decrypt a ruby source code."
    method_option :identity_file, aliases: "-i", type: :string, required: true
    method_option :verify_hash, aliases: "-h", type: :string, default: nil
    method_option :replace, aliases: "-r", type: :boolean, default: false
    def decrypt(path)
      unless hash = options[:verify_hash]
        hash = "Please, provide SHA256 hash for this file! [Enter to skip verification]:"
        hash = ask(hash).strip
        hash = nil if hash.empty?
      end

      opts = options.dup.merge(verify_hash: hash)
      key  = opts.delete(:identity_file)
      _, digest = Encruby::File.new(path, key, opts).decrypt
      say_status "Success", "Done!", :green
      say_status "Digest", digest, :cyan
    end

    # def run

    # end
  end
end
