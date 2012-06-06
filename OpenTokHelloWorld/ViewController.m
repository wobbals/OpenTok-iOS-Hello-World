//
//  ViewController.m
//  SampleApp
//
//  Created by Charley Robinson on 12/13/11.
//  Copyright (c) 2011 Tokbox, Inc. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController {
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
}
static double widgetHeight = 340;
static double widgetWidth = 480;
static NSString* const kApiKey = @"1127";
static NSString* const kToken = @"devtoken";
static NSString* const kSessionId = @"1sdemo00855f8290f8efa648d9347d718f7e06fd";
                                // To test the session in a web page,
                                // go to http://staging.tokbox.com/opentok/api/tools/js/tutorials/helloworld.html
                                // For a unique API key, go to http://staging.tokbox.com/hl/session/create
static bool subscribeToSelf = YES; // Change to NO if you want to subscribe to streams other than your own.

CGPoint invertedPoint(CGPoint point) {
    CGPoint myPoint;
    myPoint.x = -1 * point.x;
    myPoint.y = -1 * point.y;
    return myPoint;
}

- (void) doFacialDetectionOnView:(UIView*)view {
    CGSize imageSize = view.bounds.size;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef theContext = NULL;
    for (int i = 0; i < 10 && theContext == NULL; i++) {
        theContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, 4*imageSize.width, colorSpace, kCGImageAlphaPremultipliedLast);
    }
    if (!theContext) {
        return;
    }
    
    UIView* featureViewApplied = nil;
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    double lastRefreshTime = 0;
    
    while (!view.isHidden) {
        
        [view.layer renderInContext:theContext];
        
        // Layer tree has backgroundFilters set on some of the CALayers
        // When it's rendered in the Bitmap Context, none of these filters are applied.
        
        CGImageRef myCGImage = CGBitmapContextCreateImage(theContext);
        
        CIImage* myCIImage = [CIImage imageWithCGImage:myCGImage];
        myCIImage = [myCIImage imageByApplyingTransform:CGAffineTransformMakeRotation(M_PI)];
        
        // create an array containing all the detected faces from the detector
        NSArray* features = [detector featuresInImage:myCIImage];
        
        UIView* featureView = [[UIView alloc] initWithFrame:CGRectMake(0,0,CGImageGetWidth(myCGImage), CGImageGetHeight(myCGImage))];
        CGImageRelease(myCGImage);
        
        CGPoint faceCenter;
        
        // we'll iterate through every detected face. CIFaceFeature provides us
        // with the width for the entire face, and the coordinates of each eye
        // and the mouth if detected. Also provided are BOOL's for the eye's and
        // mouth so we can check if they already exist.
        for(CIFaceFeature* faceFeature in features) {
            // get the width of the face
            CGFloat faceWidth = faceFeature.bounds.size.width;
            faceCenter = faceFeature.bounds.origin;
            // create a UIView using the bounds of the face
            CGRect faceRect = CGRectMake(-1 * faceFeature.bounds.origin.x - faceFeature.bounds.size.width, -1 * faceFeature.bounds.origin.y - faceFeature.bounds.size.height, faceFeature.bounds.size.width, faceFeature.bounds.size.height);
            UIView* faceView = [[UIView alloc] initWithFrame:faceRect];
            
            // add a border around the newly created UIView
            faceView.layer.borderWidth = 1;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            
            [featureView addSubview:faceView];
            
            if(faceFeature.hasLeftEyePosition)
            {
                // create a UIView with a size based on the width of the face
                UIView* leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, faceWidth*0.3, faceWidth*0.3)];
                // change the background color of the eye view
                [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]];
                // set the position of the leftEyeView based on the face
                [leftEyeView setCenter:invertedPoint(faceFeature.leftEyePosition)];
                // round the corners
                leftEyeView.layer.cornerRadius = faceWidth*0.15;
                // add the view to the window
                [featureView addSubview:leftEyeView];
                //NSLog(@"leftEye: x=%f y=%f", faceFeature.leftEyePosition.x, faceFeature.leftEyePosition.y);
            }
            
            if(faceFeature.hasRightEyePosition)
            {
                // create a UIView with a size based on the width of the face
                UIView* rightEye = [[UIView alloc] initWithFrame:CGRectMake(0, 0, faceWidth*0.3, faceWidth*0.3)];
                // change the background color of the  eye view
                [rightEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.2]];
                // set the position of the rightEyeView based on the face
                [rightEye setCenter:invertedPoint(faceFeature.rightEyePosition)];
                // round the corners
                rightEye.layer.cornerRadius = faceWidth*0.15;
                // add the new view to the window
                [featureView addSubview:rightEye];
                //NSLog(@"rightEye: x=%f y=%f", faceFeature.rightEyePosition.x, faceFeature.rightEyePosition.y);
            }
            
            if(faceFeature.hasMouthPosition)
            {
                // create a UIView with a size based on the width of the face
                UIView* mouth = [[UIView alloc] initWithFrame:CGRectMake(0, 0, faceWidth*0.4, faceWidth*0.4)];
                // change the background color for the mouth to green
                [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
                // set the position of the mouthView based on the face
                [mouth setCenter:invertedPoint(faceFeature.mouthPosition)];
                //NSLog(@"mouth: x=%f y=%f", faceFeature.mouthPosition.x, faceFeature.mouthPosition.y);
                
                // round the corners
                mouth.layer.cornerRadius = faceWidth*0.2;
                
                // add the new view to the window
                [featureView addSubview:mouth];
            }
            
        }
        
        if (features.count > 0) {
            //NSLog(@"origin: x=%f y=%f", faceCenter.x, faceCenter.y);
            
            //[featureView.layer renderInContext:theContext];
            
            //CGImageRef imageWithFeatures = CGBitmapContextCreateImage(theContext);
            //UIImage* renderedFeatureImage = [[UIImage alloc] initWithCGImage:imageWithFeatures];
            //UIImageView* imageView = [[UIImageView alloc] initWithImage:renderedFeatureImage];
            //imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);
            
            if (featureViewApplied) {
                [featureViewApplied removeFromSuperview];
            }
            featureViewApplied = featureView;
            lastRefreshTime = CACurrentMediaTime();
            dispatch_async(dispatch_get_main_queue(), ^{
                [view addSubview:featureViewApplied];      
            });
            
            //CGImageRelease(imageWithFeatures);
        } else if (!featureViewApplied.isHidden && CACurrentMediaTime() - lastRefreshTime > 1.0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.1 animations:^{
                    [featureViewApplied setAlpha:0.1];
                } completion:^(BOOL finished) {
                    [featureViewApplied setHidden:YES];
                }];
            });
        }
        
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    _session = [[OTSession alloc] initWithSessionId:kSessionId
                                           delegate:self];
    [self doConnect];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return NO;
    } else {
        return YES;
    }
}

- (void)updateSubscriber {
    for (NSString* streamId in _session.streams) {
        OTStream* stream = [_session.streams valueForKey:streamId];
        if (![stream.connection.connectionId isEqualToString: _session.connection.connectionId]) {
            _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            break;
        }
    }
}

#pragma mark - OpenTok methods

- (void)doConnect 
{
    [_session connectWithApiKey:kApiKey token:kToken];
}

- (void)doPublish
{
    _publisher = [[OTPublisher alloc] initWithDelegate:self];
    [_publisher setName:[[UIDevice currentDevice] name]];
    [_session publish:_publisher];
    [self.view addSubview:_publisher.view];
    [_publisher.view setFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self doFacialDetectionOnView:_publisher.view.videoView];
    });

}

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage = [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
    [self showAlert:alertMessage];
}


- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
    NSLog(@"session didReceiveStream (%@)", stream.streamId);
    
    // See the declaration of subscribeToSelf above.
    if ( (subscribeToSelf && [stream.connection.connectionId isEqualToString: _session.connection.connectionId])
           ||
         (!subscribeToSelf && ![stream.connection.connectionId isEqualToString: _session.connection.connectionId])
       ) {
        if (!_subscriber) {
            _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
            
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self doFacialDetectionOnView:_subscriber.view.videoView];
            });

        }
    }
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream{
    NSLog(@"session didDropStream (%@)", stream.streamId);
    NSLog(@"_subscriber.stream.streamId (%@)", _subscriber.stream.streamId);
    if (!subscribeToSelf
        && _subscriber
        && [_subscriber.stream.streamId isEqualToString: stream.streamId])
    {
        _subscriber = nil;
        [self updateSubscriber];
    }
}

- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
    [subscriber.view setFrame:CGRectMake(0, widgetHeight, widgetWidth, widgetHeight)];
    [self.view addSubview:subscriber.view];
}

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error {
    NSLog(@"publisher didFailWithError %@", error);
    [self showAlert:[NSString stringWithFormat:@"There was an error publishing."]];
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
    [self showAlert:[NSString stringWithFormat:@"There was an error subscribing to stream %@", subscriber.stream.streamId]];
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    NSLog(@"sessionDidFail");
    [self showAlert:[NSString stringWithFormat:@"There was an error connecting to session %@", session.sessionId]];
}


- (void)showAlert:(NSString*)string {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                    message:string
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end

