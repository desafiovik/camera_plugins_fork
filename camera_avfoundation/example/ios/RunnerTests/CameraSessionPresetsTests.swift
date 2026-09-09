// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import XCTest

@testable import camera_avfoundation

// Import Objective-C part of the implementation when SwiftPM is used.
#if canImport(camera_avfoundation_objc)
  import camera_avfoundation_objc
#endif

/// Includes test cases related to resolution presets setting operations for FLTCam class.
final class CameraSessionPresetsTests: XCTestCase {
  func testResolutionPresetWithBestFormat_mustUpdateCaptureSessionPreset() {
    let expectedPreset = AVCaptureSession.Preset.inputPriority
    let presetExpectation = expectation(description: "Expected preset set")
    let lockForConfigurationExpectation = expectation(
      description: "Expected lockForConfiguration called")

    let videoSessionMock = MockCaptureSession()
    videoSessionMock.setSessionPresetStub = { preset in
      if preset == expectedPreset {
        presetExpectation.fulfill()
      }
    }
    let captureFormatMock = MockCaptureDeviceFormat()
    let captureDeviceMock = MockCaptureDevice()
    captureDeviceMock.flutterFormats = [captureFormatMock]
    captureDeviceMock.flutterActiveFormat = captureFormatMock
    captureDeviceMock.lockForConfigurationStub = {
      lockForConfigurationExpectation.fulfill()
    }

    let configuration = CameraTestUtils.createTestCameraConfiguration()
    configuration.videoCaptureDeviceFactory = { _ in captureDeviceMock }
    configuration.videoDimensionsConverter = { format in
      return CMVideoDimensions(width: 1, height: 1)
    }
    configuration.videoCaptureSession = videoSessionMock
    configuration.mediaSettings = CameraTestUtils.createDefaultMediaSettings(
      resolutionPreset: FCPPlatformResolutionPreset.max)

    let _ = CameraTestUtils.createTestCamera(configuration)

    waitForExpectations(timeout: 30, handler: nil)
  }

  func testResolutionPresetWithCanSetSessionPresetMax_mustUpdateCaptureSessionPreset() {
    let expectedPreset = AVCaptureSession.Preset.hd4K3840x2160
    let expectation = self.expectation(description: "Expected preset set")

    let videoSessionMock = MockCaptureSession()
    // Make sure that setting resolution preset for session always succeeds.
    videoSessionMock.canSetSessionPresetStub = { _ in true }
    videoSessionMock.setSessionPresetStub = { preset in
      if preset == expectedPreset {
        expectation.fulfill()
      }
    }

    let configuration = CameraTestUtils.createTestCameraConfiguration()
    configuration.videoCaptureSession = videoSessionMock
    configuration.mediaSettings = CameraTestUtils.createDefaultMediaSettings(
      resolutionPreset: FCPPlatformResolutionPreset.max)
    configuration.videoCaptureDeviceFactory = { _ in MockCaptureDevice() }

    let _ = CameraTestUtils.createTestCamera(configuration)

    waitForExpectations(timeout: 30, handler: nil)
  }

  func testResolutionPresetWithCanSetSessionPresetUltraHigh_mustUpdateCaptureSessionPreset() {
    let expectedPreset = AVCaptureSession.Preset.hd4K3840x2160
    let expectation = self.expectation(description: "Expected preset set")

    let videoSessionMock = MockCaptureSession()
    // Make sure that setting resolution preset for session always succeeds.
    videoSessionMock.canSetSessionPresetStub = { _ in true }
    // Expect that setting "ultraHigh" resolutionPreset correctly updates videoCaptureSession.
    videoSessionMock.setSessionPresetStub = { preset in
      if preset == expectedPreset {
        expectation.fulfill()
      }
    }

    let configuration = CameraTestUtils.createTestCameraConfiguration()
    configuration.videoCaptureSession = videoSessionMock
    configuration.mediaSettings = CameraTestUtils.createDefaultMediaSettings(
      resolutionPreset: FCPPlatformResolutionPreset.ultraHigh)

    let _ = CameraTestUtils.createTestCamera(configuration)

    waitForExpectations(timeout: 30, handler: nil)
  }

  // Fork VIK (card 86akfrx6z): `veryHigh` escolhe o formato 4:3 de maior resolução com lado
  // maior até 1920, em vez do preset 16:9 `.hd1920x1080`.
  func testResolutionPresetVeryHigh_mustPickLargestFourByThreeFormatUpTo1920() {
    let presetExpectation = expectation(description: "Expected inputPriority preset set")
    let formatExpectation = expectation(description: "Expected 1920x1440 format set")

    let videoSessionMock = MockCaptureSession()
    videoSessionMock.canSetSessionPresetStub = { _ in true }
    videoSessionMock.setSessionPresetStub = { preset in
      if preset == .inputPriority {
        presetExpectation.fulfill()
      }
      XCTAssertNotEqual(preset, .hd1920x1080, "16:9 não pode mais ser escolhido para veryHigh")
    }

    let wide1080 = MockCaptureDeviceFormat()
    let fourByThree1440 = MockCaptureDeviceFormat()
    let fourByThree3024 = MockCaptureDeviceFormat()
    let fourByThree960 = MockCaptureDeviceFormat()
    let dimensions: [ObjectIdentifier: CMVideoDimensions] = [
      ObjectIdentifier(wide1080): CMVideoDimensions(width: 1920, height: 1080),
      ObjectIdentifier(fourByThree1440): CMVideoDimensions(width: 1920, height: 1440),
      ObjectIdentifier(fourByThree3024): CMVideoDimensions(width: 4032, height: 3024),
      ObjectIdentifier(fourByThree960): CMVideoDimensions(width: 1280, height: 960),
    ]

    let captureDeviceMock = MockCaptureDevice()
    captureDeviceMock.flutterFormats = [wide1080, fourByThree960, fourByThree1440, fourByThree3024]
    captureDeviceMock.activeFormatStub = { wide1080 }
    captureDeviceMock.setActiveFormatStub = { format in
      if format === fourByThree1440 {
        formatExpectation.fulfill()
      } else {
        XCTFail("formato errado escolhido para veryHigh")
      }
    }

    let configuration = CameraTestUtils.createTestCameraConfiguration()
    configuration.videoCaptureDeviceFactory = { _ in captureDeviceMock }
    configuration.videoDimensionsConverter = { format in
      dimensions[ObjectIdentifier(format)] ?? CMVideoDimensions(width: 0, height: 0)
    }
    configuration.videoCaptureSession = videoSessionMock
    configuration.mediaSettings = CameraTestUtils.createDefaultMediaSettings(
      resolutionPreset: FCPPlatformResolutionPreset.veryHigh)

    let _ = CameraTestUtils.createTestCamera(configuration)

    waitForExpectations(timeout: 30, handler: nil)
  }

  // Fork VIK: sem formato 4:3 na faixa, `veryHigh` volta ao preset 16:9 de upstream.
  func testResolutionPresetVeryHigh_fallsBackTo1080pWithoutFourByThreeFormat() {
    let expectation = self.expectation(description: "Expected hd1920x1080 preset set")

    let videoSessionMock = MockCaptureSession()
    videoSessionMock.canSetSessionPresetStub = { _ in true }
    videoSessionMock.setSessionPresetStub = { preset in
      if preset == .hd1920x1080 {
        expectation.fulfill()
      }
    }

    let captureDeviceMock = MockCaptureDevice()
    captureDeviceMock.flutterFormats = [MockCaptureDeviceFormat()]
    captureDeviceMock.setActiveFormatStub = { _ in
      XCTFail("nenhum formato deveria ser fixado sem candidato 4:3")
    }

    let configuration = CameraTestUtils.createTestCameraConfiguration()
    configuration.videoCaptureDeviceFactory = { _ in captureDeviceMock }
    configuration.videoDimensionsConverter = { _ in CMVideoDimensions(width: 1920, height: 1080) }
    configuration.videoCaptureSession = videoSessionMock
    configuration.mediaSettings = CameraTestUtils.createDefaultMediaSettings(
      resolutionPreset: FCPPlatformResolutionPreset.veryHigh)

    let _ = CameraTestUtils.createTestCamera(configuration)

    waitForExpectations(timeout: 30, handler: nil)
  }
}
