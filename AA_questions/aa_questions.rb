require 'sqlite3'
require 'singleton'


# SQLite3::Database.new( "questions.db" ) do |db|
#   db.execute( "select * from table" ) do |row|
#     p row
#   end
# end

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end


class User 
  attr_accessor :fname, :lname
  
  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil unless user.length > 0

    User.new(user.first)
  end 
  
  def self.find_by_name(fname, lname)
    users = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        userssql
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless users.length > 0

    users.map { |user| User.new(user) }
  end 
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end 
  
  def authored_questions 
    Question.find_by_author_id(@id)
  end 
  
  def authored_replies 
    Reply.find_by_user_id(@id)
  end 
  
end

class Question 
  attr_accessor :title, :body, :author_id
  
  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil unless question.length > 0

    Question.new(question.first)
  end 
  
  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def initialize(options) 
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end 
  
  def author
    User.find_by_id(@author_id)
  end 
  
  def replies 
    Reply.find_by_question_id(@id)
  end 
  
end 

class Reply 
  attr_accessor :body, :question_id, :parent_reply_id, :user_id
  
  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil unless reply.length > 0

    Reply.new(reply.first)
  end 
  
  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end 
  
  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end 
  
  def initialize(options) 
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @user_id = options['user_id']
  end 
  
  def author 
    User.find_by_id(@user_id)
  end 
  
  def question 
    Question.find_by_id(@question_id)
  end 
  
  def parent_reply 
    Reply.find_by_id(@parent_reply_id)
  end 
  
  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end 
  
end 

class Follow 
  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end 
end 

class Like 
  def initialize(options) 
    @user_id = options['user_id']
    @question_id = options['question_id']
  end 
end 
