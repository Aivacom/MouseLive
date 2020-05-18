#开启预览流程
```flow
createEngine=>start: createEngine
out=>end: 界面出现图像
step1=>operation: setArea
step2=>operation: setMediaMode
step3=>operation: setRoomMode
step4=>operation: startVideoPreview
step5=>operation: setLocalVideoCanvas

createEngine->step1->step2->step3->step4->step5->out
```

#主播音视频推流流程
```flow
createEngine=>start: createEngine
out=>end: 主播开播成功
step1=>operation: setArea
step2=>operation: setMediaMode
step3=>operation: setRoomMode
step4=>operation: setAudioConfig
step5=>operation: setAudioSourceType
step6=>operation: setVideoEncoderConfig
step7=>operation: startVideoPreview
step8=>operation: setLocalVideoCanvas
step9=>operation: joinRoom
step10=>operation: stopLocalAudioStream
step11=>operation: stopLocalVideoStream

createEngine->step1->step2->step3->step4->step5->step6->step7->step8->step9->step10->step11->out
```