class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    # Find the chat through current_user to ensure authorization
    @chat = current_user.chats.find(params[:chat_id])

    # Build and save the user's message
    @message = @chat.messages.build(message_params)
    @message.role = "user"

    if @message.save
      # Call the AI with the user's question using the document's existing context
      ai_response = @chat.ask_document(@message.content)

      # Save the AI's response as a second message in the same chat
      @chat.messages.create!(
        role: "assistant",
        content: ai_response
      )

      redirect_to chat_path(@chat), notice: "Response received."
    else
      redirect_to chat_path(@chat), alert: "Message could not be sent."
    end
  end

  private

  def message_params
    # Only permit content — role is set explicitly in the action, not from the form
    params.require(:message).permit(:content)
  end
end

