class ItemTagsDao
  def initialize(dynamodb_client)
    @dynamodb_client = dynamodb_client
  end

  def create_table(table_name)
    if table_exists?(table_name)
      puts "Table named #{table_name} already existed!"
    else
      @dynamodb_client.create_table(
        table_name: table_name,
        attribute_definitions: [
          {
            attribute_name: :item_id,
            attribute_type: :N
          },
          {
            attribute_name: :locale,
            attribute_type: :S
          },
          {
            attribute_name: :is_origin,
            attribute_type: :N
          }
        ],
        key_schema: [
          {
            attribute_name: :item_id,
            key_type: :HASH
          },
          {
            attribute_name: :locale,
            key_type: :RANGE
          }
        ],
        global_secondary_indexes: [
          {
            index_name: "origin_item_tags",
            key_schema: [
              {
                attribute_name: :is_origin,
                key_type: :HASH,
              },
              {
                attribute_name: :item_id,
                key_type: :RANGE,
              }
            ],
            projection: {
              projection_type: "ALL",
            },
            provisioned_throughput: {
              read_capacity_units: 25,
              write_capacity_units: 25,
            },
          },
        ],
        provisioned_throughput: {
          read_capacity_units: 25,
          write_capacity_units: 25,
        },
      )
      puts "Create item_tags successfully!"
    end
  end

  def describe_table(table_name)
    begin
      resp = @dynamodb_client.describe_table(table_name: table_name)
      display_table(resp.table)
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def delete_table(table_name)
    if table_exists?(table_name)
      @dynamodb_client.delete_table(table_name: table_name)
      puts "Delete item_tags table successfully!"
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def get_all_items(table_name)
    if table_exists?(table_name)
      resp = @dynamodb_client.scan(table_name: table_name)
      resp.items.each do |item|
        puts "#{item["item_id"]} - #{item["locale"]} - #{item["is_origin"]}"
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def find_by_key(table_name, keys)
    if table_exists?(table_name)
      item = @dynamodb_client.get_item(
        table_name: table_name,
        key: keys
      ).item
      if item.nil?
        puts "Item not found!"
      else
        puts "#{resp.item["item_id"]} - #{resp.item["locale"]} - #{resp.item["is_origin"]}"
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def query_items(table_name)
    if table_exists?(table_name)
      resp = @dynamodb_client.query(
        table_name: table_name,
        projection_expression: "item_id, locale",
        key_condition_expression: "item_id = :item_id",
        expression_attribute_values: {
          ":item_id": 1
        }
      )
      resp.items.each do |item|
        puts "#{item["item_id"]} - #{item["locale"]}"
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def put_item(table_name, attributes)
    if table_exists?(table_name)
      begin
        @dynamodb_client.put_item(
          table_name: table_name,
          item: attributes
        )
        puts "Insert to #{table_name} successfully!"
      rescue Exception => msg
        puts "Error: #{msg}"
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def update_item(table_name, keys, is_origin)
    if table_exists?(table_name)
      # check item exists?
      item = @dynamodb_client.get_item(
        table_name: table_name,
        key: keys
      ).item

      if item.nil?
        puts "Item not found!"
      else
        begin
          @dynamodb_client.update_item(
            table_name: table_name,
            key: keys,
            attribute_updates: {
              "is_origin" => {
                value: is_origin,
                action: "PUT"
              }
            }
          )
          puts "Update item successfully!"
        rescue Exception => msg
          puts "Error: #{msg}"
        end
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  def delete_item(table_name, keys)
    if table_exists?(table_name)
      # check item exists?
      item = @dynamodb_client.get_item(
        table_name: table_name,
        key: keys
      ).item

      if item.nil?
        puts "Item not found!"
      else
        # delete item
        begin
          @dynamodb_client.delete_item(
            table_name: table_name,
            key: keys
          )
          puts "Delete item successfully!"
        rescue Exception => msg
          puts "Error: #{msg}"
        end
      end
    else
      puts "Table named #{table_name} didn't exist!"
    end
  end

  private
  def display_table(table)
    puts "============================================="
    puts "Name: #{table.table_name}"
    puts "Atributes:"
    table.attribute_definitions.each do |attribute|
      if attribute.attribute_type == 'S'
        type = 'String'
      elsif attribute.attribute_type == 'N'
        type = "Number"
      else # B
        type = "Binary"
      end
      puts "\t#{attribute.attribute_name} - #{type}"
    end
    puts "Keys: #{table.key_schema.map(&:attribute_name).join(', ')}"
    puts "============================================="
  end

  def table_exists?(table_name)
    begin
      @dynamodb_client.describe_table(table_name: table_name)
      true
    rescue Aws::DynamoDB::Errors::ResourceNotFoundException
      false
    end
  end
end

