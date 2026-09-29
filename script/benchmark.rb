require 'benchmark'

session = ActionDispatch::Integration::Session.new(Rails.application)
session.host! 'localhost'
session.get '/api/session'
token = session.response.parsed_body.fetch('csrf_token')
session.post '/api/session', params: { email: ENV.fetch('ADMIN_EMAIL', 'hr@acme.example'), password: ENV.fetch('ADMIN_PASSWORD', 'AcmeDemo2026!') }, headers: { 'X-CSRF-Token' => token }, as: :json
raise 'Sign-in failed' unless session.response.successful?
puts "Dataset: #{Employee.count} employees, #{Compensation.count} compensation versions"
[ '/api/employees?page=1', '/api/employees?page=400', '/api/employees?q=Aarav', '/api/reports?as_of=2026-09-27' ].each do |path|
  session.get path # Warmup
  durations = Array.new(20) do
    milliseconds = Benchmark.realtime { session.get path } * 1000
    raise "Request failed: #{path}" unless session.response.successful?
    milliseconds
  end.sort
  puts "#{path}: median=#{durations[10].round(1)}ms p95=#{durations[18].round(1)}ms (20 sequential requests)"
end
