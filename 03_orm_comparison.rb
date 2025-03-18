require_relative 'setup'

# Setup fresh database and generate larger dataset
setup_database
generate_sample_data(users: 1000, posts_per_user: 10, comments_per_post: 5)

puts "\n=== ORM Comparison Examples ==="

# Example 1: Simple Queries
puts "\n1. Simple Query Performance"
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report("ActiveRecord - all") do
    User.all.to_a
  end

  x.report("Sequel - all") do
    DB[:users].all
  end

  x.report("ActiveRecord - where") do
    User.where(created_at: 1.day.ago..Time.current).to_a
  end

  x.report("Sequel - where") do
    DB[:users].where(created_at: 1.day.ago..Time.current).all
  end

  x.compare!
end

# Example 2: Complex Joins
puts "\n2. Complex Join Performance"
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report("ActiveRecord - complex join") do
    User.joins(posts: :comments)
        .select('users.*, COUNT(DISTINCT posts.id) as posts_count, COUNT(comments.id) as comments_count')
        .group('users.id')
        .to_a
  end

  x.report("Sequel - complex join") do
    DB[:users]
      .join(:posts, user_id: :id)
      .join(:comments, post_id: Sequel[:posts][:id])
      .select(
        Sequel[:users][:id],
        Sequel[:users][:name],
        Sequel.function(:count, Sequel[:posts][:id]).as(:posts_count),
        Sequel.function(:count, Sequel[:comments][:id]).as(:comments_count)
      )
      .group(Sequel[:users][:id], Sequel[:users][:name])
      .all
  end

  x.compare!
end

# Example 3: Aggregations
puts "\n3. Aggregation Performance"
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report("ActiveRecord - aggregation") do
    Post.group(:user_id)
        .select('user_id, COUNT(*) as posts_count, AVG(LENGTH(content)) as avg_content_length')
        .having('COUNT(*) > 5')
        .to_a
  end

  x.report("Sequel - aggregation") do
    DB[:posts]
      .select(:user_id)
      .select_append { [
        count(id).as(:posts_count),
        avg(length(content)).as(:avg_content_length)
      ] }
      .group(:user_id)
      .order(:user_id)
      .all
  end

  x.compare!
end

# Example 4: Bulk Operations
puts "\n4. Bulk Operation Performance"
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report("ActiveRecord - bulk insert") do
    User.insert_all((1..100).map { |i| 
      { name: "User #{i}", email: "user#{i}@example.com", created_at: Time.current, updated_at: Time.current }
    })
  end

  x.report("Sequel - bulk insert") do
    DB[:users].multi_insert((1..100).map { |i| 
      { name: "User #{i}", email: "user#{i}@example.com", created_at: Time.current, updated_at: Time.current }
    })
  end

  x.compare!
end

# Example 5: Query Building
puts "\n5. Query Building Approaches"
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  conditions = { created_at: 1.day.ago..Time.current }
  pattern = "%test%"

  x.report("ActiveRecord - method chain") do
    User.where(conditions)
        .where("name LIKE ?", pattern)
        .order(created_at: :desc)
        .limit(100)
        .to_a
  end

  x.report("Sequel - method chain") do
    DB[:users]
      .where(conditions)
      .where(Sequel.like(:name, pattern))
      .order(Sequel.desc(:created_at))
      .limit(100)
      .all
  end

  x.compare!
end

puts "\nKey Findings:"
puts "1. Sequel generally performs better for raw SQL operations"
puts "2. ActiveRecord provides better Ruby-like syntax and integration"
puts "3. Complex joins show significant performance differences"
puts "4. Bulk operations benefit from specialized methods"
puts "5. Query building overhead varies between ORMs"

puts "\nRecommendations:"
puts "1. Use Sequel for performance-critical, data-intensive operations"
puts "2. Stick with ActiveRecord for standard CRUD and Rails integration"
puts "3. Consider using both in the same application where appropriate"
puts "4. Profile your specific use case before choosing an ORM"
puts "5. Use bulk operations whenever possible for better performance" 