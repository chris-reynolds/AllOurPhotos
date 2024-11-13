import uno
from com.sun.star.beans import PropertyValue

# Connect to a running LibreOffice instance
localContext = uno.getComponentContext()
resolver = localContext.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", localContext)
context = resolver.resolve("uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext")

# Get the desktop service
desktop = context.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", context)

# Load the Calc file
url = "file:///path/to/your/spreadsheet.ods"
properties = (PropertyValue("Hidden", 0, True, 0),)
document = desktop.loadComponentFromURL(url, "_blank", 0, properties)

# Locate the chart in the sheet (assuming it's on the first sheet)
sheet = document.Sheets[0]
chart = sheet.Charts.getByIndex(0)  # Adjust index if the chart is not the first one

# Export the chart to PDF
output_url = "file:///path/to/output_chart.pdf"
pdf_props = (
    PropertyValue("FilterName", 0, "calc_pdf_Export", 0),
)
chart.exportToPDF(output_url, pdf_props)

# Close the document without saving
document.close(True)
