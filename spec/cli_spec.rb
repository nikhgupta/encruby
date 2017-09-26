RSpec.describe "Encruby::CLI", :slow, type: :aruba do
  it "can encrypt/decrypt source/encrypted file in place" do
    key  = fixture_file("keys", "passwordless.pem")
    file = fixture_file("replaceable")

    if file.readlines[0].include?("encruby")
      file_crypt("replaceable", replace: true).decrypt
    end

    code = file.read

    run_command "encruby encrypt -i #{key} -r #{file}"
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.stdout).to match(/success\s*done/i)
    expect(last_command_started.stdout).to match(/digest\s*[a-f0-9]{64}/i)
    expect(file.read).not_to eq code

    key  = fixture_file("keys", "passwordless")
    run_command "encruby decrypt -i #{key} #{file} -r --no-verify"
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.stdout).to match(/success\s*done/i)
    expect(last_command_started.stdout).to match(/digest\s*[a-f0-9]{64}/i)
    expect(file.read).to eq code
  end
end

RSpec.describe 'Encruby::CLI.encrypt', :slow, type: :aruba do
  it "encrypts source file and creates a new file with encrypted code" do
    key  = fixture_file("keys", "passwordless.pem")
    file = fixture_file("simple.rb")
    outfile = fixture_file("simple.enc.rb")
    outfile.unlink if outfile.exist?

    expect(outfile).not_to exist
    run_command "encruby encrypt -i #{key} #{file}"
    expect(outfile).to exist
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.stdout).to match(/success\s*done/i)
    expect(last_command_started.stdout).to match(/digest\s*[a-f0-9]{64}/i)
  end

  it "displays errors in STDERR, if any" do
    key = "non-existent.pem"
    file = fixture_file("simple.rb")
    run_command "encruby encrypt -i #{key} #{file}"
    expect(last_command_started).not_to be_successfully_executed
    expect(last_command_started.stdout.strip).to be_empty
    expect(last_command_started.stderr).to match(/unreadable rsa/i)
  end
end

RSpec.describe 'Encruby::CLI.decrypt', :slow, type: :aruba do
  it "decrypts encrypted file and creates a new file with decrypted code" do
    encrypt_fixture :simple
    key  = fixture_file("keys", "passwordless")
    file = fixture_file("simple.enc.rb")
    outfile = fixture_file("simple.enc.dec.rb")
    outfile.unlink if outfile.exist?

    expect(outfile).not_to exist
    run_command "encruby decrypt -i #{key} #{file} --no-verify"
    expect(outfile).to exist
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started.stdout).to match(/success\s*done/i)
    expect(last_command_started.stdout).to match(/digest\s*[a-f0-9]{64}/i)
  end

  it "asks for signature of encrypted file, by default" do
    key  = fixture_file("keys", "passwordless")
    file = fixture_file("simple.enc.rb")
    run_command "encruby decrypt -i #{key} #{file}"
    type("\n")

    expect(last_command_started.stdout).to match(/provide signature/)
  end

  it "can verify the signature of encrypted file, if provided" do
    _, sign, _ = encrypt_fixture :simple
    key  = fixture_file("keys", "passwordless")
    file = fixture_file("simple.enc.rb")

    run_command "encruby decrypt -i #{key} #{file}"
    type(sign)
    expect(last_command_started).to be_successfully_executed

    run_command "encruby decrypt -i #{key} #{file}"
    type("a" + sign)
    expect(last_command_started).not_to be_successfully_executed
    expect(last_command_started.stderr).to match(/hash mismatch/i)
  end

  it "asks for password to RSA private key, if required" do
    encrypt_fixture :simple, password: true
    key  = fixture_file("keys", "password")
    file = fixture_file("simple.enc.rb")

    run_command "encruby decrypt -i #{key} #{file} --no-verify"
    expect(last_command_started).not_to be_successfully_executed
    expect(last_command_started.stderr).to match(/neither pub key nor priv key/i)
  end

  it "displays errors in STDERR, if any" do
    encrypt_fixture :simple
    key  = fixture_file("keys", "passwordless.pem")
    file = fixture_file("simple.enc.rb")
    run_command "encruby decrypt -i #{key} #{file} --no-verify"
    expect(last_command_started).not_to be_successfully_executed
    expect(last_command_started.stdout.strip).to be_empty
    expect(last_command_started.stderr).to match(/private key needed/)
  end
end
