module RSpec::Matchers
  class BeEncryptedVersionOf
    include ::RSpec::Matchers

    def initialize(infile)
      @infile = infile
      @input  = ::File.read(infile.to_s)
      @code_at = 1
    end

    def with_shebang
      @shebang  = true
      @code_at += 1
      self
    end

    def with_comments(start, endno)
      @comments = start..endno
      @code_at  = endno + 2
      self
    end

    def matches?(outfile)
      encrypted = ::File.read(outfile.to_s)
      expect(encrypted.lines[0]).to match(/^#\!.*?encruby$/) if @shebang

      if @comments
        expect(encrypted.lines[@comments]).to eq @input.lines[@comments]
      end

      expect(encrypted.lines[@code_at-1]).to eq "__END__\n"

      encrypted.lines[@code_at..-1].each do |line|
        expect(line).to match(/^[a-z0-9\/\+=]+$/i)
        expect(line.length).to be < 64
      end

      expect(outfile.stat.uid).to  eq @infile.stat.uid
      expect(outfile.stat.gid).to  eq @infile.stat.gid
      expect(outfile.stat.mode).to eq @infile.stat.mode
    end
  end

  def be_encrypted_version_of(infile)
    BeEncryptedVersionOf.new(infile)
  end
end
