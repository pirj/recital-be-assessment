# typed: strict
# This file is the code that executes when Recital receives (via a webhook) a
# notification of a new email to process.

require "sorbet-runtime"
require "./db/connect"
require "./models/email_provider"
require "./services/upload_email_attachments_for_scan_service"

class ProcessEmailWebhookJob
  extend T::Sig

  sig { params(message: EmailProvider::Message).void }
  def self.perform(message)
    # Here is where the message would be uploaded
    UploadEmailAttachmentsForScanService.run(message)

    # Tip: if you want step-by-step debugging, you can uncomment this line here.
    # Docs: https://github.com/deivid-rodriguez/pry-byebug#commands
    # binding.pry
    save_to_email_cache(message) if conversation_already_cached?(message)

    # If there's no attachments then there's nothing to scan
    return if message.attachments.blank?
  end

  sig { params(message: EmailProvider::Message).void }
  def self.save_to_email_cache(message)
    # Exclamation marks mean an error will be thrown if the operation fails
    Email.create!(
      external_id: message.id,
      conversation: Conversation.find_by!(external_id: message.conversation_id)
    )
  end

  sig { params(message: EmailProvider::Message).returns(T::Boolean) }
  def self.conversation_already_cached?(message)
    Conversation.exists?(external_id: message.conversation_id)
  end
end
