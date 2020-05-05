# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.puts' do
  it "triggers a start call exactly once" do
    allow(TTY::Pager::SystemPager).to receive(:exec_available?).and_return(true)
    output   = double(:output, :tty? => true)
    pager    = described_class.new(output: output)
    pager_io = double(:pager_io, puts: nil, close: true)

    expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

    pager.puts("one")
    pager.puts("two")
    pager.close
  end

  it "delegates any puts calls to the internal pager" do
    pager = described_class.new
    pager_io = StringIO.new

    expect(pager).to receive(:spawn_pager).once.and_return(pager_io)

    pager.puts("one")
    pager.puts("two")
    pager.close

    expect(pager_io.string).to eq("one\ntwo\n")
  end
end
