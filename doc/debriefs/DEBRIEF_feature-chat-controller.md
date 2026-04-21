# DEBRIEF: Chat Controller & Data Security

## Summary of Changes
We created the `ChatsController` (`app/controllers/chats_controller.rb`) to manage the process of uploading PDFs and viewing the results. We implemented four standard actions: `index`, `show`, `new`, and `create`.

## Technical Details & Implications
- **Authentication (`before_action`):** We added `authenticate_user!`, which forces the browser to verify a user is logged in before any method in this controller is executed.
- **Security Scoping:** In the `index`, `show`, and `create` actions, we use `current_user.chats`. Technically, this means the database query starts with the user's ID. 
    - **Implication:** This prevents a security vulnerability called "ID Guesting." It ensures that User A can never see User B's documents, even if they manually type User B's document ID into the browser address bar.
- **Strong Parameters (`chat_params`):** We implemented a private method to explicitly permit only `:checklist_item_id` and `:pdf`. 
    - **Implication:** This protects against "Mass Assignment" attacks, ensuring that a user cannot inject malicious data into other columns of the database during an upload.
- **Active Storage Integration:** When `save` is called on `@chat`, Rails recognizes the `:pdf` attachment and handles the background task of moving the file to local storage and linking it to the record.

## GitHub Pull Request Snippet
"Developed the `ChatsController` with a focus on data isolation and security. Implemented `current_user` scoping for all queries and established strong parameter filtering for PDF uploads."
