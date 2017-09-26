RSpec.describe Encruby::File do

  context "#encrypt" do
    it "encrypts a ruby source file" do
      outfile, _, _ = encrypt_fixture :complex
      infile  = fixture_file("complex.rb")

      expect(outfile).to be_executable
        .and be_encrypted_version_of(infile)
        .with_shebang.with_comments(1, 15)
    end

    it "replaces shebang in a script with its own version" do
      outfile, _, _ = encrypt_fixture :simple
      infile  = fixture_file("simple.rb")
      expect(outfile).to be_executable
        .and be_encrypted_version_of(infile)
        .with_shebang.with_comments(1,3)

      expect(outfile.readlines[0]).to eq "#!#{Encruby.bin_path}\n"
    end

    it "does not prepend shebang when not present in original code" do
      outfile, _, _ = encrypt_fixture :noshebang
      infile  = fixture_file("noshebang.rb")
      expect(outfile).not_to be_executable
      expect(outfile).to be_encrypted_version_of(infile).with_comments(0,1)
      expect(outfile.readlines[0]).not_to include Encruby.bin_path.to_s
    end

    it "provides HMAC signature for original code for verification later" do
      _, hash, _ = encrypt_fixture(:simple)
      expect(hash).to match(/\A[a-f0-9]{64}\z/)
    end

    it "preserves initial comments in the original code" do
      _, _, content = encrypt_fixture(:complex)
      input = fixture_file("complex.rb").read
      expect(content.lines[1..15]).to eq input.lines[1..15]
    end

    it "copies file permissions and group information from source file" do
      outfile, _, _ = encrypt_fixture(:complex)
      infile = fixture_file("complex.rb")
      expect(outfile.stat.mode).to eq infile.stat.mode
      expect(outfile.stat.uid).to eq infile.stat.uid
      expect(outfile.stat.gid).to eq infile.stat.gid
    end
  end

  context "#decrypt" do
    it "decrypts an encrypted encruby file" do
      encrypt_fixture(:complex)
      response = file_crypt("complex.enc.rb").decrypt(save: false)
      expect(fixture_file('complex.rb').read).to eq response[:content]
    end

    it "restores the original shebang if any" do
      original    = fixture_file("simple.rb").read
      _, _, input = encrypt_fixture(:simple)
      _,   output = decrypt_fixture(:simple)
      expect(output.lines[0]).not_to eq input.lines[0]
      expect(output.lines[0]).to eq original.lines[0]
      expect(output.lines[0]).to match(/^#\!/)

      original    = fixture_file("noshebang.rb").read
      _, _, input = encrypt_fixture(:noshebang)
      _,   output = decrypt_fixture(:noshebang)
      expect(output.lines[0]).to eq input.lines[0]
      expect(output.lines[0]).to eq original.lines[0]
      expect(output.lines[0]).not_to match(/^#\!/)
    end

    it "raises error if encrypted file format does not comply" do
      expect {
        file_crypt("bad_encryption.rb", private: true).decrypt
      }.to raise_error Encruby::Error, /no encrypted content/i
    end

    it "provides HMAC signature for original code for verification" do
      _, outhash, _ = encrypt_fixture(:simple)
      inhash, _     = decrypt_fixture(:simple)
      expect(inhash).to eq outhash
    end

    it "copies file permissions and group information from encrypted file" do
      infile,  _, _ = encrypt_fixture(:complex)
      outfile, _, _ = decrypt_fixture(:complex, save: true)
      expect(outfile.stat.mode).to eq infile.stat.mode
      expect(outfile.stat.uid).to eq infile.stat.uid
      expect(outfile.stat.gid).to eq infile.stat.gid
    end
  end

  it "replaces original file in place, if required" do
    path = fixture_file("replaceable")
    code = path.read

    file_crypt("replaceable", replace: true).encrypt
    expect(path.read).not_to eq code

    file_crypt("replaceable", replace: true).decrypt
    expect(path.read).to eq code
  end

  context "errors with arguments" do
    it "raises error when file to be operated on can not be read" do
      dbl = spy(absolute?: true)
      allow(Pathname).to receive(:new).and_call_original
      allow(Pathname).to receive(:new).with("simple.rb").and_return dbl
      allow(dbl).to receive(:readable?).and_return false
      expect{
        file_crypt("simple.rb").encrypt
      }.to raise_error Encruby::Error, /unable to read/i
    end

    it "raises error when file to be operated is not a file" do
      expect{
        file_crypt("/").encrypt
      }.to raise_error Encruby::Error, /must be a file/i
    end

    it "raises error when path for key is blank" do
      [nil, "", "  ", " \n  "].each do |key|
        expect{
          described_class.new(fixture_file("simple.rb"), key).encrypt
        }.to raise_error Encruby::Error, /unreadable.*key/i
      end
    end

    it "raises error when content for key is blank" do
      [nil, "", "  ", " \n  "].each do |content|
        dbl = spy(readable?: true)
        allow(Pathname).to receive(:new).and_call_original
        allow(Pathname).to receive(:new).with(:key).and_return dbl
        allow(dbl).to receive(:read).and_return content
        expect{
          described_class.new(fixture_file("simple.rb"), :key).encrypt
        }.to raise_error Encruby::Error, /unreadable.*key/i
      end
    end
  end
end
