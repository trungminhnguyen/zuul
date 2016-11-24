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
require 'git'
require 'json'
require 'rspec'
require 'timeout'
require 'English'

ZUUL_USER = 'qa-zuul'.freeze
CHECK_APPROVAL_TYPE = 'Verified'.freeze

describe 'Gerrit change' do
  before(:all) do
    @config = Config.new
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

# Class holding the environment configuration
class Config
  ENV_VARS = %w(GERRIT_HOST GERRIT_PORT GERRIT_USER GERRIT_REPO
                GERRIT_EMAIL).freeze

  def initialize
    config = get_required_variables(ENV_VARS)
    config.each do |var_name, var_value|
      self.class.send(:define_method, var_name) do
        var_value
      end
    end
  end

  def get_required_variables(vars)
    missing_vars = vars.select do |var|
      ENV[var].nil?
    end
    raise("Undefined variables: #{missing_vars.join(' ')}") \
      unless missing_vars.empty?

    vars.each_with_object({}) do |var, vars_hash|
      vars_hash[var.sub(/^GERRIT_/, '').downcase] = ENV[var]
    end
  end

  private :get_required_variables
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

# Class for manipulating git repository
class GitRepo
  def initialize(host, port, user, repo, email)
    @git = clone_repo(host, port, user, repo)
    @git.config('user.email', email)
    @git_dir = @git.dir.path
  end

  def clone_repo(host, port, user, repo)
    FileUtils.rm_rf repo
    Git.clone("ssh://#{user}@#{host}:#{port}/#{repo}", repo)
  end

  def create_test_commit
    rand_string = rand(36**6).to_s(36)
    new_file = File.join(@git_dir, 'test.txt')
    File.open(new_file, 'w') { |f| f.write(rand_string) }
    @git.add(new_file)
    commit_msg = "Add content to test.txt - #{rand_string}"
    @git.commit(commit_msg)
  end

  def create_testing_gerrit_change
    create_test_commit
    output = ''
    Dir.chdir(@git_dir) do
      output = `git push origin HEAD:refs/for/master 2>&1`
    end
    raise("Creating gerrit change failed:\n" + output) \
      if $CHILD_STATUS.exitstatus.nonzero?
    parse_change_number(output)
  end

  def parse_change_number(string)
    string.lines.grep(%r{^remote: *\S+/(\d+) +.*}) \
      { Regexp.last_match(1) } [0]
  end

  private :clone_repo, :parse_change_number
end
