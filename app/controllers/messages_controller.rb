class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])

    @user_message = @chat.messages.build(message_params)
    @user_message.role = "user"

    if @user_message.save
      # Call AI synchronously — response takes ~5-10s, covered by the loading spinner
      ai_response = @chat.ask_document(@user_message.content)

      @ai_message = @chat.messages.create!(
        role: "assistant",
        content: ai_response
      )

      respond_to do |format|
        # Turbo Stream: append both messages to the DOM without a page reload
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

  private

  def message_params
    params.require(:message).permit(:content)
  end
end


