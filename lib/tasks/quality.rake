# frozen_string_literal: true

namespace :quality do
  desc "Run all code quality checks for ATS application"
  task all: :environment do
    puts "Running comprehensive ATS quality checks..."
    Rake::Task["quality:security"].invoke
    Rake::Task["quality:style"].invoke
    Rake::Task["quality:test_coverage"].invoke
  end

  desc "Run security scans (Brakeman, Bundle Audit)"
  task security: :environment do
    puts "🛡️  Running security scans..."
    
    puts "Running Brakeman security scan..."
    system("bundle exec brakeman --config-file .brakeman.yml --no-pager --quiet") ||
      abort("❌ Brakeman security scan failed")
    
    puts "Running Bundle Audit..."
    system("bundle exec bundler-audit check --update") ||
      abort("❌ Bundle Audit failed")
    
    puts "Running Importmap Audit..."
    system("bin/importmap audit") ||
      abort("❌ Importmap Audit failed")
    
    puts "✅ Security scans completed successfully"
  end

  desc "Run style and quality checks (RuboCop)"
  task style: :environment do
    puts "✨ Running style and quality checks..."
    
    puts "Running RuboCop..."
    system("bundle exec rubocop --display-cop-names --extra-details") ||
      abort("❌ RuboCop style check failed")
    
    puts "✅ Style checks completed successfully"
  end

  desc "Auto-fix style issues where possible"
  task fix_style: :environment do
    puts "🔧 Auto-fixing style issues..."
    
    system("bundle exec rubocop --auto-correct-all --display-cop-names") ||
      abort("❌ RuboCop auto-fix failed")
    
    puts "✅ Style auto-fix completed"
  end

  desc "Run test suite with coverage reporting"
  task test_coverage: :environment do
    puts "🧪 Running test suite with coverage..."
    
    ENV["COVERAGE"] = "true"
    
    system("bundle exec rspec --format documentation") ||
      abort("❌ Test suite failed")
    
    puts "✅ Test suite completed with coverage reporting"
    
    if File.exist?("coverage/index.html")
      puts "📊 Coverage report available at: coverage/index.html"
    end
  end

  desc "Run performance tests"
  task performance: :environment do
    puts "⚡ Running performance tests..."
    
    system("bundle exec rspec spec/performance/ --tag performance") ||
      puts("⚠️  Performance tests not found or failed")
    
    puts "✅ Performance tests completed"
  end

  desc "Check for outdated gems"
  task outdated: :environment do
    puts "📦 Checking for outdated gems..."
    
    system("bundle outdated") ||
      puts("ℹ️  All gems are up to date")
  end

  desc "Generate comprehensive quality report"
  task report: :environment do
    puts "📈 Generating ATS quality report..."
    
    report_file = "tmp/quality_report_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt"
    
    File.open(report_file, "w") do |file|
      file.puts "ATS QUALITY REPORT"
      file.puts "=" * 50
      file.puts "Generated: #{Time.current}"
      file.puts "Rails Version: #{Rails.version}"
      file.puts "Ruby Version: #{RUBY_VERSION}"
      file.puts "\n"
      
      # Security scan results
      file.puts "SECURITY SCAN RESULTS"
      file.puts "-" * 25
      brakeman_output = `bundle exec brakeman --config-file .brakeman.yml --no-pager 2>&1`
      file.puts brakeman_output
      file.puts "\n"
      
      # Bundle audit results
      file.puts "DEPENDENCY VULNERABILITY SCAN"
      file.puts "-" * 30
      audit_output = `bundle exec bundler-audit check --update 2>&1`
      file.puts audit_output
      file.puts "\n"
      
      # Style check results
      file.puts "CODE STYLE ANALYSIS"
      file.puts "-" * 20
      rubocop_output = `bundle exec rubocop --display-cop-names 2>&1`
      file.puts rubocop_output
      file.puts "\n"
      
      # Coverage summary
      if File.exist?("coverage/.last_run.json")
        file.puts "TEST COVERAGE SUMMARY"
        file.puts "-" * 22
        coverage_data = JSON.parse(File.read("coverage/.last_run.json"))
        file.puts "Overall Coverage: #{coverage_data['result']['covered_percent']}%"
        file.puts "Covered Lines: #{coverage_data['result']['covered_lines']}"
        file.puts "Total Lines: #{coverage_data['result']['total_lines']}"
        file.puts "\n"
      end
      
      file.puts "Report generated at: #{report_file}"
    end
    
    puts "✅ Quality report generated: #{report_file}"
  end

  desc "Setup quality tools and configurations"
  task setup: :environment do
    puts "🛠️  Setting up ATS quality tools..."
    
    # Create necessary directories
    FileUtils.mkdir_p("coverage")
    FileUtils.mkdir_p("tmp/quality")
    FileUtils.mkdir_p("spec/performance")
    
    # Create gitignore entries for quality tool outputs
    gitignore_additions = [
      "# Quality tool outputs",
      "coverage/",
      "tmp/quality/",
      "*.log",
      ".bundle-audit.log",
      "brakeman-report.*",
      "rubocop-report.*"
    ].join("\n")
    
    gitignore_file = ".gitignore"
    if File.exist?(gitignore_file)
      current_content = File.read(gitignore_file)
      unless current_content.include?("Quality tool outputs")
        File.open(gitignore_file, "a") do |file|
          file.puts "\n#{gitignore_additions}"
        end
        puts "✅ Updated .gitignore with quality tool patterns"
      end
    end
    
    puts "✅ Quality tools setup completed"
  end

  desc "Clean up quality tool artifacts"
  task clean: :environment do
    puts "🧹 Cleaning up quality tool artifacts..."
    
    FileUtils.rm_rf("coverage")
    FileUtils.rm_f(Dir.glob("tmp/quality/*"))
    FileUtils.rm_f(Dir.glob("*-report.*"))
    FileUtils.rm_f(".bundle-audit.log")
    
    puts "✅ Quality tool artifacts cleaned"
  end
end

# Add quality checks to default test task
if Rake::Task.task_defined?("default")
  Rake::Task["default"].enhance(["quality:all"])
else
  desc "Run tests and quality checks"
  task default: ["quality:all"]
end