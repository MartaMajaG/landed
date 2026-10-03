class AiReplyJob < ApplicationJob
  queue_as :default

  def perform(user_message_id)
    user_message = Message.find(user_message_id)
    chat = user_message.chat

    ai_response = chat.ask_document(user_message.content)

    if ai_response.blank?
      # Nothing is saved: show an error bubble with a retry button instead
      broadcast_bubble(chat, user_message, ApplicationController.render(
        partial: "messages/ai_error", locals: { chat: chat, user_message: user_message }
      ))
      return
    end

    ai_message = chat.messages.create!(role: "assistant", content: ai_response)
    broadcast_bubble(chat, user_message, ApplicationController.render(
      partial: "messages/ai_bubble", locals: { content: ai_message.content, animate: true }
    ))
  rescue => e
    Rails.logger.error "[AiReplyJob] #{e.class}: #{e.message}"
    if defined?(chat) && chat && defined?(user_message) && user_message
      broadcast_bubble(chat, user_message, ApplicationController.render(
        partial: "messages/ai_error", locals: { chat: chat, user_message: user_message }
      ))
    end
  end

  private

  def broadcast_bubble(chat, user_message, html)
    Turbo::StreamsChannel.broadcast_replace_to(chat, target: "ai-loading-#{user_message.id}", html: html)
    Turbo::StreamsChannel.broadcast_append_to(
      chat,
      target: "chat-messages-#{chat.id}",
      html: '<script>(function(){ var el = document.getElementById("chat-messages-' + chat.id.to_s + '"); if(el) el.scrollTop = el.scrollHeight; })();</script>'
    )
  end
end
