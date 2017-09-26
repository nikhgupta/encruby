module RSpec::Matchers
  class BeEncrypted
    include ::RSpec::Matchers

    def matches?(content)
      content.lines.each do |line|
        expect(line).to match(/^[a-z0-9\/\+=]+$/i)
        expect(line.length).to be < 64
      end
    end
  end

  def be_encrypted
    BeEncrypted.new
  end
end

