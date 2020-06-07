describe Fastlane::Actions::TryScanAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The try_scan plugin is working!")

      Fastlane::Actions::TryScanAction.run(nil)
    end
  end
end
