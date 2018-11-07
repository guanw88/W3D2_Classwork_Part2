require 'sqlite3'
require 'singleton'
require 'byebug'

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

class ModelBase 
  
  def self.get_table(class_name)
    class_name = class_name.to_s
  
    case class_name
    when "User"
      return "users"
    when "Question"
      return "questions"
    when "Reply"
      return "replies"
    end 
  end 
  
  def self.find_by_id(id)
    result = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.get_table(self)}
      WHERE
        id = ?;
    SQL
    return nil unless result.length > 0

    self.new(result.first)
  end 
  
  def self.all
    result = QuestionsDatabase.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.get_table(self)};
    SQL
    return nil unless result.length > 0
    result.map { |entry| self.new(entry) }
  end 
  
  def save 
    
    if @id.nil?
      instance_vars = self.instance_variables[1..-1]
      
      
      QuestionsDatabase.instance.execute(<<-SQL, instance_vars)
        INSERT INTO
          #{self.get_table(self)} (#{instance_vars.map {|val| val.to_s }.join(',')})
        VALUES
          (#{instance_vars.map {|val| "?" }.join(',')})
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    else 
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
        UPDATE
          users
        SET
          fname = ?, lname = ?
        WHERE
          id = ?
      SQL
    end 
  end 
  
end 

class User < ModelBase
  attr_accessor :fname, :lname
  
  def self.find_by_name(fname, lname)
    users = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        userssql
      WHERE
        fname = ? AND lname = ?;
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
  
  def followed_questions 
    QuestionFollow.followed_questions_for_user_id(@id)
  end 
  
  def liked_questions 
    QuestionLike.liked_questions_for_user_id(@id)
  end 
  
  # Calculate average karma using Ruby methods 
  
  # def average_karma 
  #   questions = self.authored_questions
  #   num_questions = questions.length
  #   num_likes = 0
  #   questions.each do |question|
  #     num_likes += question.num_likes 
  #   end 
  #   avg_karma = num_likes.to_f / num_questions.to_f
  # end 
  
  # Calculate average karma using SQL query
  def average_karma
    counts = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        COUNT(DISTINCT(id)) AS num_questions, COUNT(question_likes.question_id) AS num_likes
      FROM
        questions 
      LEFT JOIN 
        question_likes ON question_likes.question_id = questions.id
      WHERE
        author_id = ?;
      
    SQL
    return counts[0]["num_likes"].to_f / counts[0]["num_questions"]
  end 
  
  # def save 
  #   if @id.nil?
  #     QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
  #       INSERT INTO
  #         users (fname, lname)
  #       VALUES
  #         (?, ?)
  #     SQL
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #   else 
  #     QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
  #       UPDATE
  #         users
  #       SET
  #         fname = ?, lname = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   end 
  # end 
  
end

class Question < ModelBase
  attr_accessor :title, :body, :author_id
  
  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?;
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end 
  
  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
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
  
  def followers 
    QuestionFollow.followers_for_question_id(@id)
  end 
  
  def likers 
    QuestionLike.likers_for_question_id(@id)
  end 
  
  def num_likes 
    QuestionLike.num_likes_for_question_id(@id)
  end 
  
  # def save 
  #   if @id.nil?
  #     QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
  #       INSERT INTO
  #         questions (title, body, author_id)
  #       VALUES
  #         (?, ?, ?)
  #     SQL
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #   else 
  #     QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
  #       UPDATE
  #         questions
  #       SET
  #         title = ?, body = ?, author_id = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   end 
  # end 
  
end 

class Reply < ModelBase
  attr_accessor :body, :question_id, :parent_reply_id, :user_id
  
  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?;
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
        question_id = ?;
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
        parent_reply_id = ?;
    SQL
    return nil unless replies.length > 0

    replies.map { |reply| Reply.new(reply) }
  end 
  
  # def save 
  #   if @id.nil?
  #     QuestionsDatabase.instance.execute(<<-SQL, @body, @question_id, @parent_reply_id, @user_id)
  #       INSERT INTO
  #         replies (body, question_id, parent_reply_id, user_id)
  #       VALUES
  #         (?, ?, ?, ?)
  #     SQL
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #   else 
  #     QuestionsDatabase.instance.execute(<<-SQL, @body, @question_id, @parent_reply_id, @user_id, @id)
  #       UPDATE
  #         replies
  #       SET
  #         body = ?, question_id = ?, parent_reply_id = ?, user_id = ?
  #       WHERE
  #         id = ?
  #     SQL
  #   end 
  # end 
  
end 

class QuestionFollow 
  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users 
      JOIN 
        question_follows ON question_follows.user_id = users.id
      WHERE
        question_id = ?;
    SQL
    return nil unless users.length > 0

    users.map { |user| User.new(user) }
  end 
  
  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions 
      JOIN 
        question_follows ON question_follows.question_id = questions.id
      WHERE
        user_id = ?;
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *, COUNT(*) AS num_followers
      FROM
        questions 
      JOIN 
        question_follows ON question_follows.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        num_followers DESC
      LIMIT
        ?;
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end 
end 

class QuestionLike 
  
  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users 
      JOIN 
        question_likes ON question_likes.user_id = users.id
      WHERE
        question_id = ?;
    SQL
    return nil unless users.length > 0

    users.map { |user| User.new(user) }
  end 
  
  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        question_id, COUNT(*) AS num_likes
      FROM
        questions 
      JOIN 
        question_likes ON question_likes.question_id = questions.id
      GROUP BY
        question_id
      HAVING
        question_id = ?;
    SQL
    return 0 if num_likes.empty?
    return num_likes[0]["num_likes"]
  end 
  
  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions 
      JOIN 
        question_likes ON question_likes.question_id = questions.id
      WHERE
        user_id = ?;
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *, COUNT(*) AS num_likes
      FROM
        questions 
      JOIN 
        question_likes ON question_likes.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        num_likes DESC
      LIMIT
        ?;
    SQL
    return nil unless questions.length > 0

    questions.map { |question| Question.new(question) }
  end 
  
  def initialize(options) 
    @user_id = options['user_id']
    @question_id = options['question_id']
  end 
end 
