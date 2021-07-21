# typed: false
require "json"
require "./models/db"
require "./models/email_provider"

FactoryBot.define do
  factory :provider_message, class: "EmailProvider::Message" do
    attachments { [association(:provider_attachment, message: instance)] }
  end
  factory :provider_attachment, class: "EmailProvider::Attachment" do
    association :message, factory: :provider_message
  end

  factory :email do
    conversation
    # You shouldn't need it, but docs are here:
    # https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#inline-definitioninstance
    attachments { [association(:attachment, email: instance)] }
  end
  factory :attachment do
    email
  end
  factory :conversation do
    sequence(:external_id)
  end
  factory :contract_scan_result do
    raw_result do
      <<-CONTRACT_SCAN_RESULT
    {
        "results": [
            {
                "extracted-values": [
                    {
                        "normalized-value": "NEWCO, INC.",
                        "score": 0.7239318694472867,
                        "text": "NEWCO, INC."
                    }
                ],
                "score": 0.955939669149689,
                "scan-key": "PartyName",
                "text": "BYLAWS OF NEWCO, INC. A DELAWARE CORPORATION BYLAWS OF NEWCO, INC. A DELAWARE CORPORATION OFFICES Registered Office."
            },
            {
                "extracted-values": [
                    {
                        "normalized-value": "Second Co.",
                        "score": 0.5239318694472867,
                        "text": "Second Co."
                    }
                ],
                "score": 0.845939669149689,
                "scan-key": "PartyName",
                "text": "BYLAWS OF NEWCO, INC. A DELAWARE CORPORATION BYLAWS OF NEWCO, INC. A DELAWARE CORPORATION OFFICES Registered Office."
            },
            {
                "extracted-values": [
                    {
                        "normalized-value": "Non-Disclosure Agreement",
                        "score": 0.6439318694472867,
                        "text": "Non-Disclosure Agreement"
                    }
                ],
                "score": 0.955939669149689,
                "scan-key": "ContractTitle",
                "text": "This Non-Disclosure Agrement, together with..."
            },
            {
                "extracted-values": [
                    {
                        "normalized-value": "Contractor Agreement",
                        "score": 0.9,
                        "text": "Non-Disclosure Agreement"
                    }
                ],
                "scan-key": "ContractTitle_V2",
                "text": "This Contractor Agreement, together with..."
            }
        ]
    }
    CONTRACT_SCAN_RESULT
    end

    trait :duplicated_party do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        parsed_result["results"] << parsed_result["results"][1]
        result.raw_result = parsed_result.to_json
      end
    end

    trait :two_title_results do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        original_result = parsed_result["results"].find do |r|
          r["scan-key"] == "ContractTitle"
        end

        # Otherwise the original will be modified
        title_result = original_result.deep_dup

        title_result["score"] = title_result["score"] + 0.001

        extracted_value = title_result["extracted-values"][0]

        extracted_value["score"] = extracted_value["score"] - 0.001

        extracted_value["text"] =
          extracted_value["normalized-value"] =
            "Higher sentence score, lower extracted score"

        parsed_result["results"] << title_result
        result.raw_result = parsed_result.to_json
      end
    end

    trait :blacklisted_party do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        parsed_result["results"][1]["extracted-values"][0]["normalized-value"] =
          "DELIVERED"
        result.raw_result = parsed_result.to_json
      end
    end

    trait :no_contract_type do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        parsed_result["results"].
          reject! { |r| r["scan-key"] == "ContractTitle" }.
          reject! { |r| r["scan-key"] == "ContractTitle_V2" }
        result.raw_result = parsed_result.to_json
      end
    end

    trait :no_title_v2_results do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        parsed_result["results"].
          reject! { |r| r["scan-key"] == "ContractTitle_V2" }
        result.raw_result = parsed_result.to_json
      end
    end

    trait :no_parties do
      after(:build) do |result|
        parsed_result = JSON.parse(result.raw_result)
        parsed_result["results"].reject! { |r| r["scan-key"] == "PartyName" }
        result.raw_result = parsed_result.to_json
      end
    end
  end
end
