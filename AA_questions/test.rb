load 'aa_questions.rb'
user = User.find_by_id(1)
question = user.authored_questions[0]
reply = user.authored_replies[0]