require File.expand_path('../spec_helper', __FILE__)
require 'webmock/rspec'

describe JenkinsPipelineBuilder::PullRequestGenerator do
  let(:pull_request_generator) { JenkinsPipelineBuilder::PullRequestGenerator }
  let(:project) { { name: 'pull_req_test', type: :project, value: { name: 'pull_req_test', jobs: ['{{name}}-00', '{{name}}-10', '{{name}}-11'] } } }
  let(:jobs) { { '{{name}}-10' => { name: '{{name}}-10', type: :'job-template', value: { name: '{{name}}-10', description: '{{description}}', publishers: [{ downstream: { project: '{{job@{{name}}-11}}' } }] }  }, '{{name}}-11' => { name: '{{name}}-11', type: :'job-template', value: { name: '{{name}}-11', description: '{{description}}' } } } }
  let(:create_jobs) { [{ name: 'pull_req_test-PR5', type: :project, value: { name: 'pull_req_test-PR5', jobs: ['{{name}}-10', '{{name}}-11'] } }, { name: 'pull_req_test-PR6', type: :project, value: { name: 'pull_req_test-PR6', jobs: ['{{name}}-10', '{{name}}-11'] } }] }
  let(:pull_request) { { name: '{{name}}-00', type: :job, name: '{{name}}-00', job_type: 'pull_request_generator', git_url: 'https://www.github.com/', git_repo: 'jenkins_pipeline_builder', git_org: 'constantcontact', jobs: ['{{name}}-10', '{{name}}-11'], builders: [{ shell_command: 'generate -v || gem install jenkins_pipeline_builder\ngenerate pipeline -c config/{{login_config}} pull_request pipeline/ {{name}}\n' }] } }
  before do
    # Request to get current pull requests from github
    stub_request(:any, 'https://www.github.com/api/v3/repos/constantcontact/jenkins_pipeline_builder/pulls').to_return(body: '[{"number": 5,"state": "open","title": "Update README again" },{"number": 6,"state": "open",  "title": "Update README again2"}]')
    stub_request(:any, 'http://username:password@127.0.0.1:8080/api/json').to_return(body: '{"assignedLabels":[{}],"mode":"NORMAL","nodeDescription":"the master Jenkins node","nodeName":"","numExecutors":2,"description":null,"jobs":[{"name":"PurgeTest-PR1","url":"http://localhost:8080/job/PurgeTest-PR1/","color":"notbuilt" },{"name":"PurgeTest-PR3","url":"http://localhost:8080/job/PurgeTest-PR3/","color":"notbuilt" },{"name":"PurgeTest-PR4","url":"http://localhost:8080/job/PurgeTest-PR4/","color":"notbuilt"}],"overallLoad":{},"primaryView":{"name":"All","url":"http://localhost:8080/" },"quietingDown":false,"slaveAgentPort":0,"unlabeledLoad":{},"useCrumbs":false,"useSecurity":true,"views":[{"name":"All","url":"http://localhost:8080/"}]}')
  end
  describe '#initialize' do
    after(:all) do
      FileUtils.rm_r 'pull_requests.csv'
    end
    it 'can work without a csv' do
      pull = pull_request_generator.new(project, jobs, pull_request)
      expect(pull.purge.count).to eq(0)
      expect(pull.create).to eq(create_jobs)
    end
    it 'can work with a csv' do
      pull = pull_request_generator.new(project, jobs, pull_request)
      expect(pull.purge.count).to eq(0)
      expect(pull.create).to eq(create_jobs)
    end
  end
end

describe JenkinsPipelineBuilder::PullRequest do
  let(:pull_request_class) { JenkinsPipelineBuilder::PullRequest }
  let(:project) { { name: 'pull_req_test', type: :project, value: { name: 'pull_req_test', jobs: ['{{name}}-00', '{{name}}-10', '{{name}}-11'] } } }
  let(:pull_request) { { name: '{{name}}-00', type: :job, name: '{{name}}-00', job_type: 'pull_request_generator', git_url: 'https://www.github.com/', git_repo: 'jenkins_pipeline_builder', git_org: 'constantcontact', jobs: ['{{name}}-10', '{{name}}-11'], builders: [{ shell_command: 'generate -v || gem install jenkins_pipeline_builder\ngenerate pipeline -c config/{{login_config}} pull_request pipeline/ {{name}}\n' }] } }
  let(:jobs) { { '{{name}}-10' => { name: '{{name}}-10', type: :'job-template', value: { name: '{{name}}-10', description: '{{description}}', publishers: [{ downstream: { project: '{{job@{{name}}-11}}' } }] }  }, '{{name}}-11' => { name: '{{name}}-11', type: :'job-template', value: { name: '{{name}}-11', description: '{{description}}' } } } }
  describe '#initialize' do
    it 'process pull_request' do
      pull = pull_request_class.new(project, 2, jobs, pull_request)
      post_jobs = { '{{name}}-10' => { name: '{{name}}-10', type: :'job-template', value: { name: '{{name}}-10', description: '{{description}}', publishers: [{ downstream: { project: '{{job@{{name}}-11}}' } }], scm_branch: 'origin/pr/2/head', scm_params: { refspec: 'refs/pull/*:refs/remotes/origin/pr/*' } } }, '{{name}}-11' => { name: '{{name}}-11', type: :'job-template', value: { name: '{{name}}-11', description: '{{description}}', scm_branch: 'origin/pr/2/head', scm_params: { refspec: 'refs/pull/*:refs/remotes/origin/pr/*' } } } }
      post_project = { name: 'pull_req_test-PR2', type: :project, value: { name: 'pull_req_test-PR2', jobs: ['{{name}}-00', '{{name}}-10', '{{name}}-11'] } }

      expect(pull.project).to eq(post_project)
      expect(pull.jobs).to eq(post_jobs)
    end
  end
end
