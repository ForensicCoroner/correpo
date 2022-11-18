*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             String
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders_url}=    Get and log the value of the vault secrets using the Get Secret keyword
    ${csvPath}=    Input form dialog
    Open the robot order website    ${orders_url}

    ${orders}=    Get orders    ${csvPath}

    FOR    ${row}    IN    @{orders}
        #Log    ${row}
        Close the annoying modal
        Fill in the form    ${row}
        Wait Until Keyword Succeeds    10x    3    Preview the robot
        Wait Until Keyword Succeeds    10x    3    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}
    Maximize Browser Window

Get orders
    [Arguments]    ${csvPath}
    #Download csv file
    #Download    https://robotsparebinindustries.com/orders.csv    verify=FALSE    overwrite=True
    Download    ${csvPath}    verify=FALSE    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Close the annoying modal
    Click Button    //button[@class="btn btn-dark"]

Fill in the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@name="address"]    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]

Submit the order
    #Mute Run On Failure    Page Should Contain Element
    Click Button    order
    Page Should Contain Element    //div[@id="receipt"]

Store the receipt as a PDF file
    [Arguments]    ${order number}
    Set Local Variable    ${file_name_and_path}    ${OUTPUT_DIR}${/}${order number}
    Wait Until Element Is Visible    //div[@id="receipt"]
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${file_name_and_path}.pdf
    RETURN    ${file_name_and_path}

Take a screenshot of the robot
    [Arguments]    ${order number}
    Set Local Variable    ${file_name_and_path}    ${OUTPUT_DIR}${/}${order number}
    Wait Until Element Is Visible    //div[@id="robot-preview-image"]
    Screenshot    //div[@id="robot-preview-image"]    ${file_name_and_path}.png
    RETURN    ${file_name_and_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}.pdf
    @{files}=    Create List    ${screenshot}.png

    Add Files To Pdf    ${files}    ${pdf}.pdf    ${True}
    #Close Pdf    ${pdf}.pdf
    Close all pdfs

 Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file_name}    include=*.pdf

Input form dialog
    Add heading    Insert file path
    Add text input    excelFile    label=File path
    ${response}=    Run dialog
    RETURN    ${response.excelFile}

Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    urls
    # Note: In real robots, you should not print secrets to the log.
    # This is just for demonstration purposes. :)
    RETURN    ${secret}[orders_url]
