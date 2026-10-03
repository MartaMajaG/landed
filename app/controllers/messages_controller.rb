class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])

    @user_message = @chat.messages.build(message_params)
    @user_message.role = "user"

    if @user_message.save
      # Enqueue background job — the AI call runs in the worker process, not here.
      # The job will broadcast the AI reply via ActionCable when it completes.
      AiReplyJob.perform_later(@user_message.id)

      respond_to do |format|
        # Turbo Stream: immediately returns the loading bubble to the browser
        format.turbo_stream
        # Fallback for non-Turbo clients
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("chat-error", partial: "error") }
        format.html { redirect_to chat_path(@chat), alert: "Message could not be sent." }
      end
    end
  end

  # Retry button on a failed or slow AI reply: queue the same question again
  def regenerate
    @chat = current_user.chats.find(params[:chat_id])
    @user_message = @chat.messages.where(role: "user").find(params[:id])
    AiReplyJob.perform_later(@user_message.id)

    render turbo_stream: turbo_stream.replace(
      "ai-loading-#{@user_message.id}",
      partial: "messages/ai_loading",
      locals: { chat: @chat, user_message: @user_message }
    )
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
