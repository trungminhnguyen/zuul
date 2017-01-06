## Required enviroment variables
# GERRIT_USER
# GERRIT_REPO
# GERRIT_HOST
# GERRIT_PORT
# GERRIT_EMAIL

## Assumptions
# there's a repository GERRIT_REPO
# zuul is configured to run a check pipeline with some job(s) on GERRIT_REPO
# zuul is configured to run a gate pipeline with some job(s) on GERRIT_REPO

require 'rubygems'

require 'fileutils'
require 'json'
require 'rspec'
require 'timeout'
require 'English'

require_relative 'env_config'
require_relative 'git_repo'

ZUUL_USER = 'qa-zuul'.freeze
CHECK_APPROVAL_TYPE = 'Verified'.freeze

describe 'Gerrit change' do
  before(:all) do
    @config = EnvConfig.new %w(GERRIT_HOST GERRIT_PORT GERRIT_USER GERRIT_REPO
                               GERRIT_EMAIL)
  end

  it 'runs check and gate pipelines' do
    gerrit = Gerrit.new(@config.host, @config.port, @config.user)
    puts "Cloning the repository: #{@config.repo}"
    git_repo = GitRepo.new(@config.host, @config.port, @config.user,
                           @config.repo, @config.email)

    puts 'Creating new gerrit change'
    change_number = git_repo.create_testing_gerrit_change
    puts "Created new gerrit change: https://#{@config.host}/#{change_number}"

    puts 'Checking the status from the check pipeline'
    check_status = gerrit.verified_change_status(change_number)
    expect(check_status).to eq('1')

    # Add a 'merge' label to the gerrit change
    puts 'Adding a Merge label'
    gerrit.add_label('Merge=+1', change_number)

    # verify the change is submitted
    puts 'Checking the change is submitted'
    change_submitted = gerrit.wait_change_submitted(change_number)
    expect(change_submitted).to be(true)
    puts 'Checking the status from the gate pipeline'
    gate_status = gerrit.verified_change_status(change_number)
    expect(gate_status).to eq('1')
  end
end

# Class for accessing the gerrit
class Gerrit
  def initialize(host, port, user)
    @user = user
    @host = host
    @port = port
  end

  def wait_change_submitted(change_number, timeout = 30)
    poll_interval = 3
    loop do
      change = query_single_change(change_number)
      change_merged = change['status'] == 'MERGED'
      return change_merged if change_merged || timeout < 0
      sleep(poll_interval)
      timeout -= poll_interval
    end
  end

  def verified_change_status(change_number, timeout = 300)
    poll_interval = 10
    loop do
      zuul_verified = verified_labels_by_zuul(change_number)
      return latest_approval(zuul_verified)['value'] unless zuul_verified.empty?
      return nil if timeout < 0
      sleep(poll_interval)
      timeout -= poll_interval
      poll_interval += 10 if poll_interval <= 60
    end
  end

  def verified_labels_by_zuul(change_number)
    approvals = latest_patchset_approvals(change_number)
    approval_type_by(approvals, CHECK_APPROVAL_TYPE, ZUUL_USER)
  end

  def query_single_change(change_number)
    query_result = gerrit_cmd(
      "query --format=JSON --current-patch-set #{change_number}"
    )
    return [] if query_result.lines.count < 2
    JSON.parse(query_result.lines[0])
  end

  def add_label(label, change_number)
    gerrit_cmd("review --label '#{label}' #{change_number},1")
  end

  def gerrit_cmd(cmd)
    `ssh #{@user}@#{@host} -p #{@port} gerrit #{cmd}`
  end

  def latest_patchset_approvals(change_number)
    change = query_single_change(change_number)
    patchset = change['currentPatchSet']
    return [] unless patchset.key?('approvals')
    patchset['approvals']
  end

  # Sort the approvals based on the 'grantedOn' field and return the last one
  # Single approval looks like this:
  # {
  #   "type": "Verified",
  #   "description": "Verified",
  #   "value": "1",
  #   "grantedOn": 1480933377,
  #   "by": {
  #     "name": "qa-zuul",
  #     "username": "qa-zuul"
  #   }
  # }
  def latest_approval(approvals)
    approvals.sort { |a, b| a['grantedOn'] <=> b['grantedOn'] } [-1]
  end

  def approval_type_by(approvals, type, by_username)
    approvals.select do |approval|
      approval['by']['username'] == by_username &&
        approval['type'] == type
    end
  end

  private :query_single_change, :gerrit_cmd, :latest_approval
end
