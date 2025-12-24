// Header shim for stasel/WebRTC packaging issue.
//
// Some WebRTC framework headers include:
//   #import "sdk/objc/base/RTCMacros.h"
// but the binary framework ships RTCMacros.h at:
//   WebRTC.framework/Headers/RTCMacros.h
//
// Under Xcode's explicit module builds / clang dependency scanning, a target build
// phase that copies headers into DerivedData may not run early enough.
//
// This shim is found via HEADER_SEARCH_PATHS and forwards to the framework header.

#pragma once

#import <WebRTC/RTCMacros.h>
