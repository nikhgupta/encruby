module Encruby
  class CLI < Thor

    desc "encrypt FILE", "Encrypt a ruby source code."
    method_option :identity_file, aliases: "-i", type: :string, required: true
    method_option :replace, aliases: "-r", type: :boolean, default: false
    def encrypt(path)
      opts = options.dup.merge(save: true)
      key  = opts.delete(:identity_file)
      response = Encruby::File.new(path, key, opts).encrypt
      say_status "Success", "Done!", :green
      say_status "Digest", response[:signature], :cyan
    end

    desc "decrypt FILE", "Decrypt a ruby source code."
    method_option :identity_file, aliases: "-i", type: :string, required: true
    method_option :verify, type: :boolean, default: true
    method_option :signature, aliases: "-s", type: :string, default: nil
    method_option :replace, aliases: "-r", type: :boolean, default: false
    def decrypt(path)
      hash = options[:signaturee]
      if !hash && options[:verify]
        hash = "Please, provide signature for this file! [Enter to skip verification]:"
        hash = ask(hash).strip
        hash = nil if hash.empty?
      end

      opts = options.dup.merge(signature: hash, save: true)
      key  = opts.delete(:identity_file)
      response = Encruby::File.new(path, key, opts).decrypt
      say_status "Success", "Done!", :green
      say_status "Digest", response[:signature], :cyan
    end

    desc "exec FILE", "Run an decrypted ruby source code."
    method_option :verify, type: :boolean, default: true
    method_option :signature, aliases: "-s", type: :string, default: nil
    method_option :identity_file, aliases: "-i", type: :string, required: true
    def exec(path)
      hash = options[:signature]
      if !hash && options[:verify]
        hash = "Please, provide signature for this file! [Enter to skip verification]:"
        hash = ask(hash).strip
        hash = nil if hash.empty?
      end

      opts = options.dup.merge(signature: hash, save: true)
      key  = opts.delete(:identity_file)
      response = Encruby::File.new(path, key, opts).decrypt
      path = response[:path]

      command = response[:path]
      command = "ruby #{command}" unless response[:path].readlines[0] =~ /^#\!/
      command = "#{command}; rm -f #{response[:path]}"
      Kernel.exec(command.to_s)
    end
  end
end
