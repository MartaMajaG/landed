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
    ApplicationController.render(partial: "messages/ai_bubble", locals: { content: content })
  end
end
