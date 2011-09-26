# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'rspec'
require 'rspec/core/rake_task'

task :default => [:spec]

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  # Put spec opts in a file named .rspec in root
end

require 'jeweler'
# Fix for Jeweler to use stable branch
class Jeweler
  module Commands
    class ReleaseToGit
      def run
        unless clean_staging_area?
          system "git status"
          raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
        end
        repo.checkout('stable')
        repo.push('origin', 'stable')
        if release_not_tagged?
          output.puts "Tagging #{release_tag}"
          repo.add_tag(release_tag)
          output.puts "Pushing #{release_tag} to origin"
          repo.push('origin', release_tag)
        end
      end
    end
    class ReleaseGemspec
      def run
        unless clean_staging_area?
          system "git status"
          raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
        end
        repo.checkout('stable')
        regenerate_gemspec!
        commit_gemspec! if gemspec_changed?
        output.puts "Pushing stable to origin"
        repo.push('origin', 'stable')
      end
    end
  end
end

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "amee-analytics"
  gem.homepage = "http://github.com/AMEE/amee-analytics"
  gem.license = "MIT"
  gem.summary = %Q{Analytics module for use with AMEE AppKit}
  gem.description = %Q{Part of the AMEE AppKit, this gem provides the ability to do mathmatical operations over a set of calculations}
  gem.email = "help@amee.com"
  gem.authors = ["James Hetherington", "Andrew Berkeley", "James Smith", "George Palmer"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rcov/rcovtask'
desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

require 'rdoc/task'
RDoc::Task.new do |rd|
  rd.title = "AMEE Analytics"
  rd.rdoc_dir = 'doc'
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
end