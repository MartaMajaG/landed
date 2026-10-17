namespace :tasks do
  desc "Generate AI expert tips for all tasks that don't have them yet"
  task generate_expert_tips: :environment do
    tasks = Task.all.order(:id)
    total = tasks.count

    puts "\n⚡ Generating expert tips for #{total} tasks...\n\n"

    tasks.each_with_index do |task, index|
      prefix = "[#{index + 1}/#{total}]"

      if task.expert_tips.present?
        puts "#{prefix} SKIP  #{task.name} (already has #{task.expert_tips.length} tips)"
        next
      end

      print "#{prefix} Generating... #{task.name}"
      tips = TaskInsightsService.new(task).call

      if tips.any?
        task.update!(expert_tips: tips)
        puts " → ✓ #{tips.length} tips saved"
      else
        puts " → ✗ Failed (API returned empty — skipping)"
      end

      # Small delay between requests to avoid rate limiting
      sleep(0.5) unless index == total - 1
    end

    puts "\n✅ Done. To verify:\n  bin/rails runner 'Task.all.each { |t| puts \"#{t.name}: #{t.expert_tips.length} tips\" }'\n\n"
  end

  desc "Regenerate expert tips for every task, keeping a task's existing tips if the new call returns nothing"
  task regenerate_expert_tips: :environment do
    tasks = Task.all.order(:id)
    total = tasks.count

    puts "\n⚡ Regenerating expert tips for #{total} tasks...\n\n"

    tasks.each_with_index do |task, index|
      prefix = "[#{index + 1}/#{total}]"
      print "#{prefix} Generating... #{task.name}"
      tips = TaskInsightsService.new(task).call

      if tips.any?
        task.update!(expert_tips: tips)
        linked = tips.count { |t| t["resource_url"].present? }
        puts " → ✓ #{tips.length} tips saved (#{linked} with a link)"
      else
        puts " → ✗ API returned empty, kept the existing #{task.expert_tips.length} tips"
      end

      sleep(0.5) unless index == total - 1
    end

    puts "\n✅ Done.\n\n"
  end

  desc "Clear all expert tips (useful for regenerating from scratch)"
  task clear_expert_tips: :environment do
    count = Task.where.not(expert_tips: []).count
    Task.update_all(expert_tips: [])
    puts "✓ Cleared expert tips from #{count} tasks."
  end
end
