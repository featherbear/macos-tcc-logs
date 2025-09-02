# macOS TCC Logs

Tracks requests to the Transparency Consent and Control daemon

Supply --json for JSONL output

---

Logs look something like this

> Lines starting with `#>` are external annotations

```
Observing events...
2024-12-27 13:23:36.386177+1100,kTCCServiceListenEvent,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:23:36.416792+1100,kTCCServiceListenEvent,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:23:36.610604+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:23:44.363526+1100,kTCCServiceSystemPolicyAllFiles,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (Service Policy)
2024-12-27 13:23:44.389727+1100,kTCCServiceSystemPolicyDesktopFolder,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (User Consent)
2024-12-27 13:24:08.613788+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:24:08.626275+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:24:08.647788+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:24:09.078263+1100,kTCCServiceSystemPolicyAllFiles,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (Service Policy)
2024-12-27 13:24:09.121477+1100,kTCCServiceSystemPolicyDesktopFolder,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (User Consent)
2024-12-27 13:24:10.117403+1100,kTCCSersviceListenEvent,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:24:10.707820+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (System Set)
#> I ran `screencapture -c` for the first time, and was prompted to grant screen capture permissions to iTerm2
2024-12-27 13:24:28.643717+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Allowed (System Set)
2024-12-27 13:24:29.118255+1100,kTCCServiceListenEvent,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Unknown (None)
2024-12-27 13:24:40.758597+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Allowed (System Set)
2024-12-27 13:24:40.772052+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Allowed (System Set)
2024-12-27 13:24:40.798759+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Allowed (System Set)
2024-12-27 13:24:41.019417+1100,kTCCServiceSystemPolicyAllFiles,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (Service Policy)
2024-12-27 13:24:41.044990+1100,kTCCServiceSystemPolicyDesktopFolder,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Denied (User Consent)
2024-12-27 13:24:49.388759+1100,kTCCServiceScreenCapture,"/Applications/iTerm.app/Contents/MacOS/iTerm2",com.googlecode.iterm2,Allowed (System Set)
```
