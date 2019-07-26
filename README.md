
# Airtable to Geckoboard

Airtable to Geckoboard is a ruby gem to facilitate quick data transfers from your Airtable Tables using the [AirTable API](https://airtable.com/api) to your [Geckoboard Datasets](https://api-docs.geckoboard.com/).

Features include:

* The ability to specify any Airtable Base Key and Table Name to synchronize.
* The ability to specify the exact Airtable fields you would like to synchronize.
* Automatic best-guess field type mapping, to keep Airtable dates and numbers properly formatted in Geckoboard. 
* The ability to optionally specify the exact Geckoboard Field type for each field in your Airtable Table, giving you the ability to visualize currencies and percentages as intended. See [Airtable's missing schema issue](https://community.airtable.com/t/metadata-api-for-schema-and-mutating-tables/1856/4) to see why we exact field maps are not automatically generated.
* The ability to use Airtable's [Filtering](https://support.airtable.com/hc/en-us/articles/203255215-Formula-field-reference) to fine-tune your synchronization.
* Automatic query throttling to ensure you do not exceed your Airtable API rate limits.
* Creates Geckoboard datasets automatically.

## Installation

Add this line to your application's Gemfile:

    gem 'airtable_to_geckoboard', '~> 1.0.0'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install airtable_to_geckoboard

## Configuration 

To use the Airtable to Geckoboard Gem, you can instantiate a new client object of the class `AirtableToGeckoboard::Client`.  The following parameters are accepted:

* (required) `String` [airtable\_api\_key](https://support.airtable.com/hc/en-us/articles/219046777-How-do-I-get-my-API-key-)
* (required) `String` [airtable\_base\_key](https://airtable.com/api)
  * The key can be found in the URL of your Base's API after the domain.
* (required) `String` airtable\_table\_name
  * This the full name of the table you would like to synchronize, including spaces.
* (required) `String` [geckoboard\_api\_key](https://support.geckoboard.com/hc/en-us/articles/205945508-Find-your-Geckoboard-API-key)
* (required) `String` geckoboard\_dataset\_id
  * This can be a name of an existing Dataset or a new Dataset. This Gem will overwrite the existing data in the current dataset if it exists.
* (optional) `Array` airtable\_fields
  * If your table has fewer than 10 columns, this field is optional. Otherwise, use this paramter to set an array of strings containing the name's of the fields you would like to synchronize, as they are displayed in your Airtable Table. For example `["Field 1", "Field 2", "Field 3"].
* (optional) `Hash` airtable\_field\_map.
  * Use this parameter to specify the [Geckoboard Field Type](https://api-docs.geckoboard.com/#schemas-and-types) of your Airtable Table's fields. Acceptable field types are 
    * `:datetime`
    * `:date`
    * `:money`
    * `:number`
    * `:percentage`
    * `:string`  
  * For example `{:"Field 1" => :date, :"Field 2" => :percentage, :"Field 3" => :money}`.  
  * If a field is not specified, the Gem will make a guess for you. See [Airtable's missing schema issue](https://community.airtable.com/t/metadata-api-for-schema-and-mutating-tables/1856/4) to see why exact field maps are not automatically generated.
* (Optional) `String` [airtable\_filter](https://support.airtable.com/hc/en-us/articles/203255215-Formula-field-reference)

## Example Usage

```ruby
client = AirtableToGeckoboard::Client.new(airtable_api_key: 'your-airtable-api-key',
                       airtable_base_key: 'your-airtable-base-key',
                       airtable_table_name: 'your-airtable-table-name',
                       geckoboard_api_key: 'your-geckoboard-api-key',
                       geckoboard_dataset_id: 'your.dataset'
                       airtable_fields: ["Field X", "Field Y", "Field Z"]
                       airtable_field_map: {:"Field X" => :percentage, :"Field Y" => :datetime},
                       airtable_filter: "NOT({Field Z} = 3)"
client.sync
```
The `sync` method will return `true` if the synchronization is successful. If an error is encountered, you will receive an exception.

Once successful, the Dataset in your Geckoboard account will automatically populate with your Airtable data for visualizations.

## Limitations

Currently the Airtable API does not provide a schema definition endpoint.  Because of this, certain Airtable field types cannot be synchronized, including: 

* Attachments
* Barcodes
* Collaborator Fields
* Link to Another Record fields
* Lookup Fields
* Multiple Select Fields.

Airtable is currently in the process of upgrading their API, so hopefully we'll be able to add these field types soon.

## Questions?

Please feel free to contact [Geckoboard Support](https://support.geckoboard.com/hc/en-us) with any questions.