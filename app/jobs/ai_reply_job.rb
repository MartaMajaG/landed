class AiReplyJob < ApplicationJob
  queue_as :default

  def perform(user_message_id)
    # 1. Load the user message and its associated chat from the database
    user_message = Message.find(user_message_id)
    chat = user_message.chat

    # 2. Call the AI synchronously — this blocks the worker thread, not the web server
    ai_response = chat.ask_document(user_message.content)

    # 3. Persist the AI reply as a new message record
    ai_message = chat.messages.create!(
      role: "assistant",
      content: ai_response
    )

    # 4. Broadcast a Turbo Stream replace to the browser via ActionCable.
    #    This targets the loading bubble that create.turbo_stream.erb inserted
    #    and swaps it with the real AI answer bubble.
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "ai-loading-#{user_message.id}",
      html: render_ai_bubble(ai_message.content)
    )
  end

  private

  # Builds the HTML string for the AI answer bubble.
  # This mirrors the bubble markup in show.html.erb and create.turbo_stream.erb.
  def render_ai_bubble(content)
    <<~HTML
      <div style="display:flex; justify-content:flex-start; gap:8px; align-items:flex-start; margin-bottom:8px;">
        <div style="width:28px; height:28px; background:#F0F1F8; border-radius:50%; display:flex; align-items:center; justify-content:center; flex-shrink:0; font-size:13px;">✦</div>
        <div style="background:#F3F4F6; color:#1A1A2E; font-size:14px; line-height:1.6; padding:10px 14px; border-radius:16px 16px 16px 4px; max-width:75%;">
          #{ERB::Util.html_escape(content)}
        </div>
      </div>
    HTML
  end
end
