#
# ticket_persistor.rb
#
# Copyright 2012 © VMware, Inc.
#

module Scotty
  FOUND_MASTER_CSV = 'found_master_tickets.csv'
  MISSING_MASTER_CSV = 'missing_master_tickets.csv'
  FOUND_USE_CSV = 'found_use_tickets.csv'
  MISSING_USE_CSV = 'missing_use_tickets.csv'
  CREATED_MASTER_CSV = 'created_master_tickets.csv'
  CREATED_USE_CSV = 'created_use_tickets.csv'

  def self.info(message)
    puts "[INFO] #{message}"
  end

end

module Scotty::TicketPersistor

  @@mte_cols = ['id','name','version','license_text','description','license_name','source_url','category','is_modified','repo','sz_product','sz_product_version','language']
  @@psa_cols = ['mte','product','version','id','interaction','description','is_modified','features','status','resolution','license']
  @@created_cols = ['id','desc']

  def self.write_found_master_tickets(components)
    counter = 0
    CSV.open(Scotty::FOUND_MASTER_CSV, 'wb') do |csv|
      csv << @@mte_cols
      components.each { |c|
          counter +=  1
          csv << [c.id, c.name, c.version, ::Scotty::CONF.license_text, '', ::Scotty::CONF.license_name, c.download_url, c.category, 'No', c.subdir, c.sz_product, c.sz_product_version, c.language]
      }
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::FOUND_MASTER_CSV}"
  end

  def self.write_missing_master_tickets(components)
    counter = 0
    CSV.open(Scotty::MISSING_MASTER_CSV, 'wb') do |csv|
      csv << @@mte_cols
      components.each do |c|
          counter +=  1
          data = c.result['data']
          csv << ['', data[0], data[1], ::Scotty::CONF.license_text, ::Scotty::CONF.mte_desc, ::Scotty::CONF.license_name,
          c.download_url, data[2], 'No', c.subdir, c.sz_product, c.sz_product_version, c.language]
      end
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::MISSING_MASTER_CSV}"
  end

  def self.write_found_use_tickets(tickets)
    counter = 0
    CSV.open(Scotty::FOUND_USE_CSV, 'wb') do |csv|
      csv << @@psa_cols
      tickets.each do |elem|
        elem['requests'].each do |item|
          counter += 1
          csv << [ elem['mte'], elem['product'], elem['version'], item['id'],
                   item['interactions'].join, item['desc'],
                   item['modified'], item['features'].join, item['status'],
                   item['resolution'], item['license_name'] ]
        end
      end
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::FOUND_USE_CSV}"
  end

  def self.write_missing_use_tickets(tickets)
    counter = 0
    CSV.open(Scotty::MISSING_USE_CSV, 'wb') do |csv|
      csv << @@psa_cols
      tickets.each {|elem|
        counter += 1
        csv << [elem['data'][2], elem['data'][0],elem['data'][1],'','',elem ? elem.to_s : '']
      }
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::MISSING_USE_CSV}"
  end

  def self.write_created_master_tickets(tickets)
    counter = 0
    CSV.open(Scotty::CREATED_MASTER_CSV, 'wb') do |csv|
      csv << @@created_cols
      tickets.each do |t|
        counter += 1
        if t['stat'] == 'ok'
          csv << [ t['id'], t['desc'] ]
        else
          csv << t.to_s
        end
      end
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::CREATED_MASTER_CSV}"
  end

  def self.write_created_use_tickets(tickets)
    counter = 0
    CSV.open(Scotty::CREATED_USE_CSV, 'wb') do |csv|
      csv << @@created_cols
      tickets.each do |t|
        counter += 1
        if t['stat'] == 'ok'
          csv << [ t['id'], t['desc'] ]
        else
          csv << t.to_s
        end
      end
    end
    Scotty.info "Wrote #{counter} records to #{Scotty::CREATED_USE_CSV}"
  end

  def self.read_found_master_tickets
    CSV.foreach(Scotty::FOUND_MASTER_CSV, :headers => :first_row, :return_headers => false) do |row_data|
      data = { :id => row_data[0].to_i,
               :name => row_data[1],
               :version => row_data[2],
               :license_text => row_data[3],
               :description => row_data[4],
               :license_name => row_data[5],
               :source_url => row_data[6],
               :category => row_data[7],
               :is_modified => row_data[8],
               :repo => row_data[9],
               :sz_product => row_data[10],
               :sz_product_version => row_data[11],
               :language => row_data[12] }
      yield data
    end
  end

  def self.read_missing_master_tickets
    CSV.foreach(Scotty::MISSING_MASTER_CSV, :headers => :first_row, :return_headers => false) do |row_data|
      data = { :name => row_data[1],
               :version => row_data[2],
               :license_text => row_data[3],
               :description => row_data[4],
               :license_name => row_data[5],
               :source_url => row_data[6],
               :category => row_data[7],
               :modified => row_data[8],
               :repo => row_data[9],
               :sz_product => row_data[10],
               :sz_product_version => row_data[11],
               :language => row_data[12] }
       yield data
    end
  end

  def self.read_missing_use_tickets
    CSV.foreach(Scotty::MISSING_USE_CSV, :headers => :first_row, :return_headers => false) do |row_data|
      data = { :product => row_data[1],
               :version => row_data[2],
               :mte => row_data[0].to_i,
               :interaction => ::Scotty::CONF.psa_interaction,
               :description => ::Scotty::CONF.psa_desc }
      yield data
    end
  end

end
