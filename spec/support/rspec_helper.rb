module Encruby
  module RSpecHelper
    def fixture_file(*path)
      Encruby.root.join("spec", "fixtures", *path)
    end

    def rsa_path(password: false, public: false)
      name = password ? "password" : "passwordless"
      name += ".pem" if public
      fixture_file("keys", name)
    end

    def rsa_data(password: false, public: false)
      rsa_path(password: password, public: public).read
    end

    def file_crypt(name, options = {})
      password   = options.delete(:password)
      use_public = options.delete(:public)
      key_path   = rsa_path(password: password, public: use_public)
      Encruby::File.new(fixture_file(name), key_path, options)
    end

    def encrypt_fixture(name, options = {})
      encrypted = fixture_file("#{name}.enc.rb")
      encrypted.unlink if encrypted.file?
      options   = { public: true, save: true }.merge(options)
      response  = file_crypt("#{name}.rb", options).encrypt
      [encrypted, response[:signature], response[:content]]
    end

    def decrypt_fixture(name, options = {})
      options   = { private: true, save: false }.merge(options)
      decrypted = fixture_file("#{name}.enc.dec.rb")
      decrypted.unlink if decrypted.file?
      response  = file_crypt("#{name}.enc.rb", options).decrypt
      response  = [response[:signature], response[:content]]
      response.unshift(decrypted) if options[:save]
      response
    end
  end
end
