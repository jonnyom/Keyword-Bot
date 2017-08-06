require 'intercom'
@count = 0

my_token = 'dG9rOjMzYmFiNTVlX2I5NzJfNDRkMF84ZWUzX2M2ZTNhNzA2ZGUzZjoxOjA='
@intercom = Intercom::Client.new(token: my_token)

puts "Enter the limit for the inbox"
@limit = $stdin.gets.chomp.to_i
@count = 0

def get_conversations
	open_convos = @intercom.conversations.find_all(open: true, read: false, assignee: "nobody_admin")
	@count = open_convos.count
end

def check_unassigned
	get_conversations
	if @count >= @limit
		return true
	else
		return false
	end
end

def is_full
	if check_unassigned
		@slack.post "The inbox is too full with a count of: " + @count.to_s
	end
end