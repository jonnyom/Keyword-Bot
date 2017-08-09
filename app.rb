require 'intercom'
require 'slack/incoming/webhooks'
require 'sinatra'
require 'json'

URL = ENV['CHATBOT_SLACK_URL']
MY_TOKEN = ENV['MY_INTERCOM_TOKEN']
APP_ID = ENV['MY_INTERCOM_APP_ID']

def auth_intercom
  @intercom = Intercom::Client.new(token: MY_TOKEN)
end

def init_keywords
	@keywords = ["android", "ios"]
end

def auth_slack
	@slack = Slack::Incoming::Webhooks.new URL
end

def check_for_keyword(message)
	if @keywords.any? {|keyword| message.downcase.include?(keyword)}
		return true
	end
	return false
end

def get_conversation_info(convo_id)
	full_convo = @intercom.conversations.find(id: convo_id)

	convo_details = {
		# :updated_at => nil,
		:body => ""
	}

	convo_details[:body] = full_convo.conversation_message.body

	if !full_convo.conversation_parts.empty?
		puts "conversation_parts aren't empty"
		full_convo.conversation_parts.reverse_each do |convo_part|
			puts "Outputting test: #{convo_part.body}"
			if convo_part.part_type == "comment" && convo_part.author.instance_of?(Intercom::User)
		    	puts "Conversation part is recent and a comment from user."
		    	convo_details[:updated_at] = convo_part.created_at
		    	convo_details[:body] = convo_details[:body] + convo_part.body
		    else
	     		puts "Conversation part is recent, but not a reply from user."
    		end
  		end
  	else
  		puts "Conversation parts are empty"
	end

	convo_details[:body].slice!("<p>")
	convo_details[:body].slice!("</p>")

	convo_details
end

def conversation_link(conversation_id, message)
	message = "Conversation of interest: https://intercomrades.intercom.com/a/apps/#{APP_ID}/respond/inbox/conversation/#{conversation_id} \n Message: #{message}"
	message
end


post '/' do
	auth_intercom
	auth_slack
	init_keywords

	payload_body = request.body.read
	verify_signature(payload_body)
	payload = JSON.parse(payload_body)
	hook_topic = payload["topic"]
	hook_data = payload["data"]
	hook_message = hook_data['item']['conversation_message']

	if (hook_topic == "conversation.user.created")
		convo_id = hook_data["item"]["id"]
		full_convo = get_conversation_info(convo_id)
		message = full_convo[:body]
		puts message
		if check_for_keyword(message)
			puts "Match"
			output = conversation_link(convo_id, message)
			@slack.post output
		else
			puts "No match"
			break
		end
	end
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