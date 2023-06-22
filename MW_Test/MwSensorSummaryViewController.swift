import UIKit
import WebKit

@objc
class MwSensorSummaryViewController: UIViewController {
    
    let mwDevices = AssessmentSettings.sharedManager.mwSensors
    @IBOutlet var csvSummary: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fileUrl = mwDevices.writeAssessmentToFile(
            filePath: "MwSensor_\(AssessmentSettings.sharedManager.dateTimeString)",
            fileName: "MwSensor_Summary_\(AssessmentSettings.sharedManager.dateTimeString).csv"
        )
        
        // Display CSV files in WebView
        let htmlContent = convertCsvToHtmlContent(fileUrl)
        csvSummary.loadHTMLString(htmlContent, baseURL: nil)
        
    }
    
    @IBAction func discardResultsButtonPressed(_ sender: Any) {
        do {
            let folderPath = AssessmentSettings.sharedManager.filesManager.documentsDirectory.path
            + String(format: "/MwSensor_%@/",        AssessmentSettings.sharedManager.dateTimeString)
            try AssessmentSettings.sharedManager.filesManager.removeItem(atPath: folderPath)
            print("Folder and its contents deleted successfully.")
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
    
    @IBAction func saveResultsPressed(_ sender: Any) {
        // Write MwSensor Data into Csv Files
        
        mwDevices.writeDataToFile(
            filePath: "MwSensor_\(AssessmentSettings.sharedManager.dateTimeString)",
            fileName: "MwSensor_Right_\(AssessmentSettings.sharedManager.dateTimeString).csv",
            type: .right
        )
        
        mwDevices.writeDataToFile(
            filePath: "MwSensor_\(AssessmentSettings.sharedManager.dateTimeString)",
            fileName: "MwSensor_Left_\(AssessmentSettings.sharedManager.dateTimeString).csv",
            type: .left
        )
    }
    
    
    func convertCsvToHtmlContent(_ fileUrl: URL) -> String {
        let csvFilePath = fileUrl.path
        let csvContent = try? String(contentsOfFile: csvFilePath, encoding: .utf8)
        
        var htmlContent = "<html><head><style>table { width: 100%; } td { padding: 5px; font-size: 32px; }</style></head><body><table border='1'>"
        
        if let csvContent = csvContent {
            let csvRows = csvContent.components(separatedBy: "\n")
            for row in csvRows {
                let rowItems = row.components(separatedBy: ",")
                htmlContent.append("<tr>")
                for item in rowItems {
                    htmlContent.append("<td>\(item)</td>")
                }
                htmlContent.append("</tr>")
            }
        }
        
        htmlContent.append("</table></body></html>")
        
        return htmlContent
    }
}
