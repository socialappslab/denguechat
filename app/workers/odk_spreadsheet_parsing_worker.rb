require "sidekiq"
require 'json'
require 'nokogiri'

class OdkSpreadsheetParsingWorker 
  include Sidekiq::Worker
  sidekiq_options :queue => :odk_parsing, :retry => true, :backtrace => true

  @@location_fields_dict = {
      :lFormId => ["KEY"],
      :lName => ["data-location-location_code_manual", "data-location-location_code", "data-location_data-location_code_manual"],
      :lTeam => ["data-phonenumber"],
      :lUser => ["data-username"]
  }

  @@visit_fields_dict = {
      :vFormId => ["KEY"],
      :vLocationFormParent => ["PARENT_KEY"],
      :vDate => ["data-visit_group-visit_date"], # "Fecha de visita (YYYY-MM-DD)" in Excel CSV
      :vStatus => ["data-visit_group-location_status"], # Not available in original Excel CSV
      :vHostGender => ["data-visit_group-visit_form-visit-visit_host_gender"], # Not available in original Excel CSV
      :vHostAge => ["data-visit_group-visit_form-visit-visit_host_age"], # Not available in original Excel CSV
      :vLarvicide => ["data-visit_group-visit_form-services_larvicide","data-visit_group-visit_form-visit-services_larvicide"], # Not available in original Excel CSV
      :vFumigation => ["data-visit_group-visit_form-services_fumigation","data-visit_group-visit_form-visit-services_fumigation"], # Not available in original Excel CSV
      :vObs => ["data-visit_group-visit_form-visit_obs","data-visit_group-visit_form-visit-visit_obs"],
      :vAutorep => ["data-visit_group-visit_form-autoreporte","data-visit_group-visit_form-visit-autoreporte"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepDengue => ["data-visit_group-visit_form-auto_report_numbers-auto_report_number_dengue","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_dengue"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepChik => ["data-visit_group-visit_form-auto_report_numbers-auto_report_number_chik","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_number_chik"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepZika => ["data-visit_group-visit_form-auto_report_numbers-auto_reporte_number_zika","data-visit_group-visit_form-visit-auto_report_numbers-auto_reporte_number_zika"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepPregnant => ["data-visit_group-visit_form-auto_report_numbers-auto_report_zika_number_pregnant","data-visit_group-visit_form-visit-auto_report_numbers-auto_report_zika_number_pregnant"], # "Auto-reporte dengue/chik" in Excel CSV
      :vAutorepSymptoms => ["data-visit_group-visit_form-symptoms","data-visit_group-visit_form-visit-symptoms"], # Not available in original Excel CSV
      :vAutorepSymptomsGender => ["data-visit_group-visit_form-symptoms_report-symptoms_gender","data-visit_group-visit_form-visit-symptoms_report-symptoms_gender"], # Not available in original Excel CSV
      :vAutorepSymptomsList => ["data-visit_group-visit_form-symptoms_report-symptom_list","data-visit_group-visit_form-visit-symptoms_report-symptom_list"] # Not available in original Excel CSV
  }

  @@inspection_fields_dict = {
      :iFormId => ["KEY"],
      :iVisitFormParent => ["PARENT_KEY"],
      :iBRSCode => ["data-visit_group-inspection-breeding_site_code"], # "Tipo de criadero" in original Excel CSV
      :iBRSCodeAmount => ["data-visit_group-inspection-breeding_site_amount"], # Tipo de criadero" in original Excel CSV
      :iLocalization => ["data-visit_group-inspection-br_localization"], # "Localización",
      :iProtected => ["data-visit_group-inspection-br_protected"], # "¿Protegido?"
      :iLarvicide => ["data-visit_group-inspection-br_larvicide"], # "¿Abatizado?"
      :iLarvae => ["data-visit_group-inspection-br_larvae"], # "¿Larvas?",
      :iPupae => ["data-visit_group-inspection-br_pupae"], # "¿Pupas?",
      :iPicture => ["data-visit_group-inspection-br_picture"], # "¿Foto de criadero?",
      :iEliminationDate => ["data-visit_group-inspection-br_elimination_date"], # "Fecha de eliminación (YYYY-MM-DD)",
      :iEliminationPhoto => ["data-visit_group-inspection-br_elimination_picture"], # "¿Foto de eliminación?",
      :iLarvaePicture => ["data-visit_group-inspection-br_larvae_picture"],
      :iObs => ["data-visit_group-inspection-breeding_site_description"] # "Comentarios sobre tipo y/o eliminación"]
  }

  # Extract the data on a single cell of a row in the record, given a set of possible keys with their positions
  # If the key does not exist among the headers, return an empty string
  def self.extract_data_from_record(recordArray, headerArray, possibleKeys, indexOfKeyToUse)
    key = possibleKeys[indexOfKeyToUse]
    if (!key.nil? && key != "")
      fieldPosition = headerArray.index(key)
      if (!fieldPosition.nil? && fieldPosition > -1)
        return recordArray[fieldPosition]
      else
        return ""
      end
    else
      return ""
    end
  end

  # Given an xmlform spec and xpath, retrieve the text related to that field
  def self.extract_desc_from_xmlform(xmldoc, xpath)
    queryResult = xmldoc.xpath(xpath)
    if !queryResult.nil?
      value = queryResult[0]
      if !value.nil?
         return value.text.strip
      else
        return xpath
      end
    else
      return xpath
    end
  end

  def self.key_to_xpath(key)
    return key.sub(/-/,'/')
  end

  def perform
    locations = nil
    inspectionsPerVisit = nil
    Rails.logger.debug "[OdkSpreadsheetParsingWorker] Started the ODK synchronization worker..."

    # Read organizations grouped by the configuration parameters
    organizations = Parameter.all.group_by do |parameter| 
      parameter.organization_id
    end
    organizations.each do |id, parameters|
      organizations[id] = parameters.group_by { |parameter| parameter.key }
    end

    # Parse the data URLs for each organization.
    # Current version works only with three different CSVs, produced by an ODK collect form
    # In all cases, 4 URLs to CSVs are needed:
    # 1. A spreadsheet/csv with info about visited locations
    # 2. A spreadsheet/csv with info about each visit for each location
    # 3. A spreadsheet/csv with info about each different breeding site found in each visit
    # 4. A XMLForm specification (to use to store information that is not currently in the model of DengueChat)
    # # Run the parser only if all 4 URLs are set
    organizations.each do |organizationId, parameters|
      if (!parameters["organization.data.visits.url"].nil? && !parameters["organization.data.locations.url"].nil? && !parameters["organization.data.inspections.url"].nil? && !parameters["organization.data.xml-form"].nil?)
        # Read the XML form spec
        xmldoc = parameters["organization.data.xml-form"] != nil ? Nokogiri::HTML(open(parameters["organization.data.xml-form"][0].value)) : nil
        # Read who the default user to upload this data should be
        defaultUser =  parameters["organization.sync.default-user"] != nil ? parameters["organization.sync.default-user"][0].value : nil

        # Read locations
        locationsHeader = []
        open(parameters["organization.data.locations.url"][0].value) do |locationsFile|
          tempLocationFile = locationsFile.read
          locationsHeader = tempLocationFile.split($/)[0].sub(/\r/,'').split(",")
          columnOfLocationFormId = locationsHeader.index(@@location_fields_dict[:lFormId][0])
          locations = tempLocationFile.split($/)[1..-1].group_by do |line|
            line.split(",")[columnOfLocationFormId].split("\r")[0]
          end
        end

        # Read inspections grouped by visits
        # ToDo: in all the places we read data from a cell in the CSV, implement reading the data from the fallback columns if there was no valid data in the default
        # Todo: i.e., if the value at line.split(",")[columnOfVisitKey] is not valid, try with the next column number in the array of @@inspection_fields_dict[:iVisitFormParent]
        # ToDo: this applies to all the places where we are referring to columns in the CSV
        inspectionsHeader = []
        open(parameters["organization.data.inspections.url"][0].value) do |inspectionsFile|
          tempInspectionsFile = inspectionsFile.read
          inspectionsHeader = tempInspectionsFile.split($/)[0].sub(/\r/,'').split(",")
          columnOfVisitFormId = inspectionsHeader.index(@@inspection_fields_dict[:iVisitFormParent][0]);
          inspectionsPerVisit = tempInspectionsFile.split($/)[1..-1].group_by do |line|
            line.split(",")[columnOfVisitFormId] # Grouping lines by the values in the column `columnOfVisitKey`
          end
        end

        visitsDuplicateArrayController = []
        # Read visits
        open(parameters["organization.data.visits.url"][0].value) do |visitsFile|
          file = visitsFile.read
          visitsHeader = file.split($/)[0].sub(/\r/,'').split(",")
          file.split($/)[1..-1].each_with_index do |visit,visitsIndex|
            visitArray = visit.split(",")
            visitId = extract_data_from_record(visitArray, visitsHeader, @@visit_fields_dict[:vFormId], 0).strip
            locationId = extract_data_from_record(visitArray, visitsHeader, @@visit_fields_dict[:vLocationFormParent], 0).strip

            # Duplicated Visits Filter: only process visitIds that are not included in the IN-MEMORY visitsDuplicatedArrayController
            if !visitsDuplicateArrayController.include? visitId
              visitsDuplicateArrayController.push(visitId)
              inspCount = !inspectionsPerVisit[visitId].nil? ? inspectionsPerVisit[visitId].length : 0
              Rails.logger.debug "[OdkSpreadsheetParsingWorker] About to process #{inspCount.to_s} inspections for visit #{visitId}"

              # The following visit records will be discarded:
              # - Visit without form ID
              # - Visits without Location
              # - Visits without Inspections
              if((!inspectionsPerVisit[visitId].eql? nil) && (inspectionsPerVisit[visitId].length > 0) && (!locations[locationId].eql? nil) )
                lNameKeys = @@location_fields_dict[:lName]
                locationName = locations[locationId][0].split(',')[locationsHeader.index(lNameKeys[0])].strip != "" ?
                               locations[locationId][0].split(',')[locationsHeader.index(lNameKeys[0])] :
                               locations[locationId][0].split(',')[locationsHeader.index(lNameKeys[1])].strip != "" ?
                                   locations[locationId][0].split(',')[locationsHeader.index(lNameKeys[1])] :
                                   locations[locationId][0].split(',')[locationsHeader.index(lNameKeys[1])]

                # Read location from database and process the data only if location exists
                location = Location.find_by_address(locationName)
                if(!location.nil?)
                  newVisit = true
                  # Starting the creation of the XLS file to import
                  workbook = RubyXL::Workbook.new
                  worksheet = workbook[0]
                  dengueChatCSVHeader = ["Fecha de visita (YYYY-MM-DD)" ,"Auto-reporte dengue/chik",	"Tipo de criadero",
                            "Localización", "¿Protegido?", "¿Abatizado?", "¿Larvas?", "¿Pupas?", "¿Foto de criadero?",
                            "Fecha de eliminación (YYYY-MM-DD)",	"¿Foto de eliminación?",
                            "Comentarios sobre tipo y/o eliminación", "Foto de larvas", "Respuestas Adicionales"]
                  dengueChatCSVHeader.each_with_index  do |string, index|
                    worksheet.add_cell(3, index, string)
                  end

                  vStatusKeys = @@visit_fields_dict[:vStatus] # => if 'E', process visit
                  vDateKeys = @@visit_fields_dict[:vDate] # => header[0] = "Fecha de visita (YYYY-MM-DD)"
                  vAutorepKeys = @@visit_fields_dict[:vAutorep] # => if 1, process the AUTOREPORTE columns
                  vAutorepDengueKeys = @@visit_fields_dict[:vAutorepDengue] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
                  vAutorepChikKeys = @@visit_fields_dict[:vAutorepChik] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
                  vAutorepZikaKeys = @@visit_fields_dict[:vAutorepZika] # => header[1] => "Auto-reporte dengue/chik" Example: C(m20)D(f3,f010)
                  vObsKeys = @@visit_fields_dict[:vObs ] # => header[11] => "Comentarios sobre tipo y/o eliminación"
                  vHostGenderKeys = @@visit_fields_dict[:vHostGender] # => questions
                  vHostAgeKeys = @@visit_fields_dict[:vHostAge] # => questions
                  vLarvicideKeys = @@visit_fields_dict[:vLarvicide] # => questions
                  vFumigationKeys = @@visit_fields_dict[:vFumigation] # => questions
                  vAutorepPregnantKeys = @@visit_fields_dict[:vAutorepPregnant] # => questions
                  vAutorepSympKeys = @@visit_fields_dict[:vAutorepSymptoms] # => questions
                  vAutorepSympGenderKeys = @@visit_fields_dict[:vAutorepSymptomsGender] # => questions
                  vAutorepSympListKeys = @@visit_fields_dict[:vAutorepSymptomsList] # => questions

                  visitStatus = extract_data_from_record(visitArray, visitsHeader, vStatusKeys, 0)
                  vDate = extract_data_from_record(visitArray, visitsHeader, vDateKeys, 0).insert(6, '20')

                  vAutorep = extract_data_from_record(visitArray, visitsHeader, vAutorepKeys, 0).strip != "" ?
                                 extract_data_from_record(visitArray, visitsHeader, vAutorepKeys, 0) :
                                 extract_data_from_record(visitArray, visitsHeader, vAutorepKeys, 1)
                  vAutorepDengue = extract_data_from_record(visitArray, visitsHeader, vAutorepDengueKeys, 0).strip != "" ?
                                       extract_data_from_record(visitArray, visitsHeader, vAutorepDengueKeys, 0) :
                                       extract_data_from_record(visitArray, visitsHeader, vAutorepDengueKeys, 1)
                  vAutorepChik = extract_data_from_record(visitArray, visitsHeader, vAutorepChikKeys, 0).strip != "" ?
                                     extract_data_from_record(visitArray, visitsHeader, vAutorepChikKeys, 0) :
                                     extract_data_from_record(visitArray, visitsHeader, vAutorepChikKeys, 1)
                  vAutorepZika = extract_data_from_record(visitArray, visitsHeader, vAutorepZikaKeys, 0).strip != "" ?
                                     extract_data_from_record(visitArray, visitsHeader, vAutorepZikaKeys, 0) :
                                     extract_data_from_record(visitArray, visitsHeader, vAutorepZikaKeys, 1)
                  vAutorepFinal = ""

                  if (vAutorep.strip == "1")
                    if (vAutorepDengue != "" && vAutorepDengue != "0")
                      vAutorepFinal = vAutorepFinal + vAutorepDengue + "D"
                    end
                    if (vAutorepChik != "" && vAutorepChik != "0")
                      vAutorepFinal = vAutorepFinal + vAutorepChik + "C"
                    end
                    if (vAutorepZika != "" && vAutorepZika != "0")
                      vAutorepFinal = vAutorepFinal + vAutorepZika + "Z"
                    end
                  end

                  # ToDo: once integrated and with data cleaned, eliminate or think  of better way to handle  fallbacks
                  visitObs =  extract_data_from_record(visitArray, visitsHeader, vObsKeys, 0).strip != "" ?
                                  extract_data_from_record(visitArray, visitsHeader, vObsKeys, 0) :
                                  extract_data_from_record(visitArray, visitsHeader, vObsKeys, 0)
                  visitHostGender =  extract_data_from_record(visitArray, visitsHeader, vHostGenderKeys, 0)
                  visitHostAge =  extract_data_from_record(visitArray, visitsHeader, vHostAgeKeys, 0)
                  visitLarvicide =   extract_data_from_record(visitArray, visitsHeader, vLarvicideKeys, 0).strip != "" ?
                                         extract_data_from_record(visitArray, visitsHeader, vLarvicideKeys, 0) :
                                         extract_data_from_record(visitArray, visitsHeader, vLarvicideKeys, 1)
                  visitServices =   extract_data_from_record(visitArray, visitsHeader, vFumigationKeys, 0).strip != "" ?
                                        extract_data_from_record(visitArray, visitsHeader, vFumigationKeys, 0) :
                                        extract_data_from_record(visitArray, visitsHeader, vFumigationKeys, 1)
                  visitAutorepPregnant =  extract_data_from_record(visitArray, visitsHeader, vAutorepPregnantKeys, 0).strip != "" ?
                                              extract_data_from_record(visitArray, visitsHeader, vAutorepPregnantKeys, 0) :
                                              extract_data_from_record(visitArray, visitsHeader, vAutorepPregnantKeys, 1)
                  visitAutorepSymptoms = extract_data_from_record(visitArray, visitsHeader, vAutorepSympKeys, 0).strip != "" ?
                                             extract_data_from_record(visitArray, visitsHeader, vAutorepSympKeys, 0) :
                                             extract_data_from_record(visitArray, visitsHeader, vAutorepSympKeys, 1)
                  visitAutorepSymptomsGender = extract_data_from_record(visitArray, visitsHeader, vAutorepSympGenderKeys, 0).strip != "" ?
                                                   extract_data_from_record(visitArray, visitsHeader, vAutorepSympGenderKeys, 0) :
                                                   extract_data_from_record(visitArray, visitsHeader, vAutorepSympGenderKeys, 1)
                  visitAutorepSymptomsList = extract_data_from_record(visitArray, visitsHeader, vAutorepSympListKeys, 0).strip != "" ?
                                                 extract_data_from_record(visitArray, visitsHeader, vAutorepSympListKeys, 0) :
                                                 extract_data_from_record(visitArray, visitsHeader, vAutorepSympListKeys, 1)
                  questions = []

                  inspectionsDuplicateArrayController = []
                  inspectionsPerVisit[visitId].each_with_index do |inspection,inspectionIndex|
                    tempInspection = inspection.split(",")

                    # Filter of duplicated visits
                    inspectionFormId = extract_data_from_record(tempInspection, inspectionsHeader, @@inspection_fields_dict[:iFormId], 0)
                    if !inspectionsDuplicateArrayController.include? inspectionFormId
                      inspectionsDuplicateArrayController.push(inspectionFormId)

                      # Extracting column number for inspection related fields
                      brsCodeKeys = @@inspection_fields_dict[:iBRSCode]
                      brsCodeAmountKeys = @@inspection_fields_dict[:iBRSCodeAmount]
                      brsLocalizationKeys = @@inspection_fields_dict[:iLocalization]
                      brsProtectedKeys = @@inspection_fields_dict[:iProtected]
                      brsLarvicideKeys = @@inspection_fields_dict[:iLarvicide]
                      brsLarvaeKeys = @@inspection_fields_dict[:iLarvae]
                      brsPupaeKeys = @@inspection_fields_dict[:iPupae]
                      brsEliminationDateKeys = @@inspection_fields_dict[:iEliminationDate]
                      brsEliminationPhotoKeys = @@inspection_fields_dict[:iEliminationPhoto]
                      brsObsKeys = @@inspection_fields_dict[:iObs]
                      brsPictureUrlKeys = @@inspection_fields_dict[:iPicture]
                      brsLarvaPictureUrlKeys = @@inspection_fields_dict[:iPicture]
                      # Extracting data from inspection related fields
                      brsCode = extract_data_from_record(tempInspection, inspectionsHeader, brsCodeKeys, 0) #tipo de criadero data-visit_group-inspection-breeding_site_code
                      brsCodeAmount = extract_data_from_record(tempInspection, inspectionsHeader, brsCodeAmountKeys, 0) #tipo de criadero data-visit_group-inspection-breeding_site_code
                      brsCodeFinal = brsCode+brsCodeAmount.to_s
                      brsLocalization = extract_data_from_record(tempInspection, inspectionsHeader, brsLocalizationKeys, 0)
                      brsProtected = extract_data_from_record(tempInspection, inspectionsHeader, brsProtectedKeys, 0) #protegido? data-visit_group-inspection-br_protected
                      brsLarvicide = extract_data_from_record(tempInspection, inspectionsHeader, brsLarvicideKeys, 0)
                      brsLarvae = extract_data_from_record(tempInspection, inspectionsHeader, brsLarvaeKeys, 0) #larvas? data-visit_group-inspection-br_larvae
                      brsPupae = extract_data_from_record(tempInspection, inspectionsHeader, brsPupaeKeys, 0) #pupas? data-visit_group-inspection-br_pupae
                      brsEliminationDate = extract_data_from_record(tempInspection, inspectionsHeader, brsEliminationDateKeys, 0) #fecha de eliminacion data-visit_group-inspection-br_elimination_date
                      brsEliminationPhoto = extract_data_from_record(tempInspection, inspectionsHeader, brsEliminationPhotoKeys, 0)
                      brsObs = extract_data_from_record(tempInspection, inspectionsHeader, brsObsKeys, 0)
                      brsPictureUrl = extract_data_from_record(tempInspection, inspectionsHeader, brsPictureUrlKeys, 0)
                      brsLarvaPictureUrl = extract_data_from_record(tempInspection, inspectionsHeader, brsLarvaPictureUrlKeys, 0)

                      # Visit date and visit related data is included only in the first row of the inspections
                      if newVisit
                        newVisit = false
                        worksheet.add_cell(4+inspectionIndex, 0, vDate) # "Fecha de visita (YYYY-MM-DD)" in DengueChat Excel CSV Form
                        worksheet.add_cell(4+inspectionIndex, 1, vAutorepFinal) # "Auto-reporte dengue/chik" in DengueChat Excel CSV Form
                        # For each visit, a JSONB data record is generated to contain all the data that was collected
                        # but that is not related to data fields in the model of DengueChat.
                        # They are stored in the questions field of the DC model, using the XMLForm specs to include both
                        # the form field name and the form field description (i.e., the actual question that was made)
                        if(xmldoc != nil )
                          questions.push({:code => vStatusKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vStatusKeys[0])), :answer => visitStatus})
                          questions.push({:code => vHostGenderKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vHostGenderKeys[0])), :answer => visitHostGender})
                          questions.push({:code => vHostAgeKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vHostAgeKeys[0])), :answer => visitHostAge})
                          questions.push({:code => vFumigationKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vFumigationKeys[0])), :answer => visitServices})
                          questions.push({:code => vLarvicideKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vLarvicideKeys[0])), :answer => visitLarvicide})
                          questions.push({:code => vObsKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vObsKeys[0])), :answer => visitObs})
                          questions.push({:code => vAutorepKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepKeys[0])), :answer => vAutorep})
                          questions.push({:code => vAutorepDengueKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepDengueKeys[0])), :answer => vAutorepDengue})
                          questions.push({:code => vAutorepChikKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepChikKeys[0])), :answer => vAutorepChik})
                          questions.push({:code => vAutorepZikaKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepZikaKeys[0])), :answer => vAutorepZika})
                          questions.push({:code => vAutorepPregnantKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepPregnantKeys[0])), :answer => visitAutorepPregnant})
                          questions.push({:code => vAutorepSympKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepSympKeys[0])), :answer => visitAutorepSymptoms})
                          questions.push({:code => vAutorepSympGenderKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepSympGenderKeys[0])), :answer => visitAutorepSymptomsGender})
                          questions.push({:code => vAutorepSympListKeys[0], :body => extract_desc_from_xmlform(xmldoc, key_to_xpath(vAutorepSympListKeys[0])), :answer => visitAutorepSymptomsList})
                          worksheet.add_cell(4+inspectionIndex, 13, JSON.generate(questions)) # "Respuestas Adicionales" NOT in DengueChat Excel CSV Form
                        end
                      end
                      worksheet.add_cell(4+inspectionIndex, 2, brsCodeFinal) # 	"Tipo de criadero" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 3, brsLocalization) # 3 => "Localización" => not available in current ODK Form
                      worksheet.add_cell(4+inspectionIndex, 4, brsProtected) # "¿Protegido?" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 5, brsLarvicide) # 5 => Abatizado => not available in current ODK Form, but used in nicaragua
                      worksheet.add_cell(4+inspectionIndex, 6, brsLarvae) # "¿Larvas?" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 7, brsPupae) # "¿Pupas?" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 8, brsPictureUrl) # 8 => "¿Foto de criadero?"  in DengueChat Excel CSV Form => ToDo: collected in URL form (but excel csv expects just a boolean)
                      worksheet.add_cell(4+inspectionIndex, 9, brsEliminationDate) # "Fecha de eliminación (YYYY-MM-DD)" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 10, brsEliminationPhoto) # 10 => "¿Foto de eliminación?" => collected in URL form (but excel csv expects just a boolean)
                      worksheet.add_cell(4+inspectionIndex, 11, brsObs) # "Comentarios sobre tipo y/o eliminación" in DengueChat Excel CSV Form
                      worksheet.add_cell(4+inspectionIndex, 12, brsLarvaPictureUrl) # "Foto de la Larva" NOT in DengueChat Excel CSV Form

                      Rails.logger.debug "[OdkSpreadsheetParsingWorker] Added row to workwheet: [#{vDate}|#{vAutorepFinal}|#{brsCodeFinal}|#{brsProtected}|#{brsLarvae}|#{brsPupae}|#{brsEliminationDate}|#{brsObs}]"
                    end
                  end
                  fileName=locationName
                  # Temporary Excel file generated and uploaded to the server
                  workbook.write("#{Rails.root}/#{fileName}.xlsx")
                  upload =  ActionDispatch::Http::UploadedFile.new({
                    :filename => "#{fileName}.xlsx",
                    :content_type => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    :tempfile => File.new("#{Rails.root}/#{fileName}.xlsx")
                  })

                  Rails.logger.debug "[OdkSpreadsheetParsingWorker] Temporary XLSX file: "+"#{Rails.root}/#{fileName}.xlsx"
                  Rails.logger.debug "[OdkSpreadsheetParsingWorker] Upload response: "+"#{upload.to_s}"
                  # Use the generated CSV and then re-use excel parsing to upload the data
                  # ToDo: Revisa CSV Report code to process all data correctly
                  # ToDo: Process inspection pictures if there are (extract the URL, donwload and save)
                  # ToDo: Process inspection larvae pictures if there are (extract the URL, donwload and save)
                  # ToDo: If a breeding site code is the same than that found in same location with same code, consider it the same br site
                  # ToDo: find a way to store also the Closed or Rejected visited (for statistics purposes)
                  # ToDo: Persist processed visit form ids and inspection form ids
                  # ToDo: integrate a CSV parsing library (to prevent issues with quoting, double-quoting, different types of separators, etc.)
                  API::V0::CsvReportsController.batch(
                      :csv => upload,
                      :file_name => "#{fileName}.xlsx",
                      :username => (!User.find_by_username(locations[locationId][0].split(',')[locationsHeader.index("data-user_denguechat")]).eql? nil) ?
                                       locations[locationId][0].split(',')[locationsHeader.index("data-user_denguechat")] : defaultUser,
                      :organization_id => organizationId)
                  Delete the local file
                  File.delete("#{Rails.root}/#{fileName}.xlsx") if File.exist?("#{Rails.root}/#{fileName}.xlsx")
                end
              end
            end
          end
        end
      end
    end
    OdkSpreadsheetParsingWorker.perform_in(1.day)
  end
end

