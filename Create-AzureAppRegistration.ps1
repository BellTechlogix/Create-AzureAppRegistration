# Function to check if a module is installed
function Check-Module {
  param (
    [string]$Name,
    [switch]$Import = $true
  )

  # Check if the module is installed
  if (Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue) {
    # The module is installed, so import it if the switch is enabled
    if ($Import) {
      Import-Module -Name $Name
    }
  } else {
        # Register the WindowsPowerShell Gallery as a trusted repository
    Set-PSRepository -Name WindowsPowerShell -InstallationPolicy Trusted
    
    # The module is not installed, so install it
    Install-Module -Name $Name
  }
}

# Increase the function capacity
$MaximumFunctionCount = 32768

# Import the Microsoft.Graph module
Check-Module -Name Microsoft.Graph -Import:$true

# Force authentication
Connect-MgGraph

# Create a new form
$form = New-Object System.Windows.Forms.Form

# Add a label to the form
$label = New-Object System.Windows.Forms.Label
$label.Text = "Please select an Azure directory:"
$form.Controls.Add($label)

# Add a drop-down list to the form
$dropdown = New-Object System.Windows.Forms.ComboBox
$directories = Get-MgDirectory
Foreach ($directory in $directories) {
  $dropdown.Items.Add($directory.DisplayName)
}
$form.Controls.Add($dropdown)

# Add a button to the form
$button = New-Object System.Windows.Forms.Button
$button.Text = "Create App Registration"
$button.Click += {
  # Get the selected directory
  $selected_directory = $dropdown.SelectedItem

  # If the user did not select a directory, exit the script
  If ($selected_directory -eq "") {
    Write-Host "No directory selected. Exiting."
    Exit
  }

  # Prompt the user for the app registration details
  Write-Host "Please enter the app registration details:"
  $display_name = Read-Host -Prompt "Display name"
  $application_id = Read-Host -Prompt "Application ID"
  $client_secret = Read-Host -Prompt "Client secret"

  # Create the app registration
  $app_registration = New-MgAppRegistration `
    -DisplayName $display_name `
    -ApplicationId $application_id `
    -ClientSecret $client_secret `
    -Directory $selected_directory

  # Verify the app registration details
  Write-Host "Please verify the app registration details:"
  Write-Host $display_name
  Write-Host $application_id
  Write-Host $client_secret

  # Prompt the user to confirm
  $confirm = Read-Host -Prompt "Is this correct? (Y/N)"

  # If the user did not confirm, exit the script
  If ($confirm -ne "Y") {
    Write-Host "Cancelled."
    Exit
  }

  # Save the app registration details in a JSON file
  $json_file = "app_registration.json"
  $content = @{
    "ApplicationId" = $app_registration.ApplicationId
    "ClientSecret" = $app_registration.ClientSecret
    "DisplayName" = $app_registration.DisplayName
  }
  $json = $content | ConvertTo-Json -Depth 10
  $file = Get-Content $json_file
  $file | Set-Content $json_file

  # Write-Host "App registration created successfully!"

  # Authenticate against Microsoft Graph
  $context = New-Object Microsoft.Graph.AuthenticationContext
  $context.ClientId = $application_id
  $context.ClientSecret = $client_secret
  $context.Connect()

  # Write a message to the console indicating that the app registration was created successfully and authenticated against Microsoft Graph
  Write-Host "App registration created successfully and authenticated against Microsoft Graph!"
}
$form.ShowDialog()