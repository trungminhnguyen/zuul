## Required enviroment variables
# GITHUB_USER
# GITHUB_API_TOKEN
# GITHUB_REPO
# GITHUB_TARGET_BRANCH

## Assumptions
# there's a repository GITHUB_USER/GITHUB_REPO
# GITHUB_TARGET_BRANCH exists
# zuul is configured to run a check pipeline with some job(s)
#   on GITHUB_USER/GITHUB_REPO
# zuul is configured to run a gate pipeline with some job(s)
#   on GITHUB_USER/GITHUB_REPO

require 'rubygems'

require 'fileutils'
require 'octokit'
require 'rspec'
require 'timeout'

require_relative 'env_config'
require_relative 'git_repo'

describe 'Github pull request' do
  before(:all) do
    @config = EnvConfig.new %w(GITHUB_API_TOKEN GITHUB_USER GITHUB_REPO
                               GITHUB_TARGET_BRANCH)
  end

  it 'runs check and gate pipelines' do
    repo_fqn = "#{@config.user}/#{@config.repo}"

    puts "Cloning the repository #{repo_fqn}"
    git_repo = GitRepo.new('github.com', '22', 'git', repo_fqn)
    test_branch = git_repo.create_test_branch(@config.target_branch)
    git_repo.create_test_commit

    # push and create a pull request
    puts 'Creating pull request'
    git_repo.git.push('origin', test_branch, force: true)
    github = Octokit::Client.new(access_token: @config.api_token)
    pull = github.create_pull_request(repo_fqn, @config.target_branch,
                                      test_branch, 'Testing PR')
    puts "Created pull request #{pull.html_url}"

    # poll on the pull request commit status named 'check'
    puts 'Waiting for check status'
    check_status = wait_successful_pr_status(github, repo_fqn, pull, 'check')
    expect(check_status).to eq('success')

    # Add a 'merge' label to the pull request
    puts 'Adding a merge label'
    github.add_labels_to_an_issue(repo_fqn, pull.number, ['merge'])

    # poll on the pull request commit status named 'gate'
    puts 'Waiting for gate status'
    gate_status = wait_successful_pr_status(github, repo_fqn, pull, 'gate')
    expect(gate_status).to eq('success')

    # # verify the PR is merged
    puts 'Checking the PR merged state'
    pr_merged = wait_pr_merged(github, repo_fqn, pull)
    expect(pr_merged).to be(true)
  end
end

def wait_pr_merged(github, repo, pull, timeout = 30)
  poll_interval = 3
  loop do
    pull = github.pull_request(repo, pull.number)
    return pull.merged if pull.merged || timeout < 0
    sleep(poll_interval)
    timeout -= poll_interval
  end
end

def wait_successful_pr_status(github, repo, pull, status_name, timeout = 300)
  poll_interval = 10
  loop do
    status = latest_commit_status(github, repo, pull.head.sha, status_name)
    return status if status == 'success' || timeout < 0
    sleep(poll_interval)
    timeout -= poll_interval
    poll_interval += 10 if poll_interval <= 60
  end
end

def latest_commit_status(github, repo, sha, status_name)
  statuses = github.statuses(repo, sha)
  target_statuses = statuses.select do |status|
    status[:context] == status_name
  end
  return nil if target_statuses.empty?
  target_statuses[0][:state]
end
