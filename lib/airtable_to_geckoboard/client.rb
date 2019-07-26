module AirtableToGeckoboard
  class Client
    attr_accessor :airtable_api_key, :airtable_base_key, :airtable_table_name, :airtable_fields, :airtable_filter, :geckoboard_dataset_id, :airtable_field_map

    WHITELIST_TYPES = [Integer, String, DateTime, Float, TrueClass]
    ACCEPTABLE_GECKOBOARD_FIELDS = [:datetime, :date, :money, :number, :percentage, :string]

    def initialize(args)
      @airtable_api_key = args[:airtable_api_key] #required
      @airtable_base_key = args[:airtable_base_key] #required 
      @airtable_table_name = args[:airtable_table_name] #required
      @airtable_fields = args[:airtable_fields] || [] #optional, but if you have more than 10 columns in your airtable table, then it is required.
      @airtable_filter = args[:airtable_filter] #optional
      @airtable_field_map = args[:airtable_field_map] || {} #optional
      raise(TooManyAirtableColumns, "Please provide 10 or fewer Airtable columns to sync.") if @airtable_fields.length > 10
      @geckoboard_dataset_id = args[:geckoboard_dataset_id] #required
      @geckoboard_client = Geckoboard.client(args[:geckoboard_api_key]) #required
    end

    def sync
      raise(TooManyAirtableColumns, "Please provide 10 or fewer Airtable columns to sync.") if @airtable_fields.length > 10
      records = get_airtable_data
      geckoboard_fields = []
      processed_fields = []
      field_map = {}
      rows = []
      records.each_with_index do |record, index|
        record["fields"].keys.select{|key| @airtable_fields.length == 0 || @airtable_fields.include?(key)}.each do |airtable_column_name|
          begin 
            DateTime.parse(record["fields"][airtable_column_name])
            c = DateTime
          rescue Exception => e 
            c = record["fields"][airtable_column_name].class
          end
          if WHITELIST_TYPES.include?(c) and !processed_fields.include?(airtable_column_name)
            field = define_geckoboard_field(airtable_column_name,c)
            geckoboard_fields.push field
            processed_fields.push airtable_column_name
            field_map[airtable_column_name] = field
          end
        end
      end
      raise(TooManyAirtableColumns,"Geckoboard requires 10 or fewer columns per dataset. Your Airtable table '#{@airtable_table_name}' has #{field_map.length} columns. Please use the :airtable_fields option to specify which Airtable columns you would like to sync.") if field_map.length > 10
      records.each do |record|
        row = {}
        processed_fields.each do |airtable_column_name|
          if field_map[airtable_column_name].is_a? Geckoboard::DateTimeField
            row[geckoboard_key(airtable_column_name)] = DateTime.parse(record["fields"][airtable_column_name])
          elsif field_map[airtable_column_name].is_a? Geckoboard::MoneyField
            row[geckoboard_key(airtable_column_name)] = record["fields"][airtable_column_name].to_f * 100
          else
            row[geckoboard_key(airtable_column_name)] = record["fields"][airtable_column_name]
          end
        end
        rows.push row 
      end
      begin
        @geckoboard_client.datasets.delete(@geckoboard_dataset_id)
      rescue Geckoboard::UnexpectedStatusError
      end
      dataset = @geckoboard_client.datasets.find_or_create(@geckoboard_dataset_id, fields: geckoboard_fields.uniq)
      dataset.put(rows)
    end

    def get_airtable_data
      records = []
      response = query_airtable
      records.push response["records"]
      continue = response["offset"]
      throttle = 1
      while continue
        sleep(1) if (throttle)%4==0
        response = query_airtable(response["offset"])
        records.push response["records"]
        continue = response["offset"]
        throttle += 1
      end
      records.flatten
    end

    def query_airtable(offset=nil)
      uri = URI.parse("https://api.airtable.com/v0/#{@airtable_base_key}/#{@airtable_table_name}?offset=#{offset}&filterByFormula=#{@airtable_filter}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      request = Net::HTTP::Get.new(uri.request_uri)
      request["charset"] = "utf-8"
      request["Authorization"] = "Bearer #{@airtable_api_key}"
      JSON.parse(http.request(request).body)
    end
    

    private 
      def geckoboard_key(airtable_column_name)
        airtable_column_name.downcase.gsub(/\s/,"_").gsub(/[^A-Za-z0-9]/, "").to_sym
      end

      def define_geckoboard_field(airtable_column_name,c)
        if airtable_field_map.keys.include?(airtable_column_name.to_sym) && ACCEPTABLE_GECKOBOARD_FIELDS.include?(airtable_field_map[airtable_column_name.to_sym])
          field = case airtable_field_map[airtable_column_name.to_sym]
          when :datetime 
            Geckoboard::DateTimeField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          when :date
            Geckoboard::DateField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          when :money
            Geckoboard::MoneyField.new(geckoboard_key(airtable_column_name), name: airtable_column_name, currency_code: "USD", optional: true)
          when :number
            Geckoboard::NumberField.new(geckoboard_key(airtable_column_name), name: airtable_column_name, optional: true)
          when :percentage
            Geckoboard::PercentageField.new(geckoboard_key(airtable_column_name), name: airtable_column_name, optional: true)
          when :string 
            Geckoboard::StringField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          end
        else
          field = case c.to_s
          when Integer.to_s
            Geckoboard::NumberField.new(geckoboard_key(airtable_column_name), name: airtable_column_name, optional: true)
          when String.to_s
            Geckoboard::StringField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          when DateTime.to_s
            Geckoboard::DateTimeField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          when Float.to_s
            Geckoboard::NumberField.new(geckoboard_key(airtable_column_name), name: airtable_column_name, optional: true)
          when TrueClass.to_s
            Geckoboard::StringField.new(geckoboard_key(airtable_column_name), name: airtable_column_name)
          end
        end
      end
  end
end