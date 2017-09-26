RSpec.describe Encruby::Message do
  let(:message){ "some message that needs encryption" }
  let(:rsa_pem){ rsa_path(public: true) }
  let(:rsa_pvt){ rsa_path(public: false) }
  let(:crypto) { described_class.new(rsa_pem) }

  it "defines AES mode to use" do
    expect(described_class::AES_MODE).not_to be_empty
  end

  it "raises error when provided RSA key can not be read" do
    dbl = double()
    allow(Pathname).to receive(:new).with(rsa_pem.to_s).and_return dbl
    allow(dbl).to receive(:readable?).and_return false
    expect{
      crypto.with_key(rsa_pem).encrypt(message)
    }.to raise_error Encruby::Error, /unreadable.*key/i
  end

  context "#encrypt" do
    it "encrypts given content and provides its signature" do
      response = crypto.with_key(rsa_pem).encrypt(message)
      expect(response[:signature].length).to eq 64
      expect(response[:content]).to be_encrypted
    end

    it "allows encrypting already encrypted content" do
      response = crypto.with_key(rsa_pem).encrypt(message)
      response = crypto.with_key(rsa_pem).encrypt(response[:content])
      expect(response[:signature].length).to eq 64
      expect(response[:content]).to be_encrypted
    end

    it "raises error when encrypting blank message" do
      expect{
        crypto.with_key(rsa_pem).encrypt("   \n ")
      }.to raise_error Encruby::Error, "data must not be empty"
    end

    it "can encrypt with private key" do
      response = crypto.with_key(rsa_pvt).encrypt(message)
      expect(response[:signature].length).to eq 64
      expect(response[:content]).to be_encrypted
    end

    it "raises OpenSSL errors as its own" do
      allow_any_instance_of(OpenSSL::Cipher).to receive(:encrypt)
        .and_raise OpenSSL::Cipher::CipherError, "some error"
      expect {
        crypto.with_key(rsa_pem).encrypt(message)
      }.to raise_error Encruby::Error, "some error"
    end
  end

  context "#decrypt" do
    before(:each) do
      @enc  = crypto.with_key(rsa_pem).encrypt(message)
      @enc2 = crypto.with_key(rsa_pem).encrypt(@enc[:content])
    end

    it "decrypts encrypted content using #encrypt" do
      response = crypto.with_key(rsa_pvt).decrypt(@enc[:content])
      expect(response[:signature]).to eq @enc[:signature]
      expect(response[:content]).to eq message
    end

    it "cannot decrypt using public key" do
      expect {
        crypto.with_key(rsa_pem).decrypt(@enc[:content])
      }.to raise_error Encruby::Error, "private key needed."
    end

    it "allows decrypting multiply encrypted content" do
      response = crypto.with_key(rsa_pvt).decrypt(@enc2[:content])
      expect(response[:signature]).to eq @enc2[:signature]
      expect(response[:content]).to eq @enc[:content]

      response = crypto.with_key(rsa_pvt).decrypt(response[:content])
      expect(response[:signature]).to eq @enc[:signature]
      expect(response[:content]).to eq message
    end

    it "verifies HMAC signature to ensure content has not been tempered with" do
      tempered = @enc[:content].gsub("a","b")
      expect{
        crypto.with_key(rsa_pvt).decrypt(tempered)
      }.to raise_error Encruby::Error, /hmac signature mismatch/i
    end

    it "verifies passed-on Hash by the sender - to ensure content has not been tempered with" do
      expect{
        hash = OpenSSL::Digest.hexdigest('sha256', Time.now.to_s)
        crypto.with_key(rsa_pvt).decrypt(@enc[:content], hash: hash)
      }.to raise_error Encruby::Error, /hash mismatch/i
    end

    it "raises OpenSSL errors as its own" do
      allow_any_instance_of(OpenSSL::Cipher).to receive(:decrypt)
        .and_raise OpenSSL::Cipher::CipherError, "some error"
      expect {
        crypto.with_key(rsa_pvt).decrypt(@enc[:content])
      }.to raise_error Encruby::Error, "some error"
    end
  end
end
