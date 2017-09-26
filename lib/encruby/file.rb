module Encruby
  class File
    attr_accessor :path

    def initialize(path, key, options = {})
      @options, @path = options, Pathname.new(path.to_s)
      @options[:save] ||= @options[:replace]

      case
      when !@path.readable?
        raise Encruby::Error, "Unable to read file: #{path}"
      when !@path.file?
        raise Encruby::Error, "Must be a file: #{path}"
      end

      @crypto = Encruby::Message.new(key)
    end

    def save_converted(type: :encrypt, content: nil)
      if @options[:replace]
        path = @path
      else
        extension = type == :encrypt ? ".enc" : ".dec"
        path = @path.basename('.*').to_s + extension + @path.extname.to_s
        path = @path.dirname.join(path)
      end
      path.open("w"){|f| f.puts content}
      path.chmod(@path.stat.mode)
      path.chown(@path.stat.uid, @path.stat.gid)
    end

    def encrypt
      content   = extract_meta(@path.read)
      data      = content[:shebang].to_s + content[:code]
      response  = @crypto.encrypt(data)
      encrypted, hmac = response[:content], response[:signature]
      shebang   = "#!#{Encruby.bin_path}\n" if content[:shebang]

      content = "#{shebang}#{content[:comments]}\n__END__\n#{encrypted}"
      save_converted(type: :encrypt, content: content) if @options[:save]
      { signature: hmac, content: content }
    end

    def decrypt
      content   = extract_meta(@path.read)
      unless content[:code] && data = content[:code].split(/^__END__\s*\n/)[1]
        raise Error, "No encrypted content found. You sure this file has been encrypted?"
      end

      hash      = @options[:signature] if @options[:verify]
      response  = @crypto.decrypt(data, hash: hash)
      decrypted, hmac = response[:content], response[:signature]
      shebang   = decrypted.lines[0] if decrypted.lines[0] =~ /^#\!/
      decrypted = decrypted.lines[1..-1].join if shebang

      content   = "#{shebang}#{content[:comments]}#{decrypted}"
      save_converted(type: :decrypt, content: content) if @options[:save]
      { signature: hmac, content: content }
    end

    private

    def extract_meta(content)
      shebang  = content.lines[0] if content =~ /^#\!/
      code     = content.scan(/^\s+[^\s|#].*/m)[0]
      comments = content.gsub(/^\s+[^\s|#].*/m, '')
      comments = comments.gsub(shebang, '') if shebang
      { shebang: shebang, comments: comments, code: code }
    end
  end
end
