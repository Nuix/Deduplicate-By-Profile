script_directory = File.dirname(__FILE__)

# Setup Nx which provides settings and progress dialogs
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Setup SuperUtilities which provides functionality for creating item set
# deduplicated using digests based on selected metadata profile
require File.join(script_directory,"SuperUtilities.jar")
java_import com.nuix.superutilities.SuperUtilities
$su = SuperUtilities.init($utilities,NUIX_VERSION)
java_import com.nuix.superutilities.misc.ProfileDigester

require 'thread'

dialog = TabbedCustomDialog.new("Deduplicate By Profile")
dialog.setHelpUrl("https://github.com/Nuix/Deduplicate-By-Profile")

# Get listing of existing metadata profile names
profile_names = $utilities.getMetadataProfileStore.getMetadataProfiles.map{|p|p.getName}
# Are we using selected items?
use_selected_items = ($current_selected_items.nil? == false && $current_selected_items.size > 0)

main_tab = dialog.addTab("main_tab","Main")
if use_selected_items
	main_tab.appendHeader("Using #{$current_selected_items.size} selected items")
else
	main_tab.appendHeader("Using all #{$current_case.count("")} items in case")
end
main_tab.appendComboBox("metadata_profile_name","Metadata Profile",profile_names)
main_tab.appendCheckBox("include_content_text","Include Item Content Text",false)
main_tab.appendTextField("item_set_name","Item Set Name","Deduplicated By Profile")
main_tab.appendComboBox("deduplicate_by","Deduplicate By",["FAMILY","INDIVIDUAL"])
main_tab.appendCheckBox("record_custom_digest","Record Custom Digest",true)
main_tab.appendTextField("custom_digest_field","Digest Custom Metadata Field","DedupeByProfileDigest")

# Validate user input
dialog.validateBeforeClosing do |values|
	item_set_name = values["item_set_name"]

	if item_set_name.strip.empty?
		CommonDialogs.showWarning("Please provide a non-empty item set name.")
		next false
	end

	if values["record_custom_digest"] && values["custom_digest_field"].strip.empty?
		CommonDialogs.showWarning("Please provide a value for 'Digest Custom Metadata Field'")
		next false
	end

	next true
end

dialog.display
if dialog.getDialogResult == true
	values = dialog.toMap

	metadata_profile_name = values["metadata_profile_name"]
	metadata_profile = $utilities.getMetadataProfileStore.getMetadataProfiles.select{|p|p.getName == metadata_profile_name}.first
	include_content_text = values["include_content_text"]
	item_set_name = values["item_set_name"]
	deduplicate_by = values["deduplicate_by"]
	record_custom_digest = values["record_custom_digest"]
	custom_digest_field = values["custom_digest_field"]

	error_count = 0
	semaphore = Mutex.new

	ProgressDialog.forBlock do |pd|
		pd.setAbortButtonVisible(false)
		pd.setTitle("Deduplicate By Profile")
		pd.onMessageLogged do |message|
			puts message
		end
		pd.setSubStatus("")

		profile_digester = ProfileDigester.new
		profile_digester.setProfile(metadata_profile)
		profile_digester.setIncludeItemText(include_content_text)
		profile_digester.setRecordDigest(record_custom_digest)
		profile_digester.setDigestCustomField(custom_digest_field)

		profile_digester.whenMessageLogged do |message|
			pd.logMessage(message)
		end

		last_progress_message = Time.now
		profile_digester.whenProgressUpdated do |current,total|
			pd.setMainProgress(current,total)
			pd.setMainStatus("Progress #{current}/#{total}")
			if (Time.now - last_progress_message) > 1 || current == total
				last_progress_message = Time.now
			end
		end

		profile_digester.whenErrorLogged do |message,item|
			pd.logMessage("ERROR: #{message}")
			semaphore.synchronize {
				error_count += 1	
			}
		end

		items = nil
		if use_selected_items
			items = $current_selected_items
			pd.logMessage("Using #{items.size} selected items")
		else
			items = $current_case.searchUnsorted("")
			pd.logMessage("Using all #{items.size} items in case")
		end

		pd.logMessage("Record Custom Digest: #{record_custom_digest}")
		if record_custom_digest
			pd.logMessage("Custom Digest Field: #{custom_digest_field}")
		end

		pd.logMessage("Adding items to item set...")
		item_set = profile_digester.addItemsToItemSet($current_case,item_set_name,deduplicate_by,items)

		pd.logMessage("'#{item_set_name}' Originals: #{item_set.getOriginals.size}")
		pd.logMessage("'#{item_set_name}' Duplicates: #{item_set.getDuplicates.size}")

		pd.logMessage("Errors: #{error_count}")
		if error_count > 0
			pd.logMessage("Please review log for ERROR messages")
		end

		pd.setCompleted
	end
end