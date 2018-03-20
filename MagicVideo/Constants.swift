//
//  Constants.swift
//  MagicVideo
//
//  Created by jaba odishelashvili on 3/14/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

struct Constants {
    struct AlertTitles {
        static let CameraAccess = "Camera Access"
        static let MicrophoneAccess = "Microphone Access"
    }
    
    struct AlertMessages {
        static let CameraAccess = "This app does not have access to your Camera. To enable press OK and switch Camera on."
        static let MicrophoneAccess = "This app does not have access to your Microphone. To enable press OK and switch Microphone on."
    }
    
    struct AlertActionTitles {
        static let Ok = "OK"
        static let Cancel = "Cancel"
    }
    
    struct CIEffectKeys {
        static let InputAmountKey = "inputAmount"
        static let InputHighlightAmount = "inputHighlightAmount"
        static let InputShadowAmount = "inputShadowAmount"
    }
    
    struct QueueLabels {
        static let VideoSessionQueue = "video_capture_session_queue"
        static let AudioSessionQueue = "audio_capture_session_queue"
    }
}
