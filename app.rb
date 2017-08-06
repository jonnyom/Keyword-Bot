require 'intercom'
require 'slack/incoming/webhooks'
require 'sinatra'
require 'json'

url = ENV['CHATBOT_SLACK_URL']

@slack = Slack::Incoming::Webhooks.new url

my_token = ENV['MY_INTERCOM_TOKEN']
@intercom = Intercom::Client.new(token: my_token)

@keywords = ["android", "ios"]

def check_incoming_messages(conversation_parts)
	conversation_parts.each do |part|
		if @keywords.any? {|keyword| part.body.include?(keyword)}
			return true
		else
			next
		end
	end
	return false
end

post '/' do
	request.body.rewind
  payload_body = request.body.read
  puts "==============================================================="
  puts payload_body
  puts "==============================================================="
  verify_signature(payload_body)
  push = JSON.parse(payload_body)
  puts "Topic Recieved: #{push['topic']}"
	# request.body.rewind
	# payload_body = request.body.read
	# verify_signature(payload_body)
	# body = JSON.parse(payload_body)
	# conversation_parts = body['data']['conversation_parts']['conversation_parts']
	# if check_incoming_messages(conversation_parts)
	# 	@slack.post "Conversation of interest: #{body['links']['conversation_web']}"
	# else
	# 	break
	# end
end


def verify_signature(payload_body)
  secret = "secret"
  expected = request.env['HTTP_X_HUB_SIGNATURE']
  if expected.nil? || expected.empty? then
    puts "Not signed. Not calculating"
  else
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), secret, payload_body)
    puts "Expected  : #{expected}"
    puts "Calculated: #{signature}"
    if Rack::Utils.secure_compare(signature, expected) then
      puts "   Match"
    else
      puts "   MISMATCH!!!!!!!"
      return halt 500, "Signatures didn't match!"
    end
  end
end