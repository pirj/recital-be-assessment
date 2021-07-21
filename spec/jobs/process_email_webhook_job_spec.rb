# typed: false
# frozen_string_literal: true

require "./spec/spec_helper"
require "./jobs/process_email_webhook_job"

RSpec.describe ProcessEmailWebhookJob do
  let(:message) { FactoryBot.build(:provider_message) }

  before do
    # This mocks out the call. Normally we'd do a more integration test, but
    # here the full class is mocked out for the assessment. So, by adding this
    # mock, we get the ability to check that it was run as an expectation below.
    allow(CreateAttachmentScanService).to receive(:run)
  end

  it "does not cache the message by default" do
    expect { described_class.perform(message) }.not_to change { Email.count }
  end

  it "scans the attachment" do
    described_class.perform(message)
    expect(CreateAttachmentScanService).to have_received(:run).once.with(
      message.attachments.first
    )
  end

  context "when the conversation is already cached" do
    let(:cached_convo) { FactoryBot.create(:conversation) }

    before do
      message.conversation_id = cached_convo.external_id
    end

    it "caches the email" do
      expect { described_class.perform(message) }.to change {
                                                       Email.count
                                                     }.by(1)
    end

    it "scans the attachment" do
      described_class.perform(message)
      expect(CreateAttachmentScanService).to have_received(:run).once.with(
        message.attachments.first
      )
    end
  end
end
