require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "analyze_document returns a manual review fallback without an attachment" do
    chat = Chat.new

    result = chat.analyze_document

    assert_equal "Manual Review Required", result["title"]
    assert_equal "manual_review", result["document_type"]
    assert_match "could not automatically analyze", result["advice"]
  end

  test "analyze_document returns a clear fallback for unsupported attachments" do
    chat = Chat.create!(user: users(:scanner_user))
    chat.document.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "letter.pdf",
      content_type: "application/pdf"
    )

    result = chat.analyze_document

    assert_equal "Manual Review Required", result["title"]
    assert_equal "manual_review", result["document_type"]
    assert_match "currently analyzes image uploads", result["advice"]
  end
end
