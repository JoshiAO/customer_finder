# Customer Finder

Customer Finder is an offline-first field operations and customer master management app. It helps teams import a customer master list, review accounts by DSP or geography, update customer details, capture verified GPS coordinates with photo evidence, and export edited records for turnover.

The app stores operational data locally, so the main workflow remains usable in the field without requiring continuous connectivity. Imported customer data, DSP reference data, area hierarchy overrides, edited flags, and captured images are all handled inside the app's local workflow.

## Core Capabilities

- import customer master data from CSV or XLSX CML files
- update an existing local customer dataset by adding only new customer records
- browse customers by DSP, province, city, and barangay
- filter and search customers by operational and geographic criteria
- update customer status and core customer information
- capture exactly three supporting photos before submitting a new GPS location
- preview stored coordinates on a map and use live road-route tracking to a customer
- export edited records and captured images as a ZIP archive
- personalize the app theme, home background, launch logo, and launch title

## App Structure

When the app opens, it shows a branded launch screen and then loads the main workspace with three sections:

- **Home**: import, update, clear, monitor, export, and personalization tools
- **DSP**: browsing by sales representative and team
- **City/Brgy**: browsing by province, city, barangay, and customer status

## Typical Workflow

1. Import the latest CML into the local database.
2. Review overall and edited record counts from the Home dashboard.
3. Browse customers by DSP assignment or by geographic area.
4. Open a customer record to review details, coordinates, and map state.
5. Update customer status or customer information as needed.
6. Capture a fresh location with the required three-photo checklist when field verification is needed.
7. Export edited records and captured images as a ZIP archive for submission.

## Main Procedures

### 1. Importing and Updating Customer Data

The Home page supports two customer master operations:

- **Import CML** loads a CSV or XLSX file into local storage and replaces the active customer dataset.
- **Update CML** compares a new file against the local database and adds only customer records that do not yet exist locally.

Both actions run with progress tracking. After completion, the Home dashboard refreshes customer counts automatically.

### 2. Monitoring Local Operational Counts

The Home page acts as a status dashboard for the local dataset. It shows:

- total customer counts
- edited record counts
- import, update, clear, and export progress indicators

This gives users a quick checkpoint before and after field activity.

### 3. Managing Local Reference Data

The app supports reference-data refreshes directly inside the workflow:

- the **DSP** page can import a new DSP master list from CSV
- the **City/Brgy** page can import a new `Area.csv` file to overwrite the active province-city-barangay hierarchy used by its dropdown filters

These updates are persisted locally and reused by the app after restart.

### 4. Browsing by DSP

The DSP page groups customers by sales representative and team. Users can:

- filter DSP cards by team
- update the DSP master list from CSV
- open a DSP to view assigned customers
- filter customers by status, coverage day, weekly coverage, and whether valid longitude and latitude are present

This view is useful for workload review, route planning, and DSP-level validation.

### 5. Browsing by Province, City, and Barangay

The City/Brgy page supports geographic filtering driven by the active area hierarchy. Users can:

- filter by province, city, barangay, and customer status
- search by customer code, customer name, or contact/person name
- limit results to customers with valid longitude and latitude
- refresh the hierarchy by importing a replacement area CSV file

This view is intended for territorial review and service-area validation.

### 6. Reviewing a Customer Record

Selecting a customer opens a detail modal with:

- current customer details
- latitude and longitude values
- map preview when coordinates are available
- live tracking and route guidance controls when location access is granted
- customer update actions

From this view, users can perform these core actions:

- **Customer Status Update**: switch the account between active/approved and blocked/on hold
- **Customer Information Update**: edit fields such as coverage schedule, phone, owner/contact name, TIN, address, province, city, and barangay
- **Capture New Location**: record a new GPS point tied to the customer after photo confirmation

Each successful update marks the record as edited so it can be included in the next export package.

### 7. Live Map Tracking and Road Routing

When a customer has stored coordinates, the detail view can use the device's current position to support live tracking. The map workflow includes:

- high-accuracy location tracking
- animated movement of the user marker
- road-route fetching through OSRM-compatible routing providers
- route distance and duration feedback
- adaptive rerouting and off-route detection
- full-screen route view for navigation focus
- recovery prompts when GPS or location permission is disabled

This is intended to help users follow a road route toward a customer instead of relying only on a static point on the map.

### 8. Capturing Location and Photo Evidence

Location capture follows a guided process:

1. The user captures exactly three photos using the device camera.
2. The app opens a preview screen where each image can be reviewed or retaken.
3. After image confirmation, the app reads the device's GPS position.
4. The user confirms the location submission.
5. The images are stored in a customer-specific local folder and the customer record is updated with the new coordinates.

This keeps every location update tied to a consistent three-image evidence set.

### 9. Exporting Edited Records

The Home page can export all edited customer records into a ZIP archive. The export package contains:

- an Excel file of edited customers
- the captured image folders associated with those edited customers

The ZIP is typically saved to the device Downloads folder when available. After a successful export, the app clears the edited flags of exported records so the next export contains only newly changed records.

### 10. Clearing Local Data

The Home page also includes a local clear-data procedure. This removes customer and DSP records from local storage after confirmation, which is useful before loading a fresh operational dataset.

## Personalization

The Home page includes a theme and personalization panel. Users can:

- choose from predefined theme presets
- change light or dark mode where allowed by the selected theme
- set a custom home background image
- set a custom launch logo image
- change the launch screen title text

These settings are persisted locally on device storage.

## Data Handling Notes

- customer data is stored locally for offline-first use
- CML imports support both CSV and XLSX files
- the app keeps a persisted snapshot of the last imported CML for repair and reuse scenarios
- DSP reference data can be refreshed from CSV
- province, city, and barangay filtering can use a locally overridden area hierarchy imported from CSV
- edited customer export is generated as a ZIP archive that bundles spreadsheet data and captured images
- captured images are stored locally in customer-specific folders

## Recommended Field Procedure

For day-to-day operations, the recommended procedure is:

1. Import or update the latest CML before starting fieldwork.
2. Review counts on the Home page to confirm the local dataset is ready.
3. Browse records by DSP or by location, depending on assignment.
4. Open customer records and validate account details on site.
5. Use the map view and live tracking tools when navigating to a customer.
6. Update status or customer information when discrepancies are confirmed.
7. Capture a new location only after completing the required three-photo checklist.
8. Export the edited ZIP archive at the end of the cycle and submit it to the receiving team.

This workflow keeps local records current, makes field validation traceable, and ensures that exported updates remain organized and evidence-backed.
