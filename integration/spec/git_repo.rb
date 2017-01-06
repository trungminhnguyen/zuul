require 'git'

# Class for manipulating git repository
class GitRepo
  def initialize(host, port, user, repo, email = nil)
    @git = clone_repo(host, port, user, repo)
    @git.config('user.email', email) unless email.nil?
    @git_dir = @git.dir.path
  end

  attr_reader :git

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

  def create_test_branch(target_branch)
    rand_string = rand(36**6).to_s(36)
    test_branch = "test_#{rand_string}"
    @git.branch(test_branch).checkout
    @git.reset_hard("origin/#{target_branch}")
    test_branch
  end

  def parse_change_number(string)
    string.lines.grep(%r{^remote: *\S+/(\d+) +.*}) \
      { Regexp.last_match(1) } [0]
  end

  private :clone_repo, :parse_change_number
end
