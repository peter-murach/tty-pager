# frozen_string_literal: true

RSpec.describe TTY::Pager::SystemPager, '.page' do
  it "executes the pager command in a subprocess" do
    text     = "I try all things, I achieve what I can.\n"
    allow(TTY::Pager::SystemPager).to receive(:exec_available?).and_return(true)
    output   = double(:output, :tty? => true)
    pager    = described_class.new(output: output)
    write_io = spy
    pid      = 12345

    allow(IO).to receive(:popen).and_return(write_io)
    allow(write_io).to receive(:pid).and_return(pid)
    allow(write_io).to receive(:closed?).and_return(false)
    status = double(:status, :success? => true)
    allow(Process).to receive(:waitpid2).with(pid, any_args).and_return([1, status])

    pager.page(text)
    expect(write_io).to have_received(:write).with(text)
    expect(write_io).to have_received(:close)
  end

  it "streams individual line and raises PagerClosed error" do
    system_pager = described_class.new
    allow(system_pager).to receive(:pager_command).and_return("less")
    allow(described_class).to receive(:run_command).and_return("")
    command_io = spy(:command_io)
    allow(IO).to receive(:popen).and_return(command_io)
    allow(command_io).to receive(:public_send).and_raise(Errno::EPIPE)

    expect {
      system_pager << "I try all things, I achieve what I can."
    }.to raise_error(TTY::Pager::PagerClosed,
                     "The pager process (`less`) was closed")
  end

  describe "block form" do
    it "calls .close when the block is done" do
      system_pager = spy(:system_pager)
      allow(described_class).to receive(:exec_available?) { true }
      allow(described_class).to receive(:new) { system_pager }

      text = "I try all things, I achieve what I can.\n"
      described_class.page do |pager|
        pager.write(text)
      end

      expect(system_pager).to have_received(:write).with(text)
      expect(system_pager).to have_received(:close)
    end
  end
end
