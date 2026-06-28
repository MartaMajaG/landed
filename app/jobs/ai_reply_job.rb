class AiReplyJob < ApplicationJob
  queue_as :default

  def perform(user_message_id)
    user_message = Message.find(user_message_id)
    chat = user_message.chat

    ai_response = chat.ask_document(user_message.content)

    ai_message = chat.messages.create!(
      role: "assistant",
      content: ai_response
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "ai-loading-#{user_message.id}",
      html: render_ai_bubble(ai_message.content)
    )

    Turbo::StreamsChannel.broadcast_append_to(
      chat,
      target: "chat-messages-#{chat.id}",
      html: '<script>(function(){ var el = document.getElementById("chat-messages-' + chat.id.to_s + '"); if(el) el.scrollTop = el.scrollHeight; })();</script>'
    )
  end

  private

  def render_ai_bubble(content)
    escaped = ERB::Util.html_escape(content)
    '<div style="display:flex; justify-content:flex-start; gap:8px; align-items:flex-start; margin-bottom:8px;">' \
      '<div style="width:28px; height:28px; background:#EEECFF; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; font-size:14px; color:#5B50E8;">&#10022;</div>' \
      '<div style="background:#F8F7FF; color:#1A1A2E; font-size:14px; line-height:1.6; padding:10px 14px; border-radius:16px 16px 16px 4px; max-width:75%;">' +
      escaped +
      '</div>' \
    '</div>'
  end
end
