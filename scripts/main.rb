require 'github_api'
require 'json'

login = JSON.parse(File.open("scripts/config.json").read)

github = Github.new login: login["USERNAME"], password: login["PASSWORD"]

def issues_json(github, user, repo)
  issues = []
  page = 1
  loop do
    new_issues = github.issues.list user: user, repo: repo, per_page: 100, page: page
    issues.concat new_issues
    if new_issues.size == 100
      page += 1
    else
      break
    end
  end

  return JSON.pretty_generate(issues)
end

Dir["projects/*"].each do |filepath|
  project = JSON.parse File.open(filepath).read
  project_name = File.basename(filepath, '.json')

  repo = project["repo"]
  repo.gsub! "http://", ""
  repo.gsub! "https://", ""

  if repo.split('/').length == 2
    _, user = repo.split('/')
    page = 1

    loop do
      repos = github.repos.list user: user, per_page: 100, page: page

      repos.map { |r| r.name }.each do |rn|
        `curl -o data/#{project_name}/#{rn}/g0v.json --create-dirs -f https://raw.github.com/#{user}/#{rn}/master/g0v.json`
        begin
          File.open "data/#{project_name}/#{rn}/issues.json", 'w' do |f|
            f.print issues_json(github, user, rn)
          end
        rescue Exception => e
          puts e
        end
      end
      if repos.length == 100
        page += 1
      else
        break
      end
    end

  elsif repo.split('/').length == 3
    _, user, repo = repo.split('/')

    `curl -o data/#{project_name}/#{repo}/g0v.json --create-dirs -f https://raw.github.com/#{user}/#{repo}/master/g0v.json`
    begin
      File.open "data/#{project_name}/#{repo}/issues.json", 'w' do |f|
        f.print issues_json(github, user, repo)
      end
    rescue Exception => e
      puts e
    end
  end
end

