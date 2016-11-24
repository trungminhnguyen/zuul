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
require 'git'
require 'octokit'
require 'rspec'
require 'timeout'

describe 'Github pull request' do
  before(:all) do
    required_vars = %w(GITHUB_API_TOKEN GITHUB_USER GITHUB_REPO
                       GITHUB_TARGET_BRANCH)
    missing_vars = required_vars.select do |var|
      ENV[var].nil?
    end
    unless missing_vars.empty?
      fail("Undefined variables: #{missing_vars.join(' ')}")
    end
    @api_token = ENV['GITHUB_API_TOKEN']
    @user = ENV['GITHUB_USER']
    @repo = ENV['GITHUB_REPO']
    @target_branch = ENV['GITHUB_TARGET_BRANCH']
  end

  it 'runs check and gate pipelines' do
    repo_fqn = "#{@user}/#{@repo}"
    rand_string = rand(36**6).to_s(36)
    test_branch = "test_#{rand_string}"

    # clone the repo
    FileUtils.rm_rf @repo
    git = Git.clone("ssh://git@github.com/#{@user}/#{@repo}.git", @repo)

    # create new branch based on target branch
    git.branch(test_branch).checkout
    git.reset_hard("origin/#{@target_branch}")

    # add new content and commit
    new_file = File.join(git.dir.path, 'test.txt')
    File.open(new_file, 'w') { |f| f.write(rand_string) }
    git.add(new_file)
    commit_msg = "Add content to test.txt - #{rand_string}"
    git.commit(commit_msg)

    # push and create a pull request
    git.push('origin', test_branch, force: true)
    github = Octokit::Client.new(access_token: @api_token)
    pull = github.create_pull_request(repo_fqn, @target_branch, test_branch,
                                      commit_msg)

    puts "opening pull request #{pull.html_url}"

    # poll on the pull request commit status named 'check'
    puts 'waiting for check status'
    check_status = wait_successful_pr_status(github, repo_fqn, pull, 'check')
    expect(check_status).to eq('success')

    # Add a 'merge' label to the pull request
    puts 'adding a merge label'
    github.add_labels_to_an_issue(repo_fqn, pull.number, ['merge'])

    # # poll on the pull request commit status named 'gate'
    puts 'waiting for gate status'
    gate_status = wait_successful_pr_status(github, repo_fqn, pull, 'gate')
    expect(gate_status).to eq('success')

    # # verify the PR is merged
    puts 'checking the PR merged state'
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
