//
//  testFileContentFormat.swift
//  Info7410AppTests
//
//  Created by Group 01 on 11/17/24.
//

import Testing
import XCTest

class TestFileContentFormat: XCTestCase {

    func testFileContentFormat() {
        // Locate the file in the app's Documents directory
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not find the app's Documents directory.")
            return
        }

        let fileURL = documentsDirectory.appendingPathComponent("HeartRateData.txt")

        // Ensure the file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            XCTFail("HeartRateData.txt file does not exist.")
            return
        }

        // Read the file content
        do {
            let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = fileContent.split(separator: "\n").map { String($0) }

            // Ensure there are lines to test
            XCTAssertGreaterThan(lines.count, 0, "The file is empty.")

            var allLinesValid = true // Track validation status

            // Check each line for correct format
            for line in lines {
                if !line.matches(regex: #"^\d{2}/\d{2}/\d{4}, \d{1,2}:\d{2}:\d{2}\s[AP]M\s[A-Z]{3}: \d+\sbpm$"#) {
                    XCTFail("\n\nTest Failed: Line does not match expected format: \(line)\n")
                    allLinesValid = false
                    return
                }
            }

            // Print success message only if all lines are valid
            if allLinesValid {
                print("\nTest Passed: All lines in HeartRateData.txt are correctly formatted.\n")
            }

        } catch {
            XCTFail("Error reading the file: \(error.localizedDescription)")
        }
    }
}

// Helper extension for regex matching
extension String {
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
