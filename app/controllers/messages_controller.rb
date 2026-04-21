class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    # Find the chat through current_user to ensure authorization
    @chat = current_user.chats.find(params[:chat_id])
    
    # Create the new message within the specific chat
    @message = @chat.messages.build(message_params)

    if @message.save
      # Redirect back to the chat view where the message was sent
      redirect_to chat_path(@chat)
    else
      # Fallback in case of save errors
      redirect_to chat_path(@chat), alert: "Message could not be sent."
    end
  end

  private

  def message_params
    # Whitelist content and role for the message
    params.require(:message).permit(:content, :role)
  end
end
