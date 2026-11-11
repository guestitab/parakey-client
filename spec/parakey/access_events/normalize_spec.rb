RSpec.describe Parakey::AccessEvents::Normalize do
  let(:result) { described_class.new.call(**args) }

  let(:args) { { item: } }

  let(:item) do
    {
      id: 'F0pLa5oF69',
      activity: 'unlock',
      timestamp: '2016-04-06T14:27:38.710Z',
      user: { id: 'PoUTa5os60', email: 'test.user@test.com', firstName: 'Jon', lastName: 'Doe' },
      mobileDevice: { deviceType: 'ios', deviceModel: 'iPhone X', osVersion: '13.0', appVersion: '3.0.0' },
      info: {
        access: { id: access_id, name: "Parakey's Office" },
        accessKey: { id: access_key_id, createdBy: { id: '98hTa5osdw' } },
        domain: { id: '45Frs4WE2B', name: 'Parakey' },
        device: { id: device_id, name: 'Main Entrance' }
      }
    }
  end
  let(:device_id) { '8BnmJ89TrW' }
  let(:access_id) { 'qweRYuii89' }
  let(:access_key_id) { 'B7SRYuiT34' }

  context 'with valid arguments' do
    it_behaves_like 'successful call', value_containing: -> {
      {
        event_type: 'unlock',
        occurred_at: Time.zone.local(2016, 4, 6, 16, 27, 38, 710_000),
        external_id: 'F0pLa5oF69',
        access_id:,
        provider_lock_id: device_id,
        grant_external_id: access_key_id,
        metadata: { payload: item }
      }
    }

    context 'with a maintenance activity' do
      let(:item) { super().merge(activity: 'calibrate') }

      it_behaves_like 'successful call', value_containing: -> { hash_including(event_type: 'synced') }
    end
  end

  context 'with invalid arguments' do
    context 'when the item is blank' do
      let(:item) { nil }
      let(:message) { 'Event item is required.' }

      it_behaves_like 'failed call', failure_class: Parakey::ArgumentError
    end
  end
end
