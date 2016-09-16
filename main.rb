require 'aws-sdk'
require './dynamo_dao'

def is_integer(str)
  !!Integer(str)
rescue ArgumentError, TypeError
  false
end

# configure AWS SQS
Aws.config.update(
  access_key_id: 'x',
  secret_access_key: 'y',
  region: 'localhost',
  dynamodb: {
    endpoint: "http://localhost:8000"
  }
)

dynamodb_client = Aws::DynamoDB::Client.new
dynamo_dao = DynamoDao.new(dynamodb_client)
table_name = "item_tags"

begin
  puts "Select your choice:"
  puts "\t1. Create table item_tags"
  puts "\t2. View information about item_tags"
  puts "\t3. Select all item_tags"
  puts "\t4. Select item_tag by key"
  puts "\t5. Query demo by particular condition"
  puts "\t6. Insert a item_tag"
  puts "\t7. Update a item_tag"
  puts "\t8. Delete a item_tag"
  puts "\t9. Delete table item_tags"
  print "\nEnter your selection:\t"

  case gets.chomp
  when '1'
    dynamo_dao.create_table(table_name)
  when '2'
    dynamo_dao.describe_table(table_name)
  when '3'
    dynamo_dao.get_all_items(table_name)
  when '4'
    keys = {}
    print "\nEnter item_id:\t"
    keys["item_id"] = gets.chomp.to_i
    print "\nEnter locale:\t"
    keys["locale"] = gets.chomp

    dynamo_dao.find_by_key(table_name, keys)
  when '5'
    dynamo_dao.query_items(table_name)
  when '6'
    # input from user
    print "\nEnter new item_id:\t"
    item_id = gets.chomp

    # check item_id
    if is_integer(item_id)
      print "\nEnter new locale:\t"
      locale = gets.chomp

      print "\nEnter new is_origin:\t"
      is_origin = gets.chomp

      if is_origin.empty? || is_integer(is_origin)
        # insert valid item
        attributes = {}
        attributes["item_id"] = item_id.to_i
        attributes["locale"] = locale
        attributes["is_origin"] = is_origin.to_i unless is_origin.empty?
        dynamo_dao.put_item(table_name, attributes)
      else
        puts "is_origin is not a valid integer"
      end
    else
      puts "item_id is not a valid integer"
    end
  when '7'
    keys = {}
    print "\nEnter item_id needed to update:\t"
    keys["item_id"] = gets.chomp.to_i

    print "\nEnter locale needed to update:\t"
    keys["locale"] = gets.chomp

    print "\nEnter new is_origin:\t"
    is_origin = gets.chomp

    if is_integer(is_origin)
      dynamo_dao.update_item(table_name, keys, is_origin.to_i)
    else
      puts "is_origin is not a valid integer"
    end
  when '8'
    keys = {}
    print "\nEnter item_id needed to delete:\t"
    keys["item_id"] = gets.chomp.to_i

    print "\nEnter locale needed to delete:\t"
    keys["locale"] = gets.chomp

    dynamo_dao.delete_item(table_name, keys)
  when '9'
    dynamo_dao.delete_table(table_name)
  else
    puts "Not valid option"
  end

  print "Do you want to continue? (y/n)\t"
end while gets.chomp == 'y'
