//
//  HeartRatePerSecond.swift
//  Info7410AppTests
//
//  Created by Group 01 on 11/16/24.
//

import Testing

import XCTest

class HeartRatePerSecondTests: XCTestCase {
    
    override func setUpWithError() throws {
            try super.setUpWithError()

            try updateTestFile()
        }
    
    private func updateTestFile() throws -> URL {
        let fileManager = FileManager.default

        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not find the app's Documents directory.")
            throw NSError(domain: "Test", code: 1, userInfo: nil)
        }

        let sourceFileURL = documentsDirectory.appendingPathComponent("HeartRateData.txt")

        guard fileManager.fileExists(atPath: sourceFileURL.path) else {
            XCTFail("The source file HeartRateData.txt does not exist in the app's Documents directory.")
            throw NSError(domain: "Test", code: 2, userInfo: nil)
        }

        let tempDirectory = fileManager.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("HeartRateData.txt")

        do {
            if fileManager.fileExists(atPath: tempFileURL.path) {
                try fileManager.removeItem(at: tempFileURL)
            }
            try fileManager.copyItem(at: sourceFileURL, to: tempFileURL)
            print("Test file copied successfully to \(tempFileURL.path)")
        } catch {
            XCTFail("Failed to copy the test file: \(error.localizedDescription)")
            throw error
        }

        return tempFileURL
    }

    func testHeartRateIntervals() {
        do {
            let testFileURL = try updateTestFile()

            let fileContent: String
            do {
                fileContent = try String(contentsOf: testFileURL, encoding: .utf8)
            } catch {
                XCTFail("Error reading the file: \(error.localizedDescription)")
                return
            }

            let lines = fileContent.split(separator: "\n").map { String($0) }
            guard lines.count > 1 else {
                XCTFail("File must contain at least two data points.")
                return
            }

            guard let firstLine = lines.first,
                  let lastLine = lines.last else {
                XCTFail("Could not extract first or last lines.")
                return
            }

            let firstTimestamp = parseTimestamp(from: firstLine)
            let lastTimestamp = parseTimestamp(from: lastLine)

            guard let startTime = firstTimestamp, let endTime = lastTimestamp else {
                XCTFail("Could not parse timestamps.")
                return
            }

            let timeDifference = endTime.timeIntervalSince(startTime)

            let averageInterval = timeDifference / Double(lines.count - 1)

            print("Start Time: \(startTime)")
            print("End Time: \(endTime)")
            print()
            print("Time Difference: \(timeDifference) seconds")
            print("Response Count: \(Double(lines.count - 1))")
            print("Average Interval: \(averageInterval) seconds")
            print()

            let expectedIntervalRange: ClosedRange<Double> = 0.98...1.02
            XCTAssert(expectedIntervalRange.contains(averageInterval),
                      "Average interval \(averageInterval) is not within the expected range \(expectedIntervalRange).")
            
            print("Test Passed: Heart Rate Per Second is within expected range\n")

        } catch {
            XCTFail("Test setup failed: \(error.localizedDescription)")
        }
    }

    private func parseTimestamp(from line: String) -> Date? {

        let components = line.split(separator: ":").map { String($0) }
        guard components.count >= 2 else { return nil }

        let timestampString = line.components(separatedBy: ": ")[0]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy, h:mm:ss a zzz"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        return dateFormatter.date(from: timestampString)
    }
}
