# Customer Finder

Customer Finder is a field operations and customer master management app. It is designed to help teams load a customer master list, review accounts by DSP or location, update customer information, capture verified GPS coordinates with supporting photos, and export edited records for submission or consolidation.

The app follows an offline-first workflow built around a local database. Customer records are imported from CML files, managed inside the app, tagged when edited, and then exported together with captured images as a ZIP archive for downstream processing.

## App Workflow Summary

When the app starts, it shows a branded launch screen and then opens the main workspace with three primary sections:

- **Home**: operational dashboard for importing, updating, and exporting customer data
- **DSP**: customer browsing by sales representative or team
- **City/Brgy**: customer browsing by province, city, and barangay

The normal field workflow is:

1. Import the latest CML file into the local database.
2. Review customer counts and edited-record totals from the Home dashboard.
3. Browse customers either by DSP assignment or by geographic area.
4. Open an individual customer record to inspect its details and map location.
5. Update status, customer information, or capture a fresh GPS location with photo evidence.
6. Export all edited records and related images as a ZIP file for turnover.

## Main Procedures

### 1. Importing Customer Data

The Home page supports two customer master procedures:

- **Import CML** replaces the existing local customer dataset with a new CSV or XLSX file.
- **Update CML** compares the new file against the local database and adds only customer records that do not yet exist.

Both actions show progress indicators during processing. After an import or update, the Home dashboard automatically refreshes the customer counts.

### 2. Monitoring Operational Counts

The Home page acts as a quick status board for the local dataset. It summarizes record totals and keeps track of how many customer records have been edited and are ready for export. This gives users a simple checkpoint before and after fieldwork.

### 3. Browsing by DSP

The DSP page organizes customers by sales representative and team. Users can:

- filter DSPs by team
- update the DSP master list using a CSV file
- open a DSP to view assigned customers
- filter the customer list by status, coverage day, weekly coverage, and presence of GPS coordinates

This view is useful for workload review, route preparation, and DSP-level account validation.

### 4. Browsing by City and Barangay

The City/Brgy page provides geographic filtering using the area master data. Users can:

- filter by province, city, barangay, and customer status
- search by customer code, customer name, or contact/person name
- limit results to only records with valid longitude and latitude

This view is intended for territorial review and for locating accounts within specific service areas.

### 5. Reviewing and Updating a Customer Record

Selecting a customer opens a detail modal that displays:

- current customer information
- map preview when coordinates are already stored
- latitude and longitude values
- available customer actions

From this record view, users can perform three core updates:

- **Customer Status Update**: switch the account between active/approved and blocked/on hold
- **Customer Information Update**: edit key fields such as coverage schedule, contact data, owner/person name, TIN, address, province, city, and barangay
- **Capture New Location**: record a new GPS point tied to the customer

Each update marks the record as edited so it can be included in the next export package.

### 6. Capturing Location and Photo Evidence

Location capture follows a guided procedure:

1. The user captures exactly three photos using the device camera.
2. The app opens a preview screen where each image can be reviewed or retaken.
3. After photo confirmation, the app requests the device's current GPS position.
4. The user confirms the latitude and longitude before submission.
5. The images are stored in a customer-specific folder and the customer record is updated with the new coordinates.

This process ensures that every location update is supported by a consistent three-image photo set.

### 7. Exporting Edited Records

The Home page can export all edited customer records into a ZIP archive. The export package contains:

- an Excel file of edited customers
- the captured image folders associated with those edited customers

After a successful export, the app clears the edited flags for the exported records so that the next export contains only newly changed data.

## Data Handling Notes

- Customer data is stored locally in the app database for fast access and offline use.
- CML imports support both CSV and XLSX formats.
- DSP reference data can be refreshed through a CSV upload.
- Area filtering is based on the bundled area master file.
- Export output is saved as a ZIP archive, typically to the device Downloads folder when available.

## Recommended Field Procedure

For day-to-day operations, the recommended procedure is:

1. Load the latest CML before starting field activity.
2. Review records by DSP or by location, depending on assignment.
3. Open customer records and validate account details on site.
4. Update status or customer information when discrepancies are found.
5. Capture a new location only after completing the required three-photo checklist.
6. Export the edited archive at the end of the cycle and submit it to the receiving team.

This procedure keeps local records current, makes field validation traceable, and ensures that exported updates are complete and organized.
