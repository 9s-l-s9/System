(define-module (services konsole)
  #:use-module (gnu home services)
  #:use-module (gnu packages shells)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (konsole-services))

;; Keep application settings, profile and palette together.  Guix Home owns
;; the resulting files; change this module and reconfigure to change the look.
;; KConfig's immutable marker prevents Konsole from replacing its settings
;; symlink with a mutable copy when it saves window state on exit.
;; Disable semantic visual hints explicitly: fish supplies prompt markers,
;; and Konsole's defaults add bars, divider lines and alternate backgrounds.
;; Shell integration remains available for navigation and copying output.
(define konsole-config
  (plain-file
   "konsolerc"
   "[$i]
MenuBar=Disabled

[Desktop Entry]
DefaultProfile=Gruvbox.profile

[General]
ConfigVersion=1

[KonsoleWindow]
RememberWindowSize=false
ShowWindowTitleOnTitleBar=true

[TabBar]
TabBarPosition=Bottom
TabBarVisibility=ShowTabBarWhenNeeded
ExpandTabWidth=false
NewTabButton=false
TabBarStyleSheet=QTabBar::tab { background: #282828; color: #a89984; padding: 8px 18px; border: none; border-top: 2px solid transparent; } QTabBar::tab:selected { color: #ebdbb2; border-top: 2px solid #d79921; } QTabBar::tab:hover { background: #3c3836; }

[UiSettings]
ColorScheme=BreezeDark
"))

(define konsole-profile
  (mixed-text-file
   "Gruvbox.profile"
   "[General]
Name=Gruvbox
Parent=FALLBACK/
Command=" (file-append fish "/bin/fish") "
Environment=TERM=xterm-256color,COLORTERM=truecolor
TerminalColumns=120
TerminalRows=36
TerminalMargin=12
TerminalCenter=false
DimWhenInactive=false
SemanticHints=0
ErrorBars=0
ErrorBackground=0
AlternatingBars=0
AlternatingBackground=0
StartInCurrentSessionDir=true
LocalTabTitleFormat=%d
RemoteTabTitleFormat=%u@%H: %d

[Appearance]
ColorScheme=Gruvbox
Font=IBM Plex Mono,14,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
AntiAliasFonts=true
LineSpacing=0

[Cursor Options]
CursorShape=0
UseCustomCursorColor=true
CustomCursorColor=235,219,178
CustomCursorTextColor=40,40,40

[Scrolling]
ScrollBarPosition=2
HighlightScrolledLines=false

[Terminal Features]
BlinkingCursorEnabled=false

[Interaction Options]
MiddleClickPasteMode=1
OpenLinksByDirectClickEnabled=true
"))

;; An opaque Gruvbox background keeps contrast independent of the desktop
;; wallpaper and compositor.  Every ANSI intensity is explicit, including
;; faint colors, so this palette does not inherit colors from another theme.
(define konsole-colors
  (plain-file
   "Gruvbox.colorscheme"
   "[General]
Description=Gruvbox
Opacity=1
Blur=false
ColorRandomization=false
Wallpaper=

[Background]
Color=40,40,40
[BackgroundIntense]
Color=40,40,40
[BackgroundFaint]
Color=40,40,40

[Foreground]
Color=235,219,178
[ForegroundIntense]
Color=251,241,199
[ForegroundFaint]
Color=189,174,147

[Color0]
Color=40,40,40
[Color0Intense]
Color=146,131,116
[Color0Faint]
Color=40,40,40

[Color1]
Color=204,36,29
[Color1Intense]
Color=251,73,52
[Color1Faint]
Color=204,36,29

[Color2]
Color=152,151,26
[Color2Intense]
Color=184,187,38
[Color2Faint]
Color=152,151,26

[Color3]
Color=215,153,33
[Color3Intense]
Color=250,189,47
[Color3Faint]
Color=215,153,33

[Color4]
Color=69,133,136
[Color4Intense]
Color=131,165,152
[Color4Faint]
Color=69,133,136

[Color5]
Color=177,98,134
[Color5Intense]
Color=211,134,155
[Color5Faint]
Color=177,98,134

[Color6]
Color=104,157,106
[Color6Intense]
Color=142,192,124
[Color6Faint]
Color=104,157,106

[Color7]
Color=168,153,132
[Color7Intense]
Color=235,219,178
[Color7Faint]
Color=168,153,132
"))

(define (konsole-services)
  (list
   (simple-service 'konsole-settings
                   home-xdg-configuration-files-service-type
                   `(("konsolerc" ,konsole-config)))
   (simple-service 'konsole-profile
                   home-xdg-data-files-service-type
                   `(("konsole/Gruvbox.profile" ,konsole-profile)
                     ("konsole/Gruvbox.colorscheme" ,konsole-colors)))))
