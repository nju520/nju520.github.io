#############################################################################
#
# Modified version of jekyllrb Rakefile
# https://github.com/jekyll/jekyll/blob/master/Rakefile
#
#############################################################################

require 'rake'
require 'date'
require 'yaml'

CONFIG = YAML.load(File.read('_config.yml'))
USERNAME = CONFIG["username"]
REPO = CONFIG["repo"]
SOURCE_BRANCH = CONFIG["branch"]
DESTINATION_BRANCH = "master"

def push(message, branch)
  # check if there is anything to add and commit, and pushes it
  sh "if [ -n '$(git status)' ]; then
        git add --all .;
        git commit -m '#{message}';
        git push origin #{branch};
     fi"
  puts "Pushed updated branch #{branch} to GitHub Pages"
end

namespace :site do
  desc "Generate the site"
  task :build do
    sh "bundle exec jekyll build"
  end

  desc "Generate the site and serve locally"
  task :serve do
    sh "bundle exec jekyll serve"
  end

  desc "Generate the site, serve locally and watch for changes"
  task :watch do
    sh "bundle exec jekyll serve --watch"
  end

  desc "Generate the site and push changes to remote origin"
  task :deploy, :message do |t, args|

    # Commit and push to GitHub for source branch
    sh "git checkout #{SOURCE_BRANCH}"

    push(args.message, SOURCE_BRANCH)

    # Generate the site
    sh "bundle exec jekyll build"

    # Commit and push to github
    # Dir.chdir("#{Dir.pwd}/#{CONFIG["destination"]}") { sh "git checkout #{DESTINATION_BRANCH}" }
    sh "cd #{Dir.pwd}/#{CONFIG["destination"]}"
    sh "git checkout #{DESTINATION_BRANCH}"
    push(args.message, DESTINATION_BRANCH)
  end
end
