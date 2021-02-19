# typed: true
require "./db/connect"
require "./services/create_attachment_scan_service"

class UploadEmailAttachmentsForScanService
  def self.run(message)
    return if message_already_scanned?(message)

    message.attachments.each do |attachment|
      CreateAttachmentScanService.run(attachment)
    end
  end

  def self.message_already_scanned?(message)
    # Ruby returns the value of the last command in a method, without an
    # explicit return keyword
    Email.where(external_id: message.id).exists?
  end
end
