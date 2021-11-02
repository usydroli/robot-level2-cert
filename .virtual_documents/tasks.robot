*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           Collections


*** Variables ***
${OUTPUT_FOLDER}    ${CURDIR}${/}output${/}
${WORKING_FOLDER}    ${OUTPUT_FOLDER}working${/}
${ORDER_LINK}    https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Open RobotSpareBin Ordering Form
    Open Available Browser    ${ORDER_LINK}
    Wait Until Page Contains    Build and order your robot    timeout=30


*** Keywords ***
Download And Read Orders File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv    dialect=excel    header=True
    [Return]    ${table}


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
    
    ${pdf}=    Set Variable    ${WORKING_FOLDER}result${order_number}.pdf
    
    ${images}=    Create List
    ...    ${WORKING_FOLDER}receipt${order_number}.png
    ...    ${WORKING_FOLDER}preview${order_number}.png
    
    Screenshot    receipt    ${images}[0]
    Screenshot    robot-preview-image    ${images}[1]
    Add Files To PDF    ${images}    ${pdf}
    
    [Return]    ${pdf}


*** Keywords ***
Submit Order
    [Arguments]    ${order}

    Close The Browser
    Open RobotSpareBin Ordering Form
    Close Constitutional Rights Modal If Exists
    Populate Webform with Order Details    ${order}
    Click Button    preview
    Click Button    order
    ${pdf}=    Save Results    ${order}[Order number]
    Close The Browser
    
    [Return]    ${pdf}


*** Keywords ***
Submit Orders
    ${pdfs}=    Create List
    ${orders}=    Download And Read Orders File

    FOR    ${order}    IN    @{orders}
        ${pdf}=    Wait Until Keyword Succeeds    2 minute    5 sec    Submit Order    ${order}
    END
    
    [Return]    ${pdfs}


*** Keywords ***
Create ZIP File Of Receipts
    [Arguments]    ${pdfs}
    Add To Archive    ${pdfs}    ${OUTPUT_FOLDER}results.zip


*** Keywords ***
Close The Browser
    Close Browser


*** Tasks ***
Submit orders from a CSV file and save the receipts in a ZIP archive
    Download And Read Orders File
    ${pdfs}=    Submit Orders
    Create ZIP File Of Receipts    ${pdfs}
    [Teardown]    Close The Browser



