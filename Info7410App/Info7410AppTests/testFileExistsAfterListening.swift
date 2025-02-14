//
//  testFileExistsAfterListening.swift
//  Info7410AppTests
//
//  Created by Group 01 on 11/17/24.
//

import Testing

import XCTest

class HeartRateFileTests: XCTestCase {

    func testFileExistsAfterListening() throws {
        let fileManager = FileManager.default

        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not find the app's Documents directory.")
            return
        }

        let fileURL = documentsDirectory.appendingPathComponent("HeartRateData.txt")

        if fileManager.fileExists(atPath: fileURL.path) {
                    print("\nTest Passed: The file HeartRateData.txt exists in the app's Documents directory.\n")
                } else {
                    XCTFail("\n\nTest Failed: The file HeartRateData.txt does not exist after listening. \n")
                }
    }
}
