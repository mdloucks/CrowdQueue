# CrowdQueue
Ever go to a restaurant, club, or party and want to play a song without having to ask the DJ? CrowdQueue allows DJs to 
install a mobile app and generate a QR code, allowing patrons to scan the code and queue up a song directly to the 
Spotify app on the DJ's phone. 
This app is made possible by [Spotify's iOS SDK](https://github.com/spotify/ios-sdk). 

## Sequence Diagram

Below is a UML(esque) diagram that outlines the architecture of CrowdQueue as well as it's core workflow, enqueuing a song. 
This repository is the 'Mobile App' portion of the diagram. The other portions are stil closed source for now. 

![Sequence diagram](https://github.com/LawnmowerDave/CrowdQueue/assets/19471665/3d932618-1b4c-4cfb-9e94-5017f95eac2a)

## Screenshots 

![Screenshot 2024-01-22 at 12 58 47 PM](https://github.com/LawnmowerDave/CrowdQueue/assets/19471665/f21fbb17-714e-46f5-bfa4-f47528d02355)

## Acknowledgements

Thank you to the open-source maintainers of [Supabase Swift](https://github.com/supabase-community/supabase-swift) for 
providing a Swift wrapper for Supabase! My knowledge in Swift is rather limited and making manual REST API calls would
have been quite a pain.

[This video by Swift Arcade](https://www.youtube.com/watch?v=kYkdti9mLzo&pp=ygUPc3BvdGlmeSBpb3Mgc2Rr) was also a great
help getting a working prototype started. 
