*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs
Library           Collections


*** Variables ***
${OUTPUT_FOLDER}    ${CURDIR}${/}output${/}
${WORKING_FOLDER}    ${OUTPUT_FOLDER}working${/}

*** Keywords ***
Remove All Files From Working Directory
    Empty Directory    ${WORKING_FOLDER}

*** Keywords ***
Submit Orders
    ${orders_url}=    Ask For Orders CSV URL
    ${orders}=    Download And Read Orders File    ${orders_url}
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds    2 minute    5 sec    Submit Order    ${order}
    END

*** Keywords ***
Ask For Orders CSV URL
    Add heading       Please provide the URL to the orders.csv file.
    Add text input    url    label=URL    # Expected URL: https://robotsparebinindustries.com/orders.csv
    ${result}=    Run dialog
    [Return]    ${result.url}

*** Keywords ***
Download And Read Orders File
    [Arguments]    ${url}
    ${secret}=    Get Secret    links
    Download    ${url}    overwrite=True
    ${table}=    Read table from CSV    orders.csv    dialect=excel    header=True
    [Return]    ${table}

*** Keywords ***
Submit Order
    [Arguments]    ${order}

    Close Browser
    Open RobotSpareBin Ordering Form
    Close Constitutional Rights Modal If Exists
    Populate Webform with Order Details    ${order}
    Click Button    preview
    Click Button    order
    Save Results    ${order}[Order number]
    Close Browser

*** Keywords ***
Open RobotSpareBin Ordering Form
    ${secret}=    Get Secret    links
    Open Available Browser    ${secret}[order_page]
    Wait Until Page Contains    Build and order your robot    timeout=30

*** Keywords ***
Close Constitutional Rights Modal If Exists
    ${modal_exists}=    Does Page Contain Element    css:div.modal
    IF    ${modal_exists}
        Click Button    xpath://div[@class="alert-buttons"]/button[text()="OK"]
    END

*** Keywords ***
Populate Webform With Order Details
    [Arguments]    ${order_details}
    Select From List By Value    head    ${order_details}[Head]
    Select Radio Button    body    id-body-${order_details}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order_details}[Legs]
    Input Text    address    ${order_details}[Address]

*** Keywords ***
Save Results
    [Arguments]    ${order_number}
    
    ${images}=    Create List
    ...    ${WORKING_FOLDER}receipt${order_number}.png
    ...    ${WORKING_FOLDER}preview${order_number}.png
    
    Screenshot    receipt    ${images}[0]
    Screenshot    robot-preview-image    ${images}[1]
    Add Files To PDF    ${images}    ${WORKING_FOLDER}result${order_number}.pdf

*** Keywords ***
Create ZIP File Of Receipts
    Archive Folder With Zip    ${WORKING_FOLDER}    ${OUTPUT_FOLDER}results.zip    include=*.pdf

*** Tasks ***
Submit orders from a CSV file and save the receipts in a ZIP archive
    Remove All Files From Working Directory
    Submit Orders
    Create ZIP File Of Receipts
    [Teardown]    Close Browser


