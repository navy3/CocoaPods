require File.expand_path('../../../spec_helper', __FILE__)


describe Pod::Command::Setup do
  extend SpecHelper::Command
  extend SpecHelper::TemporaryDirectory
  extend SpecHelper::TemporaryRepos

  before do
    config.repos_dir = SpecHelper.tmp_repos_path
  end

  it "returns the read only URL of the `master` spec-repo" do
    cmd = Pod::Command::Setup.new(argv)
    cmd.url.should == 'https://github.com/CocoaPods/Specs.git'
  end

  it "returns the push URL of the `master' spec-repo" do
    config.silent = true
    cmd = Pod::Command::Setup.new(argv('--push'))
    cmd.url.should == 'git@github.com:CocoaPods/Specs.git'
  end

  before do
    set_up_test_repo
    Pod::Command::Setup.any_instance.stubs(:read_only_url).returns(test_repo_path.to_s)
    config.repos_dir = SpecHelper.temporary_directory
  end

  it "runs with correct parameters" do
    lambda { run_command('setup') }.should.not.raise
  end

  it "complains for wrong parameters" do
    lambda { run_command('setup', 'wrong') }.should.raise Pod::Command::Help
    lambda { run_command('setup', '--wrong') }.should.raise Pod::Command::Help
  end

  it "creates the local spec-repos directory and creates a clone of the `master' repo" do
    output = run_command('setup')
    output.should.include "Setup completed"
    output.should.not.include "push"
    url = Dir.chdir(config.repos_dir + 'master') { `git config --get remote.origin.url`.chomp }
    url.should == test_repo_path.to_s
  end

  it "preserves push access for the `master' repo" do
    output = run_command('setup')
    output.should.not.include "push"
    Dir.chdir(config.repos_dir + 'master') { `git remote set-url origin git@github.com:CocoaPods/Specs.git` }
    command('setup').url.should == 'git@github.com:CocoaPods/Specs.git'
  end

  it "can run if needed" do
    output = run_command('setup')
    output.should.include "Setup completed"
    Pod::UI.output = ''
    command('setup').run_if_needed
    Pod::UI.output.should == ''
  end
end
