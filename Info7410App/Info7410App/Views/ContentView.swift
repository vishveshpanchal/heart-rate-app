/// Copyright © 2021 Polar Electro Oy. All rights reserved.

import PolarBleSdk
import SwiftUI
import Charts

extension Text {
    func headerStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.secondary)
            .fontWeight(.light)
    }
}


struct ContentView: View {
    @EnvironmentObject private var bleSdkManager: PolarBleSdkManager
    @State private var isSearchingDevices = false
    @State private var selectedRange: ClosedRange<Date> = Date()...Date().addingTimeInterval(60)
    @State private var selectedDataPoint: HeartRateData?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var notificationsEnabled = false

    var body: some View {
        ScrollView {
            VStack {
                Text("Advance Medical Device Software Engineering")
                    .bold()
                
                HStack {
                    if bleSdkManager.deviceInfoFeature.isSupported {
                        Text("Firmware: \(bleSdkManager.deviceInfoFeature.firmwareVersion)")
                    } else {
                        Text("Firmware: -")
                    }
                    
                    Spacer()
                    
                    if bleSdkManager.batteryStatusFeature.isSupported {
                        Text("Battery: \(bleSdkManager.batteryStatusFeature.batteryLevel)%")
                    } else {
                        Text("Battery: -")
                    }
                }
                .padding(2)
                
                VStack(spacing: 10) {
                    if !bleSdkManager.isBluetoothOn {
                        Text("Bluetooth OFF")
                            .bold()
                            .foregroundColor(.red)
                    }
                    
                    Group {
                        Button(action: {
                            bleSdkManager.broadcastToggle()
                            
                            if bleSdkManager.isBroadcastListenOn {
                                bleSdkManager.startAppendingHeartRateDataToFile()
                                } else {
                                    bleSdkManager.stopAppendingHeartRateDataToFile()
                                }
                        }) {
                            Text(
                                bleSdkManager.isBroadcastListenOn
                                ? "Stop Listening to Broadcast"
                                : "Listen to Broadcast")
                            
                        }.buttonStyle(
                            PrimaryButtonStyle(
                                buttonState: getBroadcastButtonState()))
                        .disabled(!bleSdkManager.isConnected)
                        
                        if bleSdkManager.isConnected && bleSdkManager.isBroadcastListenOn {
                            if let hr = bleSdkManager.hr {
                                Text("Heart Rate: \(hr)")
                                    .font(.largeTitle)
                                    .padding()
                            } else {
                                Text("Heart Rate: -")
                                    .font(.largeTitle)
                                    .padding()
                            }
                        }
                        
                        if bleSdkManager.isConnected , bleSdkManager.isBroadcastListenOn , #available(iOS 16.0, *) {
                            Chart(bleSdkManager.heartRateHistory) { data in
                                LineMark(
                                    x: .value("Time", data.time),
                                    y: .value("Heart Rate", data.rate)
                                )
                                .interpolationMethod(.monotone)
                                .foregroundStyle(.red)
                            }
                            .chartYScale(domain: bleSdkManager.dynamicYScale)
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle()) // Makes the entire area tappable
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let location = value.location
                                                    if let date = proxy.value(atX: location.x) as Date? {
                                                        let closest = bleSdkManager.heartRateHistory.min(by: {
                                                            abs($0.time.timeIntervalSince1970 - date.timeIntervalSince1970) <
                                                                abs($1.time.timeIntervalSince1970 - date.timeIntervalSince1970)
                                                        })
                                                        selectedDataPoint = closest
                                                        tooltipPosition = CGPoint(
                                                            x: location.x,
                                                            y: location.y - 30
                                                        )
                                                    }
                                                }
                                                .onEnded { _ in
                                                    selectedDataPoint = nil
                                                }
                                        )
                                }
                            }
                            .overlay {
                                if let dataPoint = selectedDataPoint {
                                    VStack {
                                        Text("Time: \(dataPoint.time.formatted(date: .omitted, time: .standard))")
                                            .foregroundColor(.black)
                                        Text("HR: \(dataPoint.rate) bpm")
                                            .foregroundColor(.black)
                                    }
                                    .padding(5)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(5)
                                    .shadow(radius: 3)
                                    .position(x: tooltipPosition.x,
                                              y: max(tooltipPosition.y - 40, 20)
                                    )
                                }
                            }
                            .frame(height: 200)
                            .padding()
                        } else if !bleSdkManager.isConnected || !bleSdkManager.isBroadcastListenOn {
                            // We dont need any action
                        }
                        else {
                            Text("Graph not supported on iOS versions below 16.")
                                .foregroundColor(.gray)
                        }
                        
                        
                        
                        switch bleSdkManager.deviceConnectionState {
                        case .disconnected(let deviceId):
                            Button(
                                "Connect \(deviceId)",
                                action: { bleSdkManager.connectToDevice() }
                            )
                            .buttonStyle(
                                PrimaryButtonStyle(
                                    buttonState: getConnectButtonState()))
                        case .connecting(let deviceId):
                            Button("Connecting \(deviceId)", action: {})
                                .buttonStyle(
                                    PrimaryButtonStyle(
                                        buttonState: getConnectButtonState())
                                )
                                .disabled(true)
                        case .connected(let deviceId):
                            Button(
                                "Disconnect \(deviceId)",
                                action: { bleSdkManager.disconnectFromDevice() }
                            )
                            .buttonStyle(
                                PrimaryButtonStyle(
                                    buttonState: getConnectButtonState()))
                        }
                        
                        Button(
                            "Auto Connect", action: { bleSdkManager.autoConnect() }
                        )
                        .buttonStyle(
                            PrimaryButtonStyle(
                                buttonState: getAutoConnectButtonState()))
                        
                        VStack {
                            Button(
                                "Search devices",
                                action: { self.isSearchingDevices = true }
                            )
                            .buttonStyle(
                                PrimaryButtonStyle(
                                    buttonState: getSearchButtonState()))
                        }
                        .sheet(
                            isPresented: $isSearchingDevices,
                            onDismiss: { bleSdkManager.stopDevicesSearch() }
                        ) {
                            DeviceSearchView(isPresented: self.$isSearchingDevices)
                        }
                    }.disabled(!bleSdkManager.isBluetoothOn)
                }.frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        if let heartRate = bleSdkManager.hr {
                                    bleSdkManager.handleNewHeartRate(rate: heartRate)
                                }
                    }
                }
        .alert(item: $bleSdkManager.generalMessage) { message in
            Alert(
                title: Text(message.text)
            )
        }
    }
    
    func getConnectButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn {
            switch bleSdkManager.deviceConnectionState {
            case .disconnected(let deviceId):
                if deviceId == "-"
                {
                    return ButtonState.disabled
                }
                else
                {
                    return ButtonState.released
                }
            case .connecting(_):
                return ButtonState.disabled
            case .connected(_):
                return ButtonState.pressedDown
            }
        }
        return ButtonState.disabled
    }
    
//    func getConnectButtonState() -> ButtonState {
//        if bleSdkManager.isBluetoothOn {
//            switch bleSdkManager.deviceConnectionState {
//            case .disconnected:
//                return ButtonState.released
//            case .connecting(_):
//                return ButtonState.disabled
//            case .connected(_):
//                return ButtonState.pressedDown
//            }
//        }
//        return ButtonState.disabled
//    }
    
    func getBroadcastButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn && bleSdkManager.isConnected {
            if bleSdkManager.isBroadcastListenOn {
                return ButtonState.pressedDown
            } else {
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }

    func getAutoConnectButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn,
            case .disconnected = bleSdkManager.deviceConnectionState
        {
            return ButtonState.released
        } else {
            return ButtonState.disabled
        }
    }

    func getSearchButtonState() -> ButtonState {
        if bleSdkManager.isBluetoothOn {
            switch bleSdkManager.deviceSearch.isSearching {
            case .inProgress:
                return ButtonState.pressedDown
            case .success:
                return ButtonState.released
            case .failed(error: _):
                return ButtonState.released
            }
        }
        return ButtonState.disabled
    }
}

struct ContentView_Previews: PreviewProvider {

    private static let offlineRecordingEntries = OfflineRecordingEntries(
        isFetching: false,
        entries: [
            PolarOfflineRecordingEntry(
                path: "/test/url", size: 500, date: Date(), type: .gyro),
            PolarOfflineRecordingEntry(
                path: "/test/url", size: 500, date: Date(), type: .acc),
            PolarOfflineRecordingEntry(
                path: "/test/url", size: 500, date: Date(), type: .magnetometer),
        ]
    )

    private static let offlineRecordingFeature = OfflineRecordingFeature(
        isSupported: true,
        availableOfflineDataTypes: [
            PolarDeviceDataType.hr: true, PolarDeviceDataType.acc: false,
            PolarDeviceDataType.ppi: true, PolarDeviceDataType.gyro: false,
            PolarDeviceDataType.magnetometer: true,
            PolarDeviceDataType.ecg: false,
        ],
        isRecording: [
            PolarDeviceDataType.hr: true, PolarDeviceDataType.acc: false,
            PolarDeviceDataType.ppi: true, PolarDeviceDataType.gyro: false,
            PolarDeviceDataType.magnetometer: true,
            PolarDeviceDataType.ecg: true,
        ]
    )

    private static let polarBleSdkManager: PolarBleSdkManager = {
        let polarBleSdkManager = PolarBleSdkManager()

        polarBleSdkManager.offlineRecordingFeature = offlineRecordingFeature
        polarBleSdkManager.offlineRecordingEntries = offlineRecordingEntries
        return polarBleSdkManager
    }()

    static var previews: some View {
        ForEach(["iPhone 8", "iPAD Pro (12.9-inch)"], id: \.self) {
            deviceName in
            ContentView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
                .environmentObject(polarBleSdkManager)
        }
    }
    
}
