require "octokit"
require "pit"
require 'open-uri'


def fetch_gemfile(repo)
  open("https://raw.github.com/#{repo}/master/Gemfile") { |f| f.read }
end

def gems(gemfile)
  gemfile.scan(/^\s*gem\s*['"]([^'"]+)['"]/m)
end

def search_repos(q)
  page = 1
  @client = Octokit::Client.new(access_token: @access_token)
  Enumerator.new do |y|
    begin
      repos = @client.search_repos(q, {sort: 'stars', order: 'desc', page: page})
      repos.items.each do |n|
        y << n
      end
      page += 1
    end while true
  end
end

STDOUT.sync = true
@access_token = Pit.get('github', require: {"access_token" => "access token"})['access_token']

search_repos('language:ruby').each do |repo|
  begin
    gemfile = fetch_gemfile(repo.full_name)
    gems = gems(gemfile)
    puts gems.join(',') unless gems.empty?
  rescue => e
    STDERR.puts e.inspect
    STDERR.puts e.message
  end
  sleep 0.1
end
