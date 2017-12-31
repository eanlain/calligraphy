#!/usr/bin/env rake
# frozen_string_literal: true

require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %w[spec litmus:run]

desc 'Run rspec tests'
RSpec::Core::RakeTask.new :spec

desc 'Run litmus test suite'
task litmus: %w[litmus:run]

desc 'Run Rubocop'
RuboCop::RakeTask.new :rubocop

namespace :litmus do
  tmp_dir = "#{Dir.pwd}/tmp"
  litmus_archive = "#{tmp_dir}/litmus-0.13.tar.gz"

  desc 'Fetch litmus test suite zip file'
  task :fetch do
    sh 'mkdir tmp' unless File.directory? tmp_dir.to_s
    sh 'mkdir tmp/webdav' unless File.directory? "#{tmp_dir}/webdav"

    unless File.exist? litmus_archive
      litmus_url = 'https://github.com/eanlain/litmus/releases/download/v0.13/litmus-0.13.tar.gz'
      sh "wget -O #{tmp_dir}/litmus-0.13.tar.gz #{litmus_url}"
    end
  end
  CLEAN.include('tmp')

  desc 'Unarchive litmus test suite zip file'
  task unarchive: :fetch do
    unless File.directory? "#{Dir.pwd}/litmus-0.13"
      sh "tar -xvzf #{tmp_dir}/litmus-0.13.tar.gz"
    end
  end
  CLEAN.include('litmus-0.13')

  desc 'Configure litmus test suite'
  task configure: :unarchive do
    unless File.exist? 'litmus-0.13/configured'
      sh 'cd litmus-0.13 && ./configure'
      sh 'cd litmus-0.13 && touch configured'
    end
  end

  desc "'make clean' litmus test suite"
  task :make_clean do
    sh 'cd litmus-0.13 && make clean'
    sh 'rm litmus-0.13/configured'
  end

  desc 'Run litmus test suite'
  task run: :configure do
    sh 'cd spec/dummy/ && rails server -d'
    sleep 1
    puma_pid = `cat spec/dummy/tmp/pids/server.pid`
    exit_code = 0

    begin
      sh 'cd litmus-0.13 &&'\
        ' make URL=http://localhost:3000/webdav/'\
        ' CREDS=\'jon_deaux changeme!\' check'
    rescue StandardError
      exit_code = 1
      puts '!!!!! Failure encountered during litmus test suite !!!!!'
    end

    sh "kill #{puma_pid}"
    exit exit_code
  end
end
