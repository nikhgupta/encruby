RSpec.describe Encruby do
  it "has a version number" do
    expect(Encruby::VERSION).not_to be nil
  end

  it "defines path to the root directory" do
    expect(described_class.root).to be_a(Pathname)
    expect(described_class.root.to_s.strip).not_to be_empty
  end

  it "defines path to the Encruby executable in the system" do
    expect(described_class.bin_path).to be_a(Pathname)
    expect(described_class.bin_path.to_s.strip).not_to be_empty
    expect(described_class.bin_path).to be_executable

    allow_any_instance_of(Pathname).to receive(:executable?).and_return(false)
    expect(described_class.bin_path).to eq(Encruby.root.join("exe", "encruby"))
  end
end
