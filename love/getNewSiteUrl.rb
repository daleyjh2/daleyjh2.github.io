# -*- coding: UTF-8 -*-
# gem install http
# gem install nokogiri
# gem install sqlite3

require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'faraday'

NEW_SITE_URL = "http://popdata.cn/newsiteurl"
NEW_SITE_PATH = "/data/web/wordpress/newsiteurl"
def get_new_site(current_site_path, new_site_path)
	begin
        	old_site_url = open(current_site_path)
        	old_site_url = old_site_url.read.lstrip.rstrip
		puts old_site_url

		# 访问旧网站地址查看新内容
		doc = Nokogiri::HTML(open(old_site_url))
		puts doc
		new_site_url = nil
		find_scripts = doc.search('script', 'hao123.href')
		if find_scripts.size > 0
			script_content = find_scripts[0].content
			script_content.split(";").each do |line|
				next if !line.include?("var strU=")
				temp_url_array = []
				line.split("\"").each do |s|
					if s.include?("http")
						temp_url_array << s
					elsif s.include?("window.location")
						temp_url_array << old_site_url
					elsif s.include?("&p=")
						temp_url_array << s
					end
				end
				temp_url = temp_url_array.join("")
				puts temp_url
				temp_response = Faraday.get(temp_url)
				# new site location got
				new_site_url = temp_response[:location]
			end
		end
		
		if new_site_url.nil?
			doc.css('div#newurllink a.panel:first').each do |link|
				puts link
				new_site_url = link.attributes['href'] if new_site_url.nil?
				break if !new_site_url.nil?
			end
		end
		
		# if no new_site_url then exit
		return if new_site_url.nil?
		
		# 访问新网站地址，获取跳转地址
		res = open(new_site_url)
		res.base_uri.path=""
		new_site_url = res.base_uri.to_s
		new_doc = Nokogiri::HTML(res)
		# 检查正文内容
		li_page = nil
		new_doc.css('li#mn_forum a').each do |link|
			li_page = link.content
                end
		if !li_page.nil? && (old_site_url != new_site_path) 
			system "echo #{new_site_url} > #{new_site_path}"
		end
	rescue Exception => e
		puts "[ERROR] GET WEBSITE URL FAILED. #{e.message}"
	end
end

get_new_site(NEW_SITE_URL, NEW_SITE_PATH)

=begin
# Fetch and parse HTML document
doc = Nokogiri::HTML(open('http://thzthz.cc/forum-42-1.html'))

puts "### Search for nodes by css"
doc.css('nav ul.menu li a', 'article h2').each do |link|
  puts link.content
end

puts "### Search for nodes by xpath"
doc.xpath('//nav//ul//li/a', '//article//h2').each do |link|
  puts link.content
end

puts "### Or mix and match."
doc.search('nav ul.menu li a', '//article//h2').each do |link|
  puts link.content
end

# https://github.com/sparklemotion/sqlite3-ruby
require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.db"

# Create a table
rows = db.execute <<-SQL
  create table numbers (
    name varchar(30),
    val int
  );
SQL

# Execute a few inserts
{
  "one" => 1,
  "two" => 2,
}.each do |pair|
  db.execute "insert into numbers values ( ?, ? )", pair
end

# Find a few rows
db.execute( "select * from numbers" ) do |row|
  p row
end

# Create another table with multiple columns

db.execute <<-SQL
  create table students (
    name varchar(50),
    email varchar(50),
    grade varchar(5),
    blog varchar(50)
  );
SQL

# Execute inserts with parameter markers
db.execute("INSERT INTO students (name, email, grade, blog) 
            VALUES (?, ?, ?, ?)", ["Jane", "me@janedoe.com", "A", "http://blog.janedoe.com"])

db.execute( "select * from students" ) do |row|
  p row
end

=end
